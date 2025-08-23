//
//  TermsOfServiceView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var hasScrolledToBottom = false
    
    let onAccept: () async -> Bool
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please review and accept our terms to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            // Terms content in scrollable view
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Terms of Service")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Effective Date: January 9, 2025")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("1. Acceptance of Terms")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("By using Hotlympics, you agree to these Terms of Service. If you do not agree, please do not use our service.")
                                .font(.body)
                            
                            Text("2. Eligibility")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("You must be at least 18 years old to use Hotlympics. By using our service, you represent and warrant that you meet this age requirement.")
                                .font(.body)
                            
                            Text("3. User Content")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("• You retain ownership of photos you upload\n• You grant us a license to use your photos for the rating service\n• You must have the right to upload any photos you submit\n• Photos must be of yourself only\n• No inappropriate or offensive content is allowed")
                                .font(.body)
                        }
                        
                        Group {
                            Text("4. Photo Requirements")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("• Photos must clearly show your face\n• No group photos\n• No heavily filtered or edited photos\n• Photos must be appropriate for all audiences\n• We reserve the right to remove any photos that violate these guidelines")
                                .font(.body)
                            
                            Text("5. Privacy and Data")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("• We collect and store your profile information securely\n• Your photos are visible to other users for rating\n• We do not sell your personal information\n• You can delete your account and data at any time")
                                .font(.body)
                            
                            Text("6. Rating System")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("• Ratings are anonymous\n• The Glicko-2 rating system is used for scoring\n• Leaderboards display top-rated photos\n• Ratings cannot be manipulated or gamed")
                                .font(.body)
                        }
                        
                        Group {
                            Text("7. Prohibited Conduct")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("You agree not to:\n• Upload photos of others without permission\n• Create multiple accounts\n• Attempt to manipulate ratings\n• Harass or abuse other users\n• Use the service for any illegal purpose")
                                .font(.body)
                            
                            Text("8. Termination")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("We reserve the right to terminate or suspend your account for violation of these terms.")
                                .font(.body)
                            
                            Text("9. Disclaimer")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("The service is provided \"as is\" without warranties of any kind. We are not responsible for any damages arising from your use of the service.")
                                .font(.body)
                            
                            Text("10. Contact")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            Text("For questions about these terms, please contact us through the app.")
                                .font(.body)
                            
                            // Bottom marker for scroll detection
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                                .onAppear {
                                    hasScrolledToBottom = true
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: acceptTerms) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Accept Terms")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                .disabled(isProcessing)
                
                Button(action: {
                    onDecline()
                }) {
                    Text("Decline and Logout")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .disabled(isProcessing)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    private func acceptTerms() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            let success = await onAccept()
            
            await MainActor.run {
                isProcessing = false
                if !success {
                    errorMessage = "Failed to accept terms. Please try again."
                }
            }
        }
    }
}

#Preview {
    TermsOfServiceView(
        onAccept: { true },
        onDecline: { }
    )
}