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
            HStack(spacing: 12) {
                // Rank
                ZStack {
                    if isTopThree {
                        Circle()
                            .fill(rankColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                    }
                    
                    Text("\(rank)")
                        .font(.system(size: isTopThree ? 18 : 16, weight: isTopThree ? .bold : .semibold))
                        .foregroundColor(isTopThree ? rankColor : .secondary)
                }
                .frame(width: 36)
                
                // Profile Image
                CachedAsyncImageView(urlString: entry.imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isTopThree ? rankColor.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 2)
                )
                
                // Spacer
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.formattedRating)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                    
                    if entry.battles > 0 {
                        HStack(spacing: 2) {
                            Text("\(entry.wins)W")
                                .foregroundColor(.green)
                            Text("-")
                                .foregroundColor(.secondary)
                            Text("\(entry.losses)L")
                                .foregroundColor(.red)
                        }
                        .font(.system(size: 12))
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
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