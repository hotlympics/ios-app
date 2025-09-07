//
//  ImageQueueService.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import Foundation

class ImageQueueService: ObservableObject {
    static let shared = ImageQueueService()
    
    // Update this to match your server URL
    // For local development: "http://localhost:3000"
    // For production: your actual server URL
    private let apiUrl = Constants.API.baseURL
    private let blockSize = 10
    private let preloader = ImagePreloader.shared
    
    @Published var activeBlock: [ImageData] = []
    @Published var bufferBlock: [ImageData] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var isInitialized = false
    
    private var gender: String = "female"
    private var isFetchingBlock = false
    
    private init() {}
    
    func initialize() async {
        // Determine gender based on user's gender (show opposite gender)
        let viewingGender = await getViewingGender()
        
        // If already initialized with the same gender, don't re-fetch
        if isInitialized && self.gender == viewingGender && !activeBlock.isEmpty {
            return
        }
        
        self.gender = viewingGender
        self.currentIndex = 0
        self.activeBlock = []
        self.bufferBlock = []
        self.isInitialized = false
        
        // Load two blocks initially
        await loadInitialBlocks()
        
        // Mark as initialized once blocks are loaded
        if !activeBlock.isEmpty {
            isInitialized = true
        }
    }
    
    private func getViewingGender() async -> String {
        // Get current user from FirebaseAuthService
        if let user = FirebaseAuthService.shared.currentUser {
            // Show opposite gender to user's gender
            if user.gender == "male" {
                return "female"
            } else if user.gender == "female" {
                return "male"
            }
        }
        
        // Default to "female" for anonymous users or users with unknown gender
        return "female"
    }
    
    func reset() async {
        isInitialized = false
        currentIndex = 0
        activeBlock = []
        bufferBlock = []
        error = nil
        await initialize()
    }
    
    private func loadInitialBlocks() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch two blocks concurrently
            async let block1 = fetchImageBlock(count: blockSize)
            async let block2 = fetchImageBlock(count: blockSize)
            
            let blocks = try await [block1, block2]
            
            if let firstBlock = blocks[0], !firstBlock.isEmpty {
                activeBlock = firstBlock
                preloader.preloadImages(from: firstBlock)
            }
            
            if let secondBlock = blocks[1], !secondBlock.isEmpty {
                bufferBlock = secondBlock
                preloader.preloadImages(from: secondBlock)
            }
            
            if activeBlock.isEmpty {
                error = "No images available"
            }
        } catch {
            self.error = "Failed to load images: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func fetchImageBlock(count: Int) async throws -> [ImageData]? {
        guard let url = URL(string: "\(apiUrl)/images/block?gender=\(gender)&count=\(count)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if user is authenticated
        if let token = await FirebaseAuthService.shared.getIdToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        do {
            let blockResponse = try decoder.decode(ImageBlockResponse.self, from: data)
            return blockResponse.success ? blockResponse.images : nil
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
    
    func getCurrentPair() -> [ImageData]? {
        guard currentIndex + 1 < activeBlock.count else {
            return nil
        }
        
        return [activeBlock[currentIndex], activeBlock[currentIndex + 1]]
    }
    
    func peekNextPair() -> [ImageData]? {
        let nextIndex = currentIndex + 2
        
        // Check if next pair is in active block
        if nextIndex + 1 < activeBlock.count {
            return [activeBlock[nextIndex], activeBlock[nextIndex + 1]]
        }
        
        // Check if next pair would be in buffer block
        if !bufferBlock.isEmpty && bufferBlock.count >= 2 {
            return [bufferBlock[0], bufferBlock[1]]
        }
        
        return nil
    }
    
    func getNextPair() -> [ImageData]? {
        currentIndex += 2
        
        // Check if we need to switch to buffer block
        if currentIndex >= activeBlock.count - 1 {
            if !bufferBlock.isEmpty {
                // Switch blocks
                activeBlock = bufferBlock
                bufferBlock = []
                currentIndex = 0
                
                // Start fetching a new buffer block in background
                Task {
                    if let newBlock = try? await fetchImageBlock(count: blockSize),
                       !newBlock.isEmpty {
                        await MainActor.run {
                            self.bufferBlock = newBlock
                            self.preloader.preloadImages(from: newBlock)
                        }
                    }
                }
            } else {
                // No more images available, mark as not initialized to force refresh
                isInitialized = false
                return nil
            }
        }
        
        return getCurrentPair()
    }
}
