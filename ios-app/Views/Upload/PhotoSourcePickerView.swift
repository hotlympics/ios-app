//
//  PhotoSourcePickerView.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI

struct PhotoSourcePickerView: View {
    let onSelectSource: () -> Void
    @Binding var showingActionSheet: Bool
    let onSelectPhotoLibrary: () -> Void
    let onSelectCamera: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Upload Your Photo")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select a photo from your library or take a new one")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onSelectSource) {
                Label("Choose Photo", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
            .confirmationDialog("Choose Photo Source", isPresented: $showingActionSheet) {
                Button("Photo Library") {
                    onSelectPhotoLibrary()
                }
                Button("Take Photo") {
                    onSelectCamera()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}