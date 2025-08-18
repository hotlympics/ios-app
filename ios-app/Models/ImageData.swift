//
//  ImageData.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import Foundation

// Firestore Timestamp structure
struct FirestoreTimestamp: Codable {
    let _seconds: Int
    let _nanoseconds: Int
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(_seconds) + TimeInterval(_nanoseconds) / 1_000_000_000)
    }
}

struct GlickoState: Codable {
    let rating: Double
    let rd: Double
    let volatility: Double
    let mu: Double
    let phi: Double
    let lastUpdateAt: FirestoreTimestamp
    let systemVersion: Int
    
    var lastUpdateDate: Date {
        return lastUpdateAt.date
    }
}

struct ImageData: Codable, Identifiable {
    let imageId: String
    let userId: String
    let imageUrl: String
    let gender: String
    let dateOfBirth: String  // ISO 8601 date string from server
    let battles: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let glicko: GlickoState
    let inPool: Bool
    let status: String?
    
    var id: String { imageId }
    
    var birthDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateOfBirth) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateOfBirth)
    }
}

struct ImageBlockResponse: Codable {
    let success: Bool
    let images: [ImageData]
    let timestamp: String
}