//
//  LeaderboardPodiumView.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import SwiftUI

struct LeaderboardPodiumView: View {
    let entries: [LeaderboardEntry]
    let onEntryTap: (LeaderboardEntry) -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Second place
            if entries.count > 1 {
                PodiumPosition(
                    entry: entries[1],
                    rank: 2,
                    position: .second,
                    onTap: onEntryTap
                )
            } else {
                Spacer()
                    .frame(width: 112)
            }
            
            // First place
            if entries.count > 0 {
                PodiumPosition(
                    entry: entries[0],
                    rank: 1,
                    position: .first,
                    onTap: onEntryTap
                )
            }
            
            // Third place
            if entries.count > 2 {
                PodiumPosition(
                    entry: entries[2],
                    rank: 3,
                    position: .third,
                    onTap: onEntryTap
                )
            } else {
                Spacer()
                    .frame(width: 112)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct PodiumPosition: View {
    let entry: LeaderboardEntry
    let rank: Int
    let position: Position
    let onTap: (LeaderboardEntry) -> Void
    
    enum Position {
        case first, second, third
        
        var imageSize: CGFloat {
            switch self {
            case .first: return 140
            case .second, .third: return 112
            }
        }
        
        var offset: CGFloat {
            switch self {
            case .first: return -30
            case .second, .third: return 20
            }
        }
        
        var borderColor: Color {
            switch self {
            case .first: return Color(red: 1.0, green: 0.84, blue: 0)  // Gold
            case .second: return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
            case .third: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
            }
        }
    }
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Crown for first place
            if position == .first {
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: 15)
                    .zIndex(1)
            }
            
            // Profile Image with rank badge
            ZStack(alignment: .bottom) {
                Button(action: { onTap(entry) }) {
                    CachedAsyncImageView(urlString: entry.imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .frame(width: position.imageSize, height: position.imageSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(position.borderColor, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity) { pressing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = pressing
                    }
                } perform: {}
                
                // Rank Badge
                Circle()
                    .fill(Color.green)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("\(rank)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(y: 10)
            }
            .offset(y: position.offset)
            
            // Score
            VStack(spacing: 2) {
                Text("\(entry.formattedRating)")
                    .font(.system(size: position == .first ? 20 : 18, weight: .bold))
                    .foregroundColor(Color.green)
                
                Text("pts")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, position == .first ? 20 : 35)
        }
    }
}

#Preview {
    LeaderboardPodiumView(
        entries: [
            LeaderboardEntry(
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
            LeaderboardEntry(
                id: "2",
                rank: 2,
                imageUrl: "https://example.com/image2.jpg",
                userId: "user2",
                displayName: "User 2",
                rating: 1650,
                ratingDeviation: 55,
                battles: 80,
                wins: 50,
                losses: 30,
                winRate: 0.625
            ),
            LeaderboardEntry(
                id: "3",
                rank: 3,
                imageUrl: "https://example.com/image3.jpg",
                userId: "user3",
                displayName: "User 3",
                rating: 1600,
                ratingDeviation: 60,
                battles: 70,
                wins: 40,
                losses: 30,
                winRate: 0.571
            )
        ],
        onEntryTap: { _ in }
    )
}