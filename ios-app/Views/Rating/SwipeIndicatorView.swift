//
//  SwipeIndicatorView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct SwipeIndicatorView: View {
    let dragOffset: CGSize
    let isDragging: Bool
    
    private let threshold: CGFloat = 80
    
    var isGoingUp: Bool {
        dragOffset.height < -threshold
    }
    
    var isGoingDown: Bool {
        dragOffset.height > threshold
    }
    
    var body: some View {
        if isDragging && (isGoingUp || isGoingDown) {
            VStack {
                if isGoingUp {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                    
                    Spacer()
                } else if isGoingDown {
                    Spacer()
                    
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: isGoingUp)
            .animation(.spring(response: 0.3), value: isGoingDown)
        }
    }
}