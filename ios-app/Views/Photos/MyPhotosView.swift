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
    
    var body: some View {
        NavigationView {
            if authService.isAuthenticated {
                // Authenticated view - show photos (placeholder for now)
                VStack {
                    Text("My Photos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Spacer()
                    
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.bottom, 10)
                    
                    Text("Coming Soon")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Your photos will appear here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGray6))
                .navigationBarHidden(true)
                .task {
                    await userService.fetchUserData()
                }
            } else {
                // Not authenticated - show sign in prompt
                SignInPromptView(message: "Sign in to view your photos")
                    .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    MyPhotosView()
}