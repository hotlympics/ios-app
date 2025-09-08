//
//  SignInView.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingError = false
    let onAuthenticationSuccess: (() -> Void)?
    
    init(onAuthenticationSuccess: (() -> Void)? = nil) {
        self.onAuthenticationSuccess = onAuthenticationSuccess
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back to rating")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // Main Content
                VStack(spacing: 24) {
                    // Title
                    Text("Sign In or Sign Up")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text("Sign in with your Google account")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Google Sign In Button
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            GoogleLogo()
                                .frame(width: 20, height: 20)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    .disabled(authService.isLoading)
                    .opacity(authService.isLoading ? 0.6 : 1.0)
                    
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .alert("Sign In Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authService.errorMessage ?? "An error occurred during sign in")
            }
            .onChange(of: authService.errorMessage) { newValue in
                if newValue != nil {
                    showingError = true
                }
            }
            .onChange(of: authService.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    onAuthenticationSuccess?()
                    dismiss()
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        authService.signInWithGoogle()
    }
}

// Google Logo Component
struct GoogleLogo: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 20, y: 10.12))
                path.addCurve(to: CGPoint(x: 19.8, y: 8),
                              control1: CGPoint(x: 20, y: 9.42),
                              control2: CGPoint(x: 19.93, y: 8.72))
                path.addLine(to: CGPoint(x: 10, y: 8))
                path.addLine(to: CGPoint(x: 10, y: 12))
                path.addLine(to: CGPoint(x: 15.64, y: 12))
                path.addCurve(to: CGPoint(x: 13.62, y: 14.98),
                              control1: CGPoint(x: 15.41, y: 13.2),
                              control2: CGPoint(x: 14.73, y: 14.24))
                path.addLine(to: CGPoint(x: 13.62, y: 17.55))
                path.addLine(to: CGPoint(x: 16.9, y: 17.55))
                path.addCurve(to: CGPoint(x: 20, y: 10.12),
                              control1: CGPoint(x: 18.73, y: 15.86),
                              control2: CGPoint(x: 20, y: 13.15))
                path.closeSubpath()
            }
            .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
            
            Path { path in
                path.move(to: CGPoint(x: 10, y: 20))
                path.addCurve(to: CGPoint(x: 16.9, y: 17.55),
                              control1: CGPoint(x: 12.7, y: 20),
                              control2: CGPoint(x: 15.09, y: 19.12))
                path.addLine(to: CGPoint(x: 13.62, y: 14.98))
                path.addCurve(to: CGPoint(x: 10, y: 16.32),
                              control1: CGPoint(x: 12.73, y: 15.58),
                              control2: CGPoint(x: 11.46, y: 16.04))
                path.addCurve(to: CGPoint(x: 4.93, y: 11.31),
                              control1: CGPoint(x: 7.21, y: 16.32),
                              control2: CGPoint(x: 5.18, y: 14.27))
                path.addLine(to: CGPoint(x: 1.68, y: 11.31))
                path.addLine(to: CGPoint(x: 1.68, y: 13.91))
                path.addCurve(to: CGPoint(x: 10, y: 20),
                              control1: CGPoint(x: 3.31, y: 17.15),
                              control2: CGPoint(x: 6.41, y: 20))
                path.closeSubpath()
            }
            .fill(Color(red: 52/255, green: 168/255, blue: 83/255))
            
            Path { path in
                path.move(to: CGPoint(x: 4.93, y: 8.69))
                path.addCurve(to: CGPoint(x: 4.61, y: 10),
                              control1: CGPoint(x: 4.74, y: 9.2),
                              control2: CGPoint(x: 4.61, y: 9.59))
                path.addCurve(to: CGPoint(x: 4.93, y: 11.31),
                              control1: CGPoint(x: 4.61, y: 10.41),
                              control2: CGPoint(x: 4.74, y: 10.8))
                path.addLine(to: CGPoint(x: 1.68, y: 11.31))
                path.addLine(to: CGPoint(x: 1.68, y: 8.69))
                path.addCurve(to: CGPoint(x: 0.63, y: 10),
                              control1: CGPoint(x: 1.07, y: 9.29),
                              control2: CGPoint(x: 0.63, y: 9.63))
                path.addCurve(to: CGPoint(x: 1.68, y: 13.91),
                              control1: CGPoint(x: 0.63, y: 11.39),
                              control2: CGPoint(x: 1.07, y: 12.71))
                path.addLine(to: CGPoint(x: 4.93, y: 11.31))
                path.closeSubpath()
            }
            .fill(Color(red: 251/255, green: 188/255, blue: 5/255))
            
            Path { path in
                path.move(to: CGPoint(x: 10, y: 4.07))
                path.addCurve(to: CGPoint(x: 13.83, y: 5.55),
                              control1: CGPoint(x: 11.53, y: 4.07),
                              control2: CGPoint(x: 12.83, y: 4.57))
                path.addLine(to: CGPoint(x: 16.73, y: 2.73))
                path.addCurve(to: CGPoint(x: 10, y: 0),
                              control1: CGPoint(x: 14.92, y: 1.03),
                              control2: CGPoint(x: 12.62, y: 0))
                path.addCurve(to: CGPoint(x: 1.68, y: 6.31),
                              control1: CGPoint(x: 6.41, y: 0),
                              control2: CGPoint(x: 3.31, y: 2.85))
                path.addLine(to: CGPoint(x: 4.93, y: 8.69))
                path.addCurve(to: CGPoint(x: 10, y: 4.07),
                              control1: CGPoint(x: 5.75, y: 6.24),
                              control2: CGPoint(x: 7.65, y: 4.07))
                path.closeSubpath()
            }
            .fill(Color(red: 234/255, green: 67/255, blue: 53/255))
        }
    }
}

#Preview {
    SignInView()
}