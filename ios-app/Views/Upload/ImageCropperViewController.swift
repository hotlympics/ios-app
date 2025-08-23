//
//  ImageCropperViewController.swift
//  ios-app
//
//  Created by Assistant on 23/08/2025.
//

import SwiftUI

struct ImageCropperViewController: View {
    let image: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var cropperViewWrapper: CropperViewWrapper?
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Cropper view
                    ImageCropperViewBridge(
                        image: image,
                        cropperWrapper: $cropperViewWrapper,
                        cropSize: CGSize(width: 400, height: 400)
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    // Bottom instruction
                    VStack(spacing: 8) {
                        Text("Move and Scale")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Pinch to zoom • Drag to position")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.8))
                }
                
                if isProcessing {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropAndComplete()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(isProcessing)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func cropAndComplete() {
        isProcessing = true
        
        // Get the cropped image directly from the cropper view
        if let croppedImage = cropperViewWrapper?.cropImage() {
            print("✅ Successfully cropped image: \(croppedImage.size)")
            onComplete(croppedImage)
            dismiss()
        } else {
            print("❌ Failed to crop image - cropperViewWrapper: \(String(describing: cropperViewWrapper))")
            isProcessing = false
            // Show error - cropping failed
        }
    }
}

// Wrapper class to hold reference to the UIKit cropper view
class CropperViewWrapper {
    weak var cropperView: CropperUIView?
    
    func cropImage() -> UIImage? {
        return cropperView?.cropImage()
    }
}

// Bridge view to connect SwiftUI with UIKit cropper
struct ImageCropperViewBridge: UIViewRepresentable {
    let image: UIImage
    @Binding var cropperWrapper: CropperViewWrapper?
    let cropSize: CGSize
    
    func makeUIView(context: Context) -> CropperUIView {
        let cropperView = CropperUIView()
        cropperView.image = image
        cropperView.cropSize = cropSize
        
        // Create wrapper and store reference
        let wrapper = CropperViewWrapper()
        wrapper.cropperView = cropperView
        DispatchQueue.main.async {
            self.cropperWrapper = wrapper
        }
        
        return cropperView
    }
    
    func updateUIView(_ uiView: CropperUIView, context: Context) {
        // No updates needed
    }
}

// Helper view to integrate the cropper
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

// Extension to properly handle cropping
extension ImageCropperViewController {
    struct CropperRepresentable: UIViewControllerRepresentable {
        let image: UIImage
        let onComplete: (UIImage) -> Void
        let onCancel: () -> Void
        
        func makeUIViewController(context: Context) -> CropperHostController {
            let controller = CropperHostController()
            controller.image = image
            controller.onComplete = onComplete
            controller.onCancel = onCancel
            return controller
        }
        
        func updateUIViewController(_ uiViewController: CropperHostController, context: Context) {
            // No updates needed
        }
    }
}

// UIKit host controller for the cropper
class CropperHostController: UIViewController {
    var image: UIImage?
    var onComplete: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?
    
    private var cropperView: CropperUIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Setup navigation
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Setup cropper
        cropperView = CropperUIView()
        cropperView.image = image
        cropperView.cropSize = CGSize(width: 400, height: 400)
        cropperView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cropperView)
        
        NSLayoutConstraint.activate([
            cropperView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropperView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropperView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        if let croppedImage = cropperView.cropImage() {
            onComplete?(croppedImage)
        }
        dismiss(animated: true)
    }
}