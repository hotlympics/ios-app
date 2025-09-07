//
//  LeaderboardListView.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import SwiftUI

struct LeaderboardListView: View {
    let entries: [LeaderboardEntry]
    let onEntryTap: (LeaderboardEntry) -> Void
    
    var body: some View {
        if entries.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text("No entries yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Be the first to compete!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVStack(spacing: 4) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardEntryRow(
                        entry: entry,
                        rank: index + 4,  // Starting from rank 4 since top 3 are in podium
                        onTap: { onEntryTap(entry) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ScrollView {
        LeaderboardListView(
            entries: [
                LeaderboardEntry(
                    id: "4",
                    rank: 4,
                    imageUrl: "https://example.com/image4.jpg",
                    userId: "user4",
                    displayName: "User 4",
                    rating: 1550,
                    ratingDeviation: 60,
                    battles: 50,
                    wins: 30,
                    losses: 20,
                    winRate: 0.6
                ),
                LeaderboardEntry(
                    id: "5",
                    rank: 5,
                    imageUrl: "https://example.com/image5.jpg",
                    userId: "user5",
                    displayName: "User 5",
                    rating: 1500,
                    ratingDeviation: 65,
                    battles: 40,
                    wins: 20,
                    losses: 20,
                    winRate: 0.5
                )
            ],
            onEntryTap: { _ in }
        )
    }
}