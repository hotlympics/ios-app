//
//  UploadView.swift
//  ios-app
//
//  Created by Assistant on 19/08/2025.
//

import SwiftUI
import PhotosUI

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if viewModel.isUploading {
                        UploadProgressView(
                            status: viewModel.uploadStatus,
                            progress: viewModel.uploadProgress
                        )
                    } else if viewModel.isLoadingImage {
                        LoadingView(message: "Loading image...")
                    } else {
                        PhotoSourcePickerView(
                            onSelectSource: viewModel.showPhotoSourcePicker,
                            showingActionSheet: $viewModel.showingActionSheet,
                            onSelectPhotoLibrary: viewModel.selectPhotoLibrary,
                            onSelectCamera: viewModel.selectCamera
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Upload Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoadingImage || viewModel.isUploading)
                }
            }
            .photosPicker(
                isPresented: $viewModel.showingImagePicker,
                selection: $viewModel.selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: viewModel.selectedItem) { newItem in
                if newItem != nil {
                    Task {
                        await viewModel.loadSelectedPhoto(from: newItem)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingCamera) {
                CameraView(
                    onCapture: viewModel.handleCameraCapture,
                    onCancel: viewModel.handleCameraCancel
                )
            }
            .fullScreenCover(isPresented: $viewModel.showingCropper) {
                if let image = viewModel.selectedImage {
                    ImageCropperViewController(
                        image: image,
                        onComplete: { croppedImage in
                            Task {
                                let success = await viewModel.handleCropComplete(croppedImage)
                                if success {
                                    dismiss()
                                }
                            }
                        },
                        onCancel: viewModel.handleCropCancel
                    )
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    UploadView()
}