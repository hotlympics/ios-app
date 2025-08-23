//
//  View+Extensions.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

extension View {
    /// Applies a card style with shadow and corner radius
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hides the view conditionally
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
    
    /// Adds a loading overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
}