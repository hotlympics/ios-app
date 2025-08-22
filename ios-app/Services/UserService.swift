//
//  UserService.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import Foundation

class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var uploadedPhotosCount: Int = 0
    @Published var poolPhotosCount: Int = 0
    @Published var userPhotos: [UserPhoto] = []
    
    private let baseURL = "http://localhost:3000"
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    private let preloader = ImagePreloader.shared
    
    private init() {}
    
    struct UserPhoto: Identifiable, Hashable {
        let id: String
        let url: String
        let isInPool: Bool
        let stats: PhotoStats?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: UserPhoto, rhs: UserPhoto) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct PhotoStats: Hashable {
        let rating: Double
        let wins: Int
        let losses: Int
        let battles: Int
    }
    
    private var isDataStale: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheValidityDuration
    }
    
    func fetchUserData(forceRefresh: Bool = false) async {
        // Skip fetching if we have fresh data and not forcing refresh
        if !forceRefresh && !userPhotos.isEmpty && !isDataStale {
            print("Using cached user data")
            return
        }
        
        guard let token = await FirebaseAuthService.shared.getIdToken() else {
            print("No auth token available")
            return
        }
        
        do {
            // Fetch user images
            let imagesURL = URL(string: "\(baseURL)/images/user")!
            var request = URLRequest(url: imagesURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let images = try? JSONDecoder().decode([ImageResponse].self, from: data) {
                // Preload all images to cache
                for image in images {
                    preloader.loadImage(from: image.url)
                }
                
                await MainActor.run {
                    self.userPhotos = images.map { image in
                        UserPhoto(
                            id: image.id,
                            url: image.url,
                            isInPool: false, // Will need to be fetched from user data
                            stats: nil // Will be added when API supports it
                        )
                    }
                    self.uploadedPhotosCount = images.count
                }
            }
            
            // Fetch user profile to get pool image IDs
            let profileURL = URL(string: "\(baseURL)/user")!
            var profileRequest = URLRequest(url: profileURL)
            profileRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (profileData, _) = try await URLSession.shared.data(for: profileRequest)
            
            if let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
                await MainActor.run {
                    let poolIds = profile.poolImageIds ?? []
                    self.poolPhotosCount = poolIds.count
                    // Update isInPool status for photos
                    self.userPhotos = self.userPhotos.map { photo in
                        UserPhoto(
                            id: photo.id,
                            url: photo.url,
                            isInPool: poolIds.contains(photo.id),
                            stats: photo.stats
                        )
                    }
                }
            }
            
            // Update last fetch time on successful fetch
            await MainActor.run {
                self.lastFetchTime = Date()
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
    
    func updatePoolSelection(imageIds: [String]) async -> Bool {
        guard let token = await FirebaseAuthService.shared.getIdToken() else {
            print("No auth token available")
            return false
        }
        
        do {
            let url = URL(string: "\(baseURL)/user/pool")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["poolImageIds": imageIds]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                await fetchUserData(forceRefresh: true) // Force refresh data after update
                return true
            }
        } catch {
            print("Error updating pool selection: \(error)")
        }
        
        return false
    }
    
    func clearCache() {
        userPhotos = []
        uploadedPhotosCount = 0
        poolPhotosCount = 0
        lastFetchTime = nil
    }
}

// Response models
private struct ImageResponse: Decodable {
    let id: String
    let url: String
}

private struct UserProfile: Decodable {
    let id: String
    let email: String
    let uploadedImageIds: [String]?
    let poolImageIds: [String]?
    let gender: String?
    let rateCount: Int?
}