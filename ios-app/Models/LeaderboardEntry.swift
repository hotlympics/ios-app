//
//  LeaderboardEntry.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let rank: Int
    let imageUrl: String
    let userId: String
    let displayName: String?
    let rating: Double
    let ratingDeviation: Double
    let battles: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    
    var formattedRating: String {
        String(format: "%.0f", rating)
    }
    
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "imageId"
        case rank
        case imageUrl
        case userId
        case displayName
        case rating
        case ratingDeviation = "rd"
        case battles
        case wins
        case losses
        case winRate
    }
}

struct LeaderboardResponse: Codable {
    let entries: [LeaderboardEntry]
    let totalCount: Int
    let gender: String
    let lastUpdated: Date?
}