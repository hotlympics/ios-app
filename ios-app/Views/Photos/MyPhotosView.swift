//
//  MyPhotosView.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import SwiftUI

struct MyPhotosView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @StateObject private var userService = UserService.shared
    @State private var selectedPhotos = Set<String>()
    @State private var isUpdatingPool = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var hasChanges: Bool {
        let currentPoolIds = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
        return selectedPhotos != currentPoolIds
    }
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Photos")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(userService.userPhotos.count)/10 photos uploaded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Pool selection bar
                    if !userService.userPhotos.isEmpty {
                        HStack {
                            Text("Select up to 2 photos for the rating pool (\(selectedPhotos.count)/2 selected)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: savePoolSelection) {
                                if isUpdatingPool {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Save Pool Selection")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(hasChanges && !isUpdatingPool ? Color.green : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .disabled(!hasChanges || isUpdatingPool)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                    }
                    
                    // Photo grid or empty state
                    ScrollView {
                        if userService.userPhotos.isEmpty && !isRefreshing {
                            // Empty state
                            VStack(spacing: 20) {
                                Spacer(minLength: 100)
                                
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No photos uploaded yet")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("Upload photos to see them here")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer(minLength: 100)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            // Photo grid
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(userService.userPhotos) { photo in
                                    PhotoGridItem(
                                        photo: photo,
                                        isSelected: selectedPhotos.contains(photo.id),
                                        onTap: { togglePhotoSelection(photo.id) }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    .refreshable {
                        await refreshPhotos()
                    }
                    
                    // Success/Error messages
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Pool selections updated successfully!")
                                .font(.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showSuccessMessage = false
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    errorMessage = nil
                                }
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .navigationBarHidden(true)
                .onAppear {
                    Task {
                        // Fetch user data (will use cache if available)
                        await userService.fetchUserData()
                        // Initialize selected photos from current pool
                        selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
                    }
                }
            } else {
                // Not authenticated - show sign in prompt
                SignInPromptView(message: "Sign in to view your photos")
                    .navigationBarHidden(true)
            }
        }
    }
    
    private func togglePhotoSelection(_ photoId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedPhotos.contains(photoId) {
                selectedPhotos.remove(photoId)
            } else {
                if selectedPhotos.count < 2 {
                    selectedPhotos.insert(photoId)
                } else {
                    // Show error - max 2 photos
                    errorMessage = "You can only select up to 2 photos for the pool"
                }
            }
        }
    }
    
    private func refreshPhotos() async {
        isRefreshing = true
        await userService.fetchUserData(forceRefresh: true)
        selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
        isRefreshing = false
    }
    
    private func savePoolSelection() {
        isUpdatingPool = true
        errorMessage = nil
        
        Task {
            let success = await userService.updatePoolSelection(imageIds: Array(selectedPhotos))
            
            await MainActor.run {
                isUpdatingPool = false
                if success {
                    showSuccessMessage = true
                    // Refresh the selected photos from the updated data
                    selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
                } else {
                    errorMessage = "Failed to update pool selection"
                }
            }
        }
    }
}

struct PhotoGridItem: View {
    let photo: UserService.UserPhoto
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Photo
                CachedAsyncImage(urlString: photo.url) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .foregroundColor(Color(UIColor.systemGray5))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
                )
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                        .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MyPhotosView()
}