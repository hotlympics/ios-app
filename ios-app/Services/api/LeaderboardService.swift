//
//  LeaderboardService.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import Foundation

enum LeaderboardType: String, CaseIterable {
    case femaleTop = "female_top"
    case femaleBottom = "female_bottom"
    case maleTop = "male_top"
    case maleBottom = "male_bottom"
    
    var displayName: String {
        switch self {
        case .femaleTop:
            return "Top Women"
        case .femaleBottom:
            return "Bottom Women"
        case .maleTop:
            return "Top Men"
        case .maleBottom:
            return "Bottom Men"
        }
    }
    
    var gender: String {
        switch self {
        case .femaleTop, .femaleBottom:
            return "female"
        case .maleTop, .maleBottom:
            return "male"
        }
    }
}

class LeaderboardService: ObservableObject {
    static let shared = LeaderboardService()
    
    private let baseURL = Constants.API.baseURL
    private let cacheValidityMinutes = 10
    private var cache: [LeaderboardType: CachedLeaderboard] = [:]
    
    private struct CachedLeaderboard {
        let data: LeaderboardResponse
        let timestamp: Date
        
        func isValid(validityMinutes: Int) -> Bool {
            let elapsed = Date().timeIntervalSince(timestamp)
            return elapsed < TimeInterval(validityMinutes * 60)
        }
    }
    
    private init() {}
    
    func fetchLeaderboard(type: LeaderboardType, forceRefresh: Bool = false) async throws -> LeaderboardResponse {
        // Check cache first unless force refresh is requested
        if !forceRefresh, let cached = cache[type], cached.isValid(validityMinutes: cacheValidityMinutes) {
            return cached.data
        }
        
        // Fetch from API
        guard let url = URL(string: "\(baseURL)/leaderboards/\(type.rawValue)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let token = await FirebaseAuthService.shared.getIdToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 404 {
                // Return empty response for 404 (no leaderboard data yet)
                let emptyResponse = LeaderboardResponse(
                    entries: [],
                    totalCount: 0,
                    gender: type.gender,
                    lastUpdated: nil
                )
                cache[type] = CachedLeaderboard(data: emptyResponse, timestamp: Date())
                return emptyResponse
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let leaderboardData = try decoder.decode(LeaderboardAPIResponse.self, from: data)
        
        // Transform API response to our model
        let leaderboardResponse = LeaderboardResponse(
            entries: leaderboardData.entries.enumerated().map { index, entry in
                LeaderboardEntry(
                    id: entry.imageId,
                    rank: index + 1,
                    imageUrl: entry.imageUrl,
                    userId: entry.userId,
                    displayName: nil,
                    rating: entry.rating,
                    ratingDeviation: entry.rd ?? 50,
                    battles: entry.battles,
                    wins: entry.wins,
                    losses: entry.losses,
                    winRate: entry.battles > 0 ? Double(entry.wins) / Double(entry.battles) : 0
                )
            },
            totalCount: leaderboardData.metadata.actualEntryCount,
            gender: type.gender,
            lastUpdated: ISO8601DateFormatter().date(from: leaderboardData.metadata.generatedAt)
        )
        
        // Cache the response
        cache[type] = CachedLeaderboard(data: leaderboardResponse, timestamp: Date())
        
        // Preload images for smooth scrolling
        await preloadImages(for: leaderboardResponse.entries)
        
        return leaderboardResponse
    }
    
    private func preloadImages(for entries: [LeaderboardEntry]) async {
        // Preload top 10 images
        let imagesToPreload = Array(entries.prefix(10))
        
        for entry in imagesToPreload {
            ImagePreloader.shared.loadImage(from: entry.imageUrl)
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func clearCache(for type: LeaderboardType) {
        cache.removeValue(forKey: type)
    }
}

// API Response Models (internal)
private struct LeaderboardAPIResponse: Codable {
    let entries: [APIEntry]
    let metadata: APIMetadata
    
    struct APIEntry: Codable {
        let imageId: String
        let imageUrl: String
        let userId: String
        let rating: Double
        let rd: Double?
        let battles: Int
        let wins: Int
        let losses: Int
        let draws: Int
        let gender: String
        let dateOfBirth: String?
    }
    
    struct APIMetadata: Codable {
        let generatedAt: String
        let updateCount: Int
        let firstGeneratedAt: String
        let actualEntryCount: Int
        let averageRating: Double
        let ratingRange: RatingRange
        let dataQuality: DataQuality
        let configVersion: Int
        let configKey: String
        
        struct RatingRange: Codable {
            let highest: Double
            let lowest: Double
        }
        
        struct DataQuality: Codable {
            let allImagesValid: Bool
            let missingFields: [String]
            let errorCount: Int
        }
    }
}