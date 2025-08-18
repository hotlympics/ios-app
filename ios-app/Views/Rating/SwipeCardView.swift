//
//  SwipeCardView.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct SwipeCardView: View {
    let pair: [ImageData]
    let onComplete: (ImageData) -> Void
    let nextPair: [ImageData]?
    
    @State private var dragOffset: CGSize = .zero
    @State private var exitDirection: ExitDirection? = nil
    @State private var isDragging = false
    @State private var hasCompleted = false
    
    enum ExitDirection {
        case up, down
    }
    
    private let dragThreshold: CGFloat = 80
    private let velocityThreshold: CGFloat = 700
    private let cornerRadius: CGFloat = 16
    
    var topImage: ImageData { pair[0] }
    var bottomImage: ImageData { pair[1] }
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate card dimensions to fill available space with small margins
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            
            // Card should be as large as possible while maintaining 1:2 ratio
            // Calculate based on height constraint (most limiting on phones)
            let heightBasedWidth = availableHeight / 2
            let widthBasedWidth = availableWidth
            
            // Use the smaller of the two to ensure it fits
            let cardWidth = min(heightBasedWidth, widthBasedWidth, 400)
            let cardHeight = cardWidth * 2 // 1:2 aspect ratio (two square images stacked)
            let offscreenDistance = geometry.size.height + 200
            
            ZStack {
                // Background next pair (visible during swipe)
                if let nextPair = nextPair, nextPair.count == 2 {
                    ZStack {
                        Color.white
                        
                        VStack(spacing: 0) {
                            // Top image
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                
                                CachedAsyncImage(urlString: nextPair[0].imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: cardWidth, height: cardWidth)
                                        .clipped()
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                }
                            }
                            .frame(width: cardWidth, height: cardWidth)
                            .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: cornerRadius))
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Bottom image
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                
                                CachedAsyncImage(urlString: nextPair[1].imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: cardWidth, height: cardWidth)
                                        .clipped()
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                }
                            }
                            .frame(width: cardWidth, height: cardWidth)
                            .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius))
                        }
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .allowsHitTesting(false)
                }
                
                // Main swipeable card
                ZStack {
                    Color.white
                    
                    VStack(spacing: 0) {
                        // Top image area
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                            
                            CachedAsyncImage(urlString: topImage.imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: cardWidth, height: cardWidth)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                            }
                        }
                        .frame(width: cardWidth, height: cardWidth)
                        .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: cornerRadius))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectImage(.up)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Bottom image area
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                            
                            CachedAsyncImage(urlString: bottomImage.imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: cardWidth, height: cardWidth)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                            }
                        }
                        .frame(width: cardWidth, height: cardWidth)
                        .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectImage(.down)
                        }
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .offset(y: calculateOffset(offscreenDistance: offscreenDistance))
                .rotationEffect(calculateRotation())
                .scaleEffect(calculateScale())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if exitDirection == nil {
                                isDragging = true
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            handleDragEnd(value: value)
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: exitDirection)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onChange(of: exitDirection) { newValue in
            if newValue != nil && !hasCompleted {
                hasCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let winner = newValue == .up ? topImage : bottomImage
                    onComplete(winner)
                }
            }
        }
    }
    
    private func calculateOffset(offscreenDistance: CGFloat) -> CGFloat {
        if let exitDirection = exitDirection {
            return exitDirection == .up ? -offscreenDistance : offscreenDistance
        }
        return dragOffset.height
    }
    
    private func calculateRotation() -> Angle {
        if let exitDirection = exitDirection {
            return .degrees(exitDirection == .up ? -3 : 3)
        }
        return .degrees(Double(dragOffset.height) * 0.01)
    }
    
    private func calculateScale() -> CGFloat {
        if exitDirection != nil {
            return 0.98
        }
        if isDragging {
            return 0.995
        }
        return 1.0
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
        let verticalMovement = value.translation.height
        let velocity = value.predictedEndLocation.y - value.location.y
        
        let shouldAccept = abs(verticalMovement) > dragThreshold ||
                          abs(velocity) > velocityThreshold
        
        if shouldAccept {
            selectImage(verticalMovement < 0 ? .up : .down)
        } else {
            withAnimation(.spring()) {
                dragOffset = .zero
            }
        }
    }
    
    private func selectImage(_ direction: ExitDirection) {
        guard exitDirection == nil else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            exitDirection = direction
        }
    }
}

#Preview {
    SwipeCardView(
        pair: [
            ImageData(
                imageId: "test-1",
                userId: "user-1",
                imageUrl: "https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Top",
                gender: "female",
                dateOfBirth: ISO8601DateFormatter().string(from: Date()),
                battles: 100,
                wins: 50,
                losses: 50,
                draws: 0,
                glicko: GlickoState(
                    rating: 1500,
                    rd: 350,
                    volatility: 0.06,
                    mu: 0,
                    phi: 2.0,
                    lastUpdateAt: FirestoreTimestamp(_seconds: Int(Date().timeIntervalSince1970), _nanoseconds: 0),
                    systemVersion: 2
                ),
                inPool: true,
                status: "active"
            ),
            ImageData(
                imageId: "test-2",
                userId: "user-2",
                imageUrl: "https://via.placeholder.com/300x400/4ECDC4/FFFFFF?text=Bottom",
                gender: "female",
                dateOfBirth: ISO8601DateFormatter().string(from: Date()),
                battles: 80,
                wins: 40,
                losses: 40,
                draws: 0,
                glicko: GlickoState(
                    rating: 1450,
                    rd: 350,
                    volatility: 0.06,
                    mu: 0,
                    phi: 2.0,
                    lastUpdateAt: FirestoreTimestamp(_seconds: Int(Date().timeIntervalSince1970), _nanoseconds: 0),
                    systemVersion: 2
                ),
                inPool: true,
                status: "active"
            )
        ],
        onComplete: { winner in
            print("Winner: \(winner.imageId)")
        },
        nextPair: nil
    )
    .padding()
}