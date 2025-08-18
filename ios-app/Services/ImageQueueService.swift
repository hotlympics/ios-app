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
    private let apiUrl = "http://localhost:3000"
    private let blockSize = 10
    
    @Published var activeBlock: [ImageData] = []
    @Published var bufferBlock: [ImageData] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private var gender: String = "female"
    private var isFetchingBlock = false
    
    private init() {}
    
    func initialize(gender: String = "female") async {
        self.gender = gender
        self.currentIndex = 0
        self.activeBlock = []
        self.bufferBlock = []
        
        // Load two blocks initially
        await loadInitialBlocks()
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
            }
            
            if let secondBlock = blocks[1], !secondBlock.isEmpty {
                bufferBlock = secondBlock
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
                        }
                    }
                }
            } else {
                // No more images available
                return nil
            }
        }
        
        return getCurrentPair()
    }
}
