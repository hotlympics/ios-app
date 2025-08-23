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
    @State private var profileSetupCompletedOnTab: Int? = nil
    
    // Callback for successful authentication
    private func onAuthenticationSuccess() {
        // Only show upload sheet if we're on the Upload tab (tag 2)
        if selectedTab == 2 {
            // Show upload sheet after a short delay to ensure auth state is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if authService.isAuthenticated && !needsProfileCompletion {
                    showingUploadSheet = true
                }
            }
        }
        // Don't change tabs - stay on current tab
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
                        .onAppear {
                            profileSetupCompletedOnTab = 2
                        }
                } else {
                    Text("") // Empty view - will trigger sheet
                        .navigationBarHidden(true)
                        .onAppear {
                            // Only show upload sheet if:
                            // 1. We're actually on the Upload tab (selectedTab == 2)
                            // 2. Profile wasn't just completed on this tab
                            if selectedTab == 2 && profileSetupCompletedOnTab != 2 {
                                showingUploadSheet = true
                            }
                            // Reset the flag if it was set for this tab
                            if profileSetupCompletedOnTab == 2 {
                                profileSetupCompletedOnTab = nil
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
                        .onAppear {
                            profileSetupCompletedOnTab = 3
                        }
                } else {
                    MyPhotosView(onAuthenticationSuccess: {
                        // Do nothing when signing in from My Photos tab
                        // User stays on the same tab, no upload prompt
                    })
                        .navigationBarHidden(true)
                        .onAppear {
                            // Reset flag if profile was completed on this tab
                            if profileSetupCompletedOnTab == 3 {
                                profileSetupCompletedOnTab = nil
                            }
                        }
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
                        .onAppear {
                            profileSetupCompletedOnTab = 4
                        }
                } else {
                    ProfileView()
                        .navigationBarHidden(true)
                        .onAppear {
                            // Reset flag if profile was completed on this tab
                            if profileSetupCompletedOnTab == 4 {
                                profileSetupCompletedOnTab = nil
                            }
                        }
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
        .onChange(of: selectedTab) { newTab in
            // When user actively selects the Upload tab and is authenticated with complete profile
            if newTab == 2 && 
               authService.isAuthenticated && 
               !needsProfileCompletion && 
               profileSetupCompletedOnTab != 2 {
                showingUploadSheet = true
            }
        }
        .onChange(of: showingUploadSheet) { isShowing in
            if !isShowing && selectedTab == 2 {
                // Navigate to My Photos tab after upload
                selectedTab = 3
            }
        }
    }
}

#Preview {
    ContentView()
}
