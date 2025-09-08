//
//  SignInPromptView.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import SwiftUI

struct SignInPromptView: View {
    @State private var showingSignIn = false
    let message: String
    let onAuthenticationSuccess: (() -> Void)?
    
    init(message: String = "Sign in to upload photos", onAuthenticationSuccess: (() -> Void)? = nil) {
        self.message = message
        self.onAuthenticationSuccess = onAuthenticationSuccess
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sheet(isPresented: $showingSignIn) {
            SignInView(onAuthenticationSuccess: onAuthenticationSuccess)
        }
    }
}

#Preview {
    SignInPromptView()
}

#Preview("Custom Message") {
    SignInPromptView(message: "Sign in to view your photos")
}