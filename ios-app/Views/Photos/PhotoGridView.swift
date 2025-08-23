//
//  PhotoGridView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct PhotoGridView: View {
    let photos: [UserService.UserPhoto]
    let selectedPhotos: Set<String>
    let onPhotoTap: (String) -> Void
    let onPhotoDelete: (UserService.UserPhoto) -> Void
    let deletingPhotoId: String?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(photos) { photo in
                PhotoCellView(
                    photo: photo,
                    isSelected: selectedPhotos.contains(photo.id),
                    isDeleting: deletingPhotoId == photo.id,
                    onTap: { onPhotoTap(photo.id) },
                    onDelete: { onPhotoDelete(photo) }
                )
            }
        }
        .padding()
    }
}