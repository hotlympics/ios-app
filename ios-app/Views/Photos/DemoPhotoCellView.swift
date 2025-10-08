//
//  DemoPhotoCellView.swift
//  ios-app
//
//  Created for demo view purposes
//

import SwiftUI

struct DemoPhotoCellView: View {
    let photo: DemoPhoto

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Photo image
                Image(photo.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(photo.isInPool ? Color.green : Color.clear, lineWidth: 4)
                    )

            // Pool indicator (top-left)
            if photo.isInPool {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    )
                    .padding(8)
            }

            // Delete button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .disabled(true)
                    .padding(8)
                }
                Spacer()
            }

            // Rating and Win/Loss overlays (bottom)
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    // Rating (bottom-left)
                    Text("\(photo.rating)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .cornerRadius(4)

                    Spacer()

                    // Win/Loss (bottom-right)
                    HStack(spacing: 2) {
                        Text("\(photo.wins)")
                            .foregroundColor(.green)
                        Text("/")
                            .foregroundColor(.white)
                        Text("\(photo.losses)")
                            .foregroundColor(.red)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .cornerRadius(4)
                }
                .padding(4)
            }
        }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    DemoPhotoCellView(photo: DemoPhotosData.photos[0])
        .frame(width: 180, height: 180)
}
