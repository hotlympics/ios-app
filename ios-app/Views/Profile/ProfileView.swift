//
//  ProfileView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var showingSignIn = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("My Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                
                if authService.isAuthenticated, let user = authService.user {
                    // Authenticated User View
                    VStack(spacing: 20) {
                        // Profile Image
                        if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // User Info
                        VStack(spacing: 8) {
                            if let displayName = user.displayName {
                                Text(displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(user.email)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Upload Photo Button
                        Button(action: {
                            // TODO: Implement photo upload
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Upload Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Sign Out Button
                        Button(action: {
                            authService.signOut()
                        }) {
                            Text("Sign Out")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Not Authenticated View
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Sign in to upload photos")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingSignIn = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Sign In")
                            }
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGray6))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
        }
    }
}

#Preview {
    ProfileView()
}