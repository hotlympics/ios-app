//
//  LeaderboardDetailView.swift
//  ios-app
//
//  Created on 25/08/2025.
//

import SwiftUI

struct LeaderboardDetailView: View {
    let entry: LeaderboardEntry
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var isDragging = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
                .opacity(isDragging ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            
            // Image with gestures
            CachedAsyncImageView(urlString: entry.imageUrl) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 0.5), 3.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        withAnimation(.spring()) {
                            if scale < 1.0 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else if scale > 2.5 {
                                scale = 2.5
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                     }
                     .onChanged { value in
                         if scale > 1.0 {
                             // Allow panning when zoomed
                             offset = CGSize(
                                 width: lastOffset.width + value.translation.width,
                                 height: lastOffset.height + value.translation.height
                             )
                         } else {
                             // Swipe down to dismiss
                             if value.translation.height > 0 {
                                 offset = CGSize(
                                     width: 0,
                                     height: value.translation.height
                                 )
                             }
                         }
                     }
                     .onEnded { value in
                         if scale <= 1.0 && value.translation.height > 100 {
                             // Dismiss if swiped down enough
                             isPresented = false
                         } else {
                             lastOffset = offset
                             if scale <= 1.0 {
                                 withAnimation(.spring()) {
                                     offset = .zero
                                     lastOffset = .zero
                                 }
                             }
                         }
                     }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1.0 {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.0
                    }
                }
            }
            
            // Close button overlay
            VStack {
                HStack {
                    // Close button
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                 Spacer()
            }
        }
    }
}

#Preview {
    LeaderboardDetailView(
        entry: LeaderboardEntry(
            id: "1",
            rank: 1,
            imageUrl: "https://example.com/image1.jpg",
            userId: "user1",
            displayName: "User 1",
            rating: 1750,
            ratingDeviation: 50,
            battles: 100,
            wins: 75,
            losses: 25,
            winRate: 0.75
        ),
        isPresented: .constant(true)
    )
}