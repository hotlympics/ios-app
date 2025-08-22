//
//  UploadService.swift
//  ios-app
//
//  Created by Assistant on 19/08/2025.
//

import Foundation
import UIKit

class UploadService: ObservableObject {
    static let shared = UploadService()
    
    private let baseURL = "http://localhost:3000"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadStatus = ""
    
    private init() {}
    
    struct UploadUrlResponse: Codable {
        let success: Bool
        let imageId: String
        let uploadUrl: String
        let downloadUrl: String
        let fileName: String
        let message: String
    }
    
    func requestUploadUrl(fileExtension: String = "jpg") async throws -> UploadUrlResponse {
        guard let token = await FirebaseAuthService.shared.getIdToken() else {
            throw UploadError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/images/request-upload") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["fileExtension": fileExtension]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UploadError.requestFailed
        }
        
        return try JSONDecoder().decode(UploadUrlResponse.self, from: data)
    }
    
    func uploadToFirebase(imageData: Data, uploadUrl: String) async throws {
        guard let url = URL(string: uploadUrl) else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let session = URLSession(configuration: .default, delegate: UploadDelegate(self), delegateQueue: nil)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UploadError.uploadFailed
        }
    }
    
    func confirmUpload(imageId: String, fileName: String) async throws {
        guard let token = await FirebaseAuthService.shared.getIdToken() else {
            throw UploadError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/images/confirm-upload/\(imageId)") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["actualFileName": fileName]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UploadError.confirmationFailed
        }
    }
    
    func uploadPhoto(_ image: UIImage) async throws {
        await MainActor.run {
            self.isUploading = true
            self.uploadProgress = 0
            self.uploadStatus = "Preparing image..."
        }
        
        defer {
            Task { @MainActor in
                self.isUploading = false
                self.uploadStatus = ""
                self.uploadProgress = 0
            }
        }
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw UploadError.imageCompressionFailed
        }
        
        await MainActor.run {
            self.uploadStatus = "Requesting upload permission..."
        }
        
        // Request upload URL
        let uploadResponse = try await requestUploadUrl(fileExtension: "jpg")
        
        await MainActor.run {
            self.uploadStatus = "Uploading to cloud..."
        }
        
        // Upload to Firebase
        try await uploadToFirebase(imageData: imageData, uploadUrl: uploadResponse.uploadUrl)
        
        await MainActor.run {
            self.uploadStatus = "Finalizing upload..."
        }
        
        // Confirm upload
        try await confirmUpload(imageId: uploadResponse.imageId, fileName: uploadResponse.fileName)
        
        await MainActor.run {
            self.uploadStatus = "Upload complete!"
        }
        
        // Force refresh user data to show the new photo
        await UserService.shared.fetchUserData(forceRefresh: true)
    }
    
    enum UploadError: LocalizedError {
        case notAuthenticated
        case invalidURL
        case requestFailed
        case uploadFailed
        case confirmationFailed
        case imageCompressionFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be signed in to upload photos"
            case .invalidURL:
                return "Invalid server URL"
            case .requestFailed:
                return "Failed to request upload permission"
            case .uploadFailed:
                return "Failed to upload image"
            case .confirmationFailed:
                return "Failed to confirm upload"
            case .imageCompressionFailed:
                return "Failed to compress image"
            }
        }
    }
    
    private class UploadDelegate: NSObject, URLSessionTaskDelegate {
        private weak var uploadService: UploadService?
        
        init(_ uploadService: UploadService) {
            self.uploadService = uploadService
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            Task { @MainActor in
                self.uploadService?.uploadProgress = progress * 100
            }
        }
    }
}