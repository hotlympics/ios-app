//
//  RatingView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct RatingView: View {
    @StateObject private var imageQueue = ImageQueueService.shared
    @State private var currentPair: [ImageData] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if imageQueue.isLoading {
                    Spacer()
                    ProgressView("Loading images...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if let error = imageQueue.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Text(error)
                            .font(.title3)
                            .foregroundColor(.red)
                        Text("Please check your connection and try again")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await loadImages()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if currentPair.count == 2 {
                    // Two images stacked vertically
                    VStack(spacing: 0) {
                        ImageElement(
                            imageData: currentPair[0],
                            onTap: { handleImageSelection(currentPair[0]) },
                            isTop: true
                        )
                        
                        ImageElement(
                            imageData: currentPair[1],
                            onTap: { handleImageSelection(currentPair[1]) },
                            isBottom: true
                        )
                    }
                    .padding(.horizontal, 0)  // No horizontal padding for maximum width
                    .padding(.bottom, 8)  // Small padding before tab bar
                } else {
                    Spacer()
                    Text("No images available")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        await imageQueue.initialize(gender: "female")
        if let pair = imageQueue.getCurrentPair() {
            currentPair = pair
        }
    }
    
    private func handleImageSelection(_ selectedImage: ImageData) {
        guard currentPair.count == 2 else { return }
        
        let winnerId = selectedImage.imageId
        let loser = currentPair.first { $0.imageId != winnerId }
        
        guard let loserId = loser?.imageId else { return }
        
        // Submit rating to server (non-blocking)
        Task {
            let success = await RatingService.shared.submitRating(
                winnerId: winnerId,
                loserId: loserId
            )
            if !success {
                print("Failed to submit rating for winner: \(winnerId), loser: \(loserId)")
            }
        }
        
        // Immediately show next pair (seamless transition)
        if let nextPair = imageQueue.getNextPair() {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPair = nextPair
            }
        } else {
            // Queue exhausted, need to reinitialize
            Task {
                await loadImages()
            }
        }
    }
}

#Preview {
    RatingView()
}
