//
//  ProfileView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("My Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Sign in to upload photos")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
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