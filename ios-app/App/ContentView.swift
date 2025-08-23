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
            
            // Upload tab - shows SignInPromptView if not authenticated
            NavigationView {
                if authService.isAuthenticated {
                    Text("") // Empty view - will trigger sheet
                        .navigationBarHidden(true)
                        .onAppear {
                            showingUploadSheet = true
                        }
                        .onChange(of: selectedTab) { newValue in
                            if newValue == 2 && authService.isAuthenticated {
                                showingUploadSheet = true
                            }
                        }
                } else {
                    SignInPromptView(message: "Sign in to upload photos")
                        .navigationBarHidden(true)
                }
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
            }
            .tag(2)
            
            MyPhotosView()
                .tabItem {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 24))
                }
                .tag(3)
            
            ProfileView()
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
    }
}

#Preview {
    ContentView()
}
