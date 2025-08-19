//
//  RatingView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct RatingView: View {
    @StateObject private var imageQueue = ImageQueueService.shared
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var currentPair: [ImageData] = []
    @State private var nextPair: [ImageData]? = nil
    @State private var pairKey: String = UUID().uuidString
    
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
                    // Swipeable card view with animation
                    SwipeCardView(
                        pair: currentPair,
                        onComplete: { winner in
                            handleImageSelection(winner)
                        },
                        nextPair: nextPair
                    )
                    .id(pairKey)  // Force view refresh when pair changes
                    .padding(.horizontal, 16)  // Side padding for card
                    .padding(.top, 8)  // Small top margin under island
                    .padding(.bottom, 8)  // Small bottom margin above tab bar
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
        .onChange(of: authService.user) { _ in
            // When user changes (login/logout), clear current pair and reload
            currentPair = []
            nextPair = nil
            pairKey = UUID().uuidString  // Force view refresh
            Task {
                await loadImages()
            }
        }
    }
    
    private func loadImages() async {
        await imageQueue.initialize()
        
        // If we already have a current pair (returning to tab), use it
        // Otherwise get the current pair from the queue
        if currentPair.isEmpty {
            if let pair = imageQueue.getCurrentPair() {
                currentPair = pair
                // Preload next pair for smooth transition
                nextPair = imageQueue.peekNextPair()
            }
        } else {
            // Just refresh the next pair preview
            nextPair = imageQueue.peekNextPair()
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
        if let newCurrentPair = imageQueue.getNextPair() {
            // Update pairs and force SwipeCardView to reset
            currentPair = newCurrentPair
            nextPair = imageQueue.peekNextPair()
            pairKey = UUID().uuidString  // Force view refresh
        } else {
            // Queue exhausted, reset and reinitialize
            currentPair = []
            Task {
                await imageQueue.reset()
                if let pair = imageQueue.getCurrentPair() {
                    currentPair = pair
                    nextPair = imageQueue.peekNextPair()
                }
            }
        }
    }
}

#Preview {
    RatingView()
}
