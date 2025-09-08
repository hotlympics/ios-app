//
//  ProfileSetupView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var authService: FirebaseAuthService
    @State private var isLoading = false
    @State private var currentUser: User?
    
    var body: some View {
        Group {
            if let user = currentUser {
                if user.needsGenderAndDOB {
                    GenderDOBSetupView(
                        onSubmit: updateProfile,
                        onLogout: logout
                    )
                } else if user.needsToSAcceptance {
                    TermsOfServiceView(
                        onAccept: acceptTermsOfService,
                        onDecline: logout
                    )
                } else {
                    // This shouldn't happen as ProfileSetupView should only be shown for incomplete profiles
                    ProgressView("Loading...")
                        .onAppear {
                            // Refresh user data in case of state mismatch
                            Task {
                                await refreshUserData()
                            }
                        }
                }
            } else {
                // Loading state while fetching user data
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading profile...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .onAppear {
                    Task {
                        await loadUserData()
                    }
                }
            }
        }
    }
    
    private func loadUserData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Fetch fresh user data from the server
        let userData = await authService.fetchUserProfile()
        
        await MainActor.run {
            currentUser = userData
            isLoading = false
        }
    }
    
    private func refreshUserData() async {
        // Force refresh user data
        let userData = await authService.fetchUserProfile()
        
        await MainActor.run {
            currentUser = userData
            
            // If profile is complete after refresh, this view should be dismissed
            // The parent view should handle this by checking isProfileComplete
            if userData?.isProfileComplete == true {
                // Notify that profile setup is complete
                authService.checkAuthState()
            }
        }
    }
    
    private func updateProfile(gender: String, dateOfBirth: String) async -> Bool {
        let success = await authService.updateUserProfile(
            gender: gender,
            dateOfBirth: dateOfBirth
        )
        
        if success {
            // Refresh user data after successful update
            await refreshUserData()
        }
        
        return success
    }
    
    private func acceptTermsOfService() async -> Bool {
        let success = await authService.acceptTermsOfService()
        
        if success {
            // Refresh user data after successful ToS acceptance
            await refreshUserData()
        }
        
        return success
    }
    
    private func logout() {
        Task {
            await authService.signOut()
        }
    }
}

#Preview {
    ProfileSetupView(authService: FirebaseAuthService.shared)
}