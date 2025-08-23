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
    let photoUrl: String?
    let firebaseUid: String?
    let googleId: String?
    
    // Profile information
    let gender: String?
    let dateOfBirth: String?
    let uploadedImageIds: [String]?
    let poolImageIds: [String]?
    
    // Terms of Service
    let tosVersion: String?
    let tosAcceptedAt: String?
    
    // Statistics (optional - not always returned by server)
    let rateCount: Int?
    
    // Profile completion checks
    var hasValidGender: Bool {
        guard let gender = gender else { return false }
        return gender == "male" || gender == "female"
    }
    
    var hasDateOfBirth: Bool {
        return dateOfBirth != nil && !dateOfBirth!.isEmpty
    }
    
    var hasAcceptedCurrentToS: Bool {
        return tosVersion == Constants.currentToSVersion
    }
    
    var isProfileComplete: Bool {
        return hasValidGender && hasDateOfBirth && hasAcceptedCurrentToS
    }
    
    var needsGenderAndDOB: Bool {
        return !hasValidGender || !hasDateOfBirth
    }
    
    var needsToSAcceptance: Bool {
        return !hasAcceptedCurrentToS
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoUrl
        case firebaseUid
        case googleId
        case gender
        case dateOfBirth
        case uploadedImageIds
        case poolImageIds
        case tosVersion
        case tosAcceptedAt
        case rateCount
    }
}