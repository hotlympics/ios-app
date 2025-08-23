//
//  ImageCropperViewController.swift
//  ios-app
//
//  Created by Assistant on 23/08/2025.
//

import SwiftUI

// MARK: - Cropper Wrapper to hold reference
class CropperWrapper: ObservableObject {
    weak var cropperView: ImageCropperUIView?
    
    func performCrop() -> UIImage? {
        return cropperView?.performCrop()
    }
}

// MARK: - Main Cropper View Controller

struct ImageCropperViewController: View {
    let image: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @StateObject private var cropperWrapper = CropperWrapper()
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Main cropper view
                    ImageCropperViewBridge(
                        image: image,
                        cropperWrapper: cropperWrapper,
                        cropSize: CGSize(width: 400, height: 400)
                    )
                    .edgesIgnoringSafeArea(.horizontal)
                    
                    // Instructions
                    instructionsView
                }
                
                // Processing overlay
                if isProcessing {
                    processingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - View Components
    
    private var instructionsView: some View {
        VStack(spacing: 8) {
            Text("Move and Scale")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Pinch to zoom • Drag to position • Double tap to reset")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            onCancel()
            dismiss()
        }
        .foregroundColor(.white)
        .disabled(isProcessing)
    }
    
    private var doneButton: some View {
        Button("Done") {
            performCrop()
        }
        .foregroundColor(.white)
        .fontWeight(.semibold)
        .disabled(isProcessing)
    }
    
    // MARK: - Actions
    
    private func performCrop() {
        isProcessing = true
        
        // Directly call crop on the wrapper
        if let croppedImage = cropperWrapper.performCrop() {
            onComplete(croppedImage)
            dismiss()
        } else {
            isProcessing = false
        }
    }
}

// MARK: - Bridge to connect wrapper with UIKit view
struct ImageCropperViewBridge: UIViewRepresentable {
    let image: UIImage
    let cropperWrapper: CropperWrapper
    let cropSize: CGSize
    
    func makeUIView(context: Context) -> ImageCropperUIView {
        let cropperView = ImageCropperUIView()
        cropperWrapper.cropperView = cropperView
        
        // Delay configuration to ensure view is in hierarchy
        DispatchQueue.main.async {
            cropperView.configure(with: image, cropSize: cropSize)
        }
        return cropperView
    }
    
    func updateUIView(_ uiView: ImageCropperUIView, context: Context) {
        // No updates needed
    }
}

// MARK: - Helper View for Sheet Presentation

struct ImageCropperHost: View {
    @Binding var isPresented: Bool
    let image: UIImage
    let onComplete: (UIImage) -> Void
    
    var body: some View {
        if isPresented {
            ImageCropperViewController(
                image: image,
                onComplete: { croppedImage in
                    onComplete(croppedImage)
                    isPresented = false
                },
                onCancel: {
                    isPresented = false
                }
            )
        }
    }
}