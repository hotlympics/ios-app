//
//  Battle.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import Foundation

struct Battle: Codable, Identifiable {
    let id: String
    let winnerId: String
    let loserId: String
    let isDraw: Bool
    let voterId: String?
    let createdAt: Date
    
    // Glicko updates
    let winnerRatingBefore: Double
    let winnerRatingAfter: Double
    let loserRatingBefore: Double
    let loserRatingAfter: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case winnerId
        case loserId
        case isDraw
        case voterId
        case createdAt
        case winnerRatingBefore
        case winnerRatingAfter
        case loserRatingBefore
        case loserRatingAfter
    }
}

struct RatingSubmission: Codable {
    let winnerId: String
    let loserId: String
    let isDraw: Bool
    
    init(winnerId: String, loserId: String, isDraw: Bool = false) {
        self.winnerId = winnerId
        self.loserId = loserId
        self.isDraw = isDraw
    }
}