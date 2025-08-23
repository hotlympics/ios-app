//
//  ProfileView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @StateObject private var userService = UserService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if authService.isAuthenticated, let user = authService.currentUser {
                    // Authenticated User View
                    
                    VStack(spacing: 30) {
                        // Email
                        Text(user.email ?? "No email")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // Stats Section
                        VStack(spacing: 20) {
                            HStack {
                                Text("Photos Uploaded:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(userService.uploadedPhotosCount)/10")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 40)
                            
                            HStack {
                                Text("Photos in Pool:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(userService.poolPhotosCount)/2")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 40)
                        }
                        
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
                    .task {
                        await userService.fetchUserData()
                    }
                } else {
                    // Not Authenticated View
                    SignInPromptView(message: "Sign in to access your profile")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGray6))
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ProfileView()
}
