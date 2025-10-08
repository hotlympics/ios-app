//
//  MyPhotosView.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import SwiftUI

struct MyPhotosView: View {
    @StateObject private var viewModel = MyPhotosViewModel()
    @StateObject private var authService = FirebaseAuthService.shared
    let onAuthenticationSuccess: (() -> Void)?
    
    init(onAuthenticationSuccess: (() -> Void)? = nil) {
        self.onAuthenticationSuccess = onAuthenticationSuccess
    }
    
    var body: some View {
        if viewModel.isAuthenticated {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("My Photos")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(viewModel.userPhotos.count)/10 photos uploaded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // Pool selection bar
                    if !viewModel.userPhotos.isEmpty {
                        PoolSelectionBarView(
                            selectedCount: viewModel.selectedPhotos.count,
                            hasChanges: viewModel.hasChanges,
                            isUpdating: viewModel.isUpdatingPool,
                            onSave: viewModel.savePoolSelection
                        )
                    }
                    
                    // Photo grid or empty state
                    ScrollView {
                        if viewModel.userPhotos.isEmpty && !viewModel.isRefreshing {
                            EmptyPhotosView()
                        } else {
                            PhotoGridView(
                                photos: viewModel.userPhotos,
                                selectedPhotos: viewModel.selectedPhotos,
                                onPhotoTap: viewModel.togglePhotoSelection,
                                onPhotoDelete: viewModel.confirmDeletePhoto,
                                deletingPhotoId: viewModel.isDeletingPhoto ? viewModel.photoToDelete?.id : nil
                            )
                        }
                    }
                    .refreshable {
                        await viewModel.refreshPhotos()
                    }
                }
                .background(Color(UIColor.systemBackground))
                .navigationBarHidden(true)
                .onChange(of: viewModel.showSuccessMessage) { _ in
                    viewModel.dismissMessages()
                }
                .onChange(of: viewModel.errorMessage) { _ in
                    viewModel.dismissMessages()
                }
                .overlay(
                    // Success/Error messages overlay at bottom
                    VStack {
                        Spacer()
                        
                        if viewModel.showSuccessMessage {
                            SuccessMessageView(
                                message: viewModel.successMessageText,
                                isSuccess: true
                            )
                        }
                        
                        if let error = viewModel.errorMessage {
                            SuccessMessageView(
                                message: error,
                                isSuccess: false
                            )
                        }
                    }
                )
                .alert(isPresented: $viewModel.showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Photo"),
                        message: Text(viewModel.photoToDelete?.isInPool == true
                            ? "This photo is currently in the rating pool. Deleting it will remove it from the pool and delete all associated data. Are you sure?"
                            : "This will permanently delete the photo and all associated data. Are you sure?"),
                        primaryButton: .destructive(Text("Delete")) {
                            viewModel.deletePhoto()
                        },
                        secondaryButton: .cancel(viewModel.cancelDelete)
                    )
                }
                .onAppear {
                    Task {
                        await viewModel.loadPhotos()
                    }
            }
        } else {
            DemoMyPhotosView(onAuthenticationSuccess: onAuthenticationSuccess)
        }
    }
}

#Preview {
    MyPhotosView()
}