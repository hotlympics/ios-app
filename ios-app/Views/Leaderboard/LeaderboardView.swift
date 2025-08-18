//
//  LeaderboardView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct LeaderboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Leaderboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Coming Soon")
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
    LeaderboardView()
}