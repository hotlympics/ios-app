//
//  PhotoCellView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct PhotoCellView: View {
    let photo: UserService.UserPhoto
    let isSelected: Bool
    let isDeleting: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Photo
                CachedAsyncImageView(urlString: photo.url) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .foregroundColor(Color(UIColor.systemGray5))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
                )
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                        .padding(8)
                }
                
                // Delete button (top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .disabled(isDeleting)
                        .padding(8)
                    }
                    Spacer()
                }
                
                // Rating and Win/Loss overlays (bottom)
                if let stats = photo.stats {
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            // Rating (bottom-left)
                            Text(String(Int(stats.rating)))
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
                                Text(String(stats.wins))
                                    .foregroundColor(.green)
                                Text("/")
                                    .foregroundColor(.white)
                                Text(String(stats.losses))
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

                // Deleting overlay
                if isDeleting {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}