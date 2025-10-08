//
//  ImageElement.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

// Custom shape for rounding specific corners
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ImageElement: View {
    let imageData: ImageData
    let onTap: () -> Void
    var isTop: Bool = false
    var isBottom: Bool = false
    
    @State private var isPressed = false
    
    private var cornerRadius: CGFloat { 12 }
    
    private var corners: UIRectCorner {
        if isTop {
            return [.topLeft, .topRight]
        } else if isBottom {
            return [.bottomLeft, .bottomRight]
        } else {
            return [.allCorners]
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        CachedAsyncImageView(
                            urlString: imageData.imageUrl
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        }
                    )
                    .clipShape(RoundedCornerShape(corners: corners, radius: cornerRadius))
                    .overlay(
                        RoundedCornerShape(corners: corners, radius: cornerRadius)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)  // Square aspect ratio
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Preview with mock data for testing
#Preview {
    VStack {
        ImageElement(
            imageData: ImageData(
                imageId: "test-1",
                userId: "user-1",
                imageUrl: "https://via.placeholder.com/300x400/FF6B6B/FFFFFF?text=Test+Image",
                gender: "female",
                dateOfBirth: FirestoreTimestamp(_seconds: Int(Date().timeIntervalSince1970), _nanoseconds: 0),
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
            onTap: { print("Tapped") }
        )
        .padding()
    }
}