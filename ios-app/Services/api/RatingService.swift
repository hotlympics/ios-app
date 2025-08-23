//
//  RatingService.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import Foundation

class RatingService {
    static let shared = RatingService()
    
    // Use the same API URL as ImageQueueService
    private let apiUrl = "http://localhost:3000"
    
    private init() {}
    
    struct RatingResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    func submitRating(winnerId: String, loserId: String) async -> Bool {
        guard let url = URL(string: "\(apiUrl)/ratings") else {
            print("Invalid URL for rating submission")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if user is authenticated
        if let token = await FirebaseAuthService.shared.getIdToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "winnerId": winnerId,
            "loserId": loserId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                return false
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let ratingResponse = try decoder.decode(RatingResponse.self, from: data)
                return ratingResponse.success
            } else {
                print("Rating submission failed with status code: \(httpResponse.statusCode)")
                return false
            }
        } catch {
            print("Error submitting rating: \(error)")
            return false
        }
    }
}