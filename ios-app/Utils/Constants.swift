//
//  Constants.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import Foundation

struct Constants {
    // Current Terms of Service version - must match backend
    static let currentToSVersion = "1.0"
    
    struct API {
        static let baseURL = "http://localhost:3000"
        static let timeout: TimeInterval = 30
        
        struct Endpoints {
            static let imagesPair = "/images/pair"
            static let imagesBlock = "/images/block"
            static let ratings = "/ratings"
            static let leaderboards = "/leaderboards"
            static let requestUpload = "/images/request-upload"
            static let confirmUpload = "/images/confirm-upload"
            static let userImages = "/images/user"
            static let user = "/user"
            static let userPool = "/user/pool"
            static let userProfile = "/user/profile"
            static let acceptToS = "/user/accept-tos"
        }
    }
    
    struct Images {
        static let maxUploadSize = 10 * 1024 * 1024 // 10MB
        static let compressionQuality: CGFloat = 0.8
        static let cropSize = 400
        static let maxPhotosPerUser = 10
        static let maxPoolSize = 2
    }
    
    struct Cache {
        static let imagesCacheLimit = 50
        static let userDataValidityMinutes = 5
    }
    
    struct Animation {
        static let defaultDuration = 0.3
        static let springResponse = 0.4
        static let springDamping = 0.8
    }
    
    struct Rating {
        static let swipeThreshold: CGFloat = 80
        static let velocityThreshold: CGFloat = 700
        static let blockSize = 10
    }
}