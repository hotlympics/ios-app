//
//  User.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let createdAt: Date?
    let lastLoginAt: Date?
    
    // Profile information
    let gender: String?
    let dateOfBirth: String?
    let uploadedPhotos: [String]
    let poolPhotos: [String]
    
    // Statistics
    let totalBattles: Int
    let totalWins: Int
    let totalLosses: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoURL
        case createdAt
        case lastLoginAt
        case gender
        case dateOfBirth
        case uploadedPhotos
        case poolPhotos
        case totalBattles
        case totalWins
        case totalLosses
    }
}