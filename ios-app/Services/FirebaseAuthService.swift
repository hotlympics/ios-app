//
//  FirebaseAuthService.swift
//  ios-app
//
//  Created on 19/08/2025.
//

import Foundation
import SwiftUI

// NOTE: To use this service, you need to:
// 1. Add Firebase SDK to your Xcode project via Swift Package Manager:
//    - In Xcode, go to File > Add Package Dependencies
//    - Enter: https://github.com/firebase/firebase-ios-sdk
//    - Select FirebaseAuth and GoogleSignIn packages
// 2. Replace the placeholder GoogleService-Info.plist with your actual Firebase config
// 3. Configure URL schemes in your Info.plist
// 4. Uncomment the Firebase imports and implementation below

import Firebase
import FirebaseAuth
import GoogleSignIn

class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000"
    
    struct User: Codable, Equatable {
        let id: String
        let firebaseUid: String
        let email: String
        let googleId: String?
        let gender: String
        let dateOfBirth: String?
        let tosVersion: String?
        let tosAcceptedAt: String?
        let rateCount: Int
        let uploadedImageIds: [String]
        let poolImageIds: [String]
        let displayName: String?
        let photoUrl: String?
    }
    
    private init() {
        setupAuthStateListener()
        loadStoredUser()
    }
    
    // MARK: - Setup
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                Task {
                    await self?.handleAuthStateChange(firebaseUser: firebaseUser)
                }
            } else {
                DispatchQueue.main.async {
                    self?.user = nil
                    self?.isAuthenticated = false
                    self?.clearStoredCredentials()
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() {
        print("Starting Google Sign-In...")
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("ERROR: Firebase configuration error - no client ID")
            errorMessage = "Firebase configuration error"
            isLoading = false
            return
        }
        
        print("Client ID found: \(clientID)")
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("ERROR: Cannot find root view controller")
            errorMessage = "Cannot find root view controller"
            isLoading = false
            return
        }
        
        print("Presenting Google Sign-In...")
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            print("Google Sign-In callback received")
            if let error = error {
                print("ERROR in Google Sign-In: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = self?.getErrorMessage(from: error) ?? "Sign in failed"
                    self?.isLoading = false
                }
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("ERROR: Failed to get user or token from result")
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to get authentication token"
                    self?.isLoading = false
                }
                return
            }
            
            print("Successfully got Google user, proceeding with Firebase auth...")
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = self?.getErrorMessage(from: error) ?? "Authentication failed"
                        self?.isLoading = false
                    }
                    return
                }
                
                if let firebaseUser = authResult?.user {
                    Task {
                        await self?.handleAuthStateChange(firebaseUser: firebaseUser)
                    }
                }
            }
        }
    }
    
    // MARK: - Backend Sync
    
    private func handleAuthStateChange(firebaseUser: Any) async {
        guard let firebaseUser = firebaseUser as? FirebaseAuth.User else { return }
        
        do {
            let idToken = try await firebaseUser.getIDToken()
            await syncWithBackend(idToken: idToken)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to get authentication token"
                self.isLoading = false
            }
        }
    }
    
    private func syncWithBackend(idToken: String) async {
        guard let url = URL(string: "\(baseURL)/auth/sync") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Print the raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Backend response: \(jsonString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Backend error (status \(httpResponse.statusCode)): \(errorMessage)")
                throw NSError(domain: "AuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Backend error: \(errorMessage)"])
            }
            
            let decoder = JSONDecoder()
            let syncResponse = try decoder.decode(SyncResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.user = syncResponse.user
                self.isAuthenticated = true
                self.isLoading = false
                self.saveUser(syncResponse.user)
                self.saveToken(idToken)
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to sync with server: Data format error"
                self.isLoading = false
            }
        } catch {
            print("Sync error: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to sync with server: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            user = nil
            isAuthenticated = false
            clearStoredCredentials()
        } catch {
            errorMessage = "Failed to sign out"
        }
    }
    
    // MARK: - Token Management
    
    func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    func getIdToken() async -> String? {
        guard let currentUser = Auth.auth().currentUser else { return nil }
        
        do {
            return try await currentUser.getIDToken()
        } catch {
            print("Error getting ID token: \(error)")
            return nil
        }
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
    
    // MARK: - Error Handling
    
    private func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        // Map common error codes to user-friendly messages
        switch nsError.code {
        case -5:
            return "Sign in was cancelled"
        case 17007:
            return "This email is already registered"
        case 17008:
            return "Invalid email address"
        case 17011:
            return "No account found with this email"
        case 17009:
            return "Incorrect password"
        case 17020:
            return "Network error. Please check your connection"
        default:
            return "An error occurred. Please try again"
        }
    }
    
    private struct SyncResponse: Codable {
        let user: User
    }
}