//
//  ContentView.swift
//  ios-app
//
//  Created by Jørgen Henriksen on 18/08/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingUploadSheet = false
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var justAuthenticated = false
    
    // Callback for successful authentication
    private func onAuthenticationSuccess() {
        // Set flag to prevent upload sheet from showing
        justAuthenticated = true
        // Navigate to Profile tab (tag 4)
        selectedTab = 4
    }
    
    // Check if user needs to complete profile
    private var needsProfileCompletion: Bool {
        guard let user = authService.currentUser else { return false }
        return !user.isProfileComplete
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RatingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                }
                .tag(0)
            
            LeaderboardView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                }
                .tag(1)
            
            // Upload tab - shows SignInPromptView if not authenticated or ProfileSetupView if profile incomplete
            NavigationView {
                if !authService.isAuthenticated {
                    SignInPromptView(message: "Sign in to upload photos", onAuthenticationSuccess: onAuthenticationSuccess)
                        .navigationBarHidden(true)
                } else if needsProfileCompletion {
                    ProfileSetupView(authService: authService)
                        .navigationBarHidden(true)
                } else {
                    Text("") // Empty view - will trigger sheet
                        .navigationBarHidden(true)
                        .onAppear {
                            // Only show upload sheet if we didn't just authenticate
                            if !justAuthenticated {
                                showingUploadSheet = true
                            }
                        }
                        .onChange(of: selectedTab) { newValue in
                            if newValue == 2 && authService.isAuthenticated && !needsProfileCompletion && !justAuthenticated {
                                showingUploadSheet = true
                            }
                        }
                }
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
            }
            .tag(2)
            
            // My Photos tab - shows profile setup if incomplete
            NavigationView {
                if authService.isAuthenticated && needsProfileCompletion {
                    ProfileSetupView(authService: authService)
                        .navigationBarHidden(true)
                } else {
                    MyPhotosView(onAuthenticationSuccess: onAuthenticationSuccess)
                        .navigationBarHidden(true)
                }
            }
            .tabItem {
                Image(systemName: "photo.stack")
                    .font(.system(size: 24))
            }
            .tag(3)
            
            // Profile tab - shows profile setup if incomplete
            NavigationView {
                if authService.isAuthenticated && needsProfileCompletion {
                    ProfileSetupView(authService: authService)
                        .navigationBarHidden(true)
                } else {
                    ProfileView()
                        .navigationBarHidden(true)
                }
            }
            .tabItem {
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
            }
            .tag(4)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingUploadSheet) {
            UploadView()
        }
        .onChange(of: showingUploadSheet) { isShowing in
            if !isShowing && selectedTab == 2 {
                // Navigate to My Photos tab after upload
                selectedTab = 3
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Reset the justAuthenticated flag after navigating to Profile tab
            if newTab == 4 && justAuthenticated {
                // Use a small delay to ensure the navigation completes first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    justAuthenticated = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
