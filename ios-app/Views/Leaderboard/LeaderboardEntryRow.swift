//
//  LeaderboardEntryRow.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import SwiftUI

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private var isTopThree: Bool {
        rank <= 3
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0)  // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        default: return .secondary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Rank badge overlay on image
                ZStack(alignment: .topLeading) {
                    // Profile Image
                    CachedAsyncImageView(urlString: entry.imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 350, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isTopThree ? rankColor.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    
                    // Rank badge
                    ZStack {
                        if isTopThree {
                            Circle()
                                .fill(rankColor)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 32, height: 32)
                        }
                        
                        Text("\(rank)")
                            .font(.system(size: isTopThree ? 16 : 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 12, y: 12)
                }
                
                // Score underneath
                Text("\(entry.formattedRating) pts")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.gray.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

#Preview {
    VStack {
        LeaderboardEntryRow(
            entry: LeaderboardEntry(
                id: "1",
                rank: 1,
                imageUrl: "https://example.com/image1.jpg",
                userId: "user1",
                displayName: "User 1",
                rating: 1750,
                ratingDeviation: 50,
                battles: 100,
                wins: 75,
                losses: 25,
                winRate: 0.75
            ),
            rank: 1,
            onTap: {}
        )
        
        LeaderboardEntryRow(
            entry: LeaderboardEntry(
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
            rank: 4,
            onTap: {}
        )
    }
    .padding()
}