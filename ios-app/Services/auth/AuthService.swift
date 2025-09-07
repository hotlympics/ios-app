//
//  AuthService.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import Foundation
import AuthenticationServices
import CryptoKit

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = Constants.API.baseURL
    private var currentNonce: String?
    
    struct User: Codable {
        let id: Int
        let firebaseUid: String
        let email: String
        let displayName: String?
        let photoUrl: String?
        let isAdmin: Bool
        let createdAt: String
        let updatedAt: String
    }
    
    private override init() {
        super.init()
        loadStoredUser()
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presentingViewController: UIViewController) {
        isLoading = true
        errorMessage = nil
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentingViewController as? ASAuthorizationControllerPresentationContextProviding
        authorizationController.performRequests()
    }
    
    // MARK: - Backend Sync
    
    private func syncWithBackend(idToken: String) async {
        guard let url = URL(string: "\(baseURL)/auth/sync") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sync with backend"])
            }
            
            let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.user = syncResponse.user
                self.isAuthenticated = true
                self.isLoading = false
                self.saveUser(syncResponse.user)
                self.saveToken(idToken)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to sync with server: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        user = nil
        isAuthenticated = false
        clearStoredCredentials()
    }
    
    // MARK: - Token Management
    
    func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "user_data")
        }
    }
    
    private func loadStoredUser() {
        if let userData = UserDefaults.standard.data(forKey: "user_data"),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           let _ = UserDefaults.standard.string(forKey: "auth_token") {
            self.user = user
            self.isAuthenticated = true
        }
    }
    
    private func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "user_data")
    }
    
    // MARK: - Helper Functions
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private struct SyncResponse: Codable {
        let user: User
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Note: This is a placeholder for Google Sign-In
        // In production, you would use the actual Google Sign-In SDK
        // For now, this shows the structure that would be used
        isLoading = false
        errorMessage = "Google Sign-In SDK needs to be integrated"
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                errorMessage = "Sign in was cancelled"
            case .failed:
                errorMessage = "Sign in failed"
            case .invalidResponse:
                errorMessage = "Invalid response from sign in"
            case .notHandled:
                errorMessage = "Sign in not handled"
            case .unknown:
                errorMessage = "An unknown error occurred"
            case .notInteractive:
                errorMessage = "Sign in requires interaction"
            @unknown default:
                errorMessage = "An error occurred during sign in"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}