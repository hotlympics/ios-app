//
//  UploadView.swift
//  ios-app
//
//  Created by Assistant on 19/08/2025.
//

import SwiftUI
import PhotosUI

struct UploadView: View {
    @StateObject private var uploadService = UploadService.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoadingImage = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    if uploadService.isUploading {
                        uploadingView
                    } else if isLoadingImage {
                        loadingImageView
                    } else {
                        selectionView
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
                    .disabled(isLoadingImage || uploadService.isUploading)
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingActionSheet) {
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Take Photo") {
                    checkCameraPermission()
                }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItem) { newItem in
                if newItem != nil {
                    Task {
                        await loadSelectedPhoto(from: newItem)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    showingCamera = false
                    Task {
                        await uploadPhoto(image)
                    }
                } onCancel: {
                    showingCamera = false
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var selectionView: some View {
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
            
            Button(action: {
                showingActionSheet = true
            }) {
                Label("Choose Photo", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text(uploadService.uploadStatus)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if uploadService.uploadProgress > 0 {
                VStack(spacing: 8) {
                    ProgressView(value: uploadService.uploadProgress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(uploadService.uploadProgress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 60)
    }
    
    private var loadingImageView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading image...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }
    
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isLoadingImage = true
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.isLoadingImage = false
                        self.selectedItem = nil
                    }
                    // Upload the image directly
                    await uploadPhoto(image)
                } else {
                    throw NSError(domain: "UploadView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } else {
                throw NSError(domain: "UploadView", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data available"])
            }
        } catch {
            await MainActor.run {
                self.isLoadingImage = false
                self.selectedItem = nil
                self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
    
    private func checkCameraPermission() {
        #if !targetEnvironment(simulator)
        showingCamera = true
        #else
        errorMessage = "Camera not available in simulator"
        showingError = true
        #endif
    }
    
    private func uploadPhoto(_ image: UIImage) async {
        do {
            try await uploadService.uploadPhoto(image)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// Camera View for taking photos
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            } else {
                parent.onCancel()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

#Preview {
    UploadView()
}