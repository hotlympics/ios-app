//
//  EmptyPhotosView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct EmptyPhotosView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No photos uploaded yet")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Upload photos to see them here")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
    }
}