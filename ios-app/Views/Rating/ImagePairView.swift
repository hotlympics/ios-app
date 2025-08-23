//
//  ImagePairView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct ImagePairView: View {
    let topImageUrl: String
    let bottomImageUrl: String
    let cardWidth: CGFloat
    let onTopTap: () -> Void
    let onBottomTap: () -> Void
    
    private let cornerRadius: CGFloat = 16
    
    var cardHeight: CGFloat {
        cardWidth * 2 // 1:2 aspect ratio
    }
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 0) {
                // Top image area
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    CachedAsyncImageView(urlString: topImageUrl) { image in
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
                .onTapGesture(perform: onTopTap)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Bottom image area
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    CachedAsyncImageView(urlString: bottomImageUrl) { image in
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
                .onTapGesture(perform: onBottomTap)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}