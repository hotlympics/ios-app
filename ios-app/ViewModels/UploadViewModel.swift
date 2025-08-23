//
//  UploadViewModel.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI
import PhotosUI

@MainActor
class UploadViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingCropper = false
    @Published var showingActionSheet = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isLoadingImage = false
    
    private let uploadService = UploadService.shared
    
    var isUploading: Bool {
        uploadService.isUploading
    }
    
    var uploadStatus: String {
        uploadService.uploadStatus
    }
    
    var uploadProgress: Double {
        uploadService.uploadProgress
    }
    
    func showPhotoSourcePicker() {
        showingActionSheet = true
    }
    
    func selectPhotoLibrary() {
        showingImagePicker = true
    }
    
    func selectCamera() {
        checkCameraPermission()
    }
    
    func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoadingImage = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    self.isLoadingImage = false
                    self.selectedItem = nil
                    self.selectedImage = image
                    self.showingCropper = true
                } else {
                    throw NSError(domain: "UploadView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } else {
                throw NSError(domain: "UploadView", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data available"])
            }
        } catch {
            self.isLoadingImage = false
            self.selectedItem = nil
            self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
            self.showingError = true
        }
    }
    
    func handleCameraCapture(_ image: UIImage) {
        showingCamera = false
        selectedImage = image
        showingCropper = true
    }
    
    func handleCameraCancel() {
        showingCamera = false
    }
    
    func handleCropComplete(_ croppedImage: UIImage) async -> Bool {
        showingCropper = false
        
        do {
            try await uploadService.uploadPhoto(croppedImage)
            return true
        } catch {
            print("Upload failed with error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
    
    func handleCropCancel() {
        showingCropper = false
        selectedImage = nil
    }
    
    private func checkCameraPermission() {
        #if !targetEnvironment(simulator)
        showingCamera = true
        #else
        errorMessage = "Camera not available in simulator"
        showingError = true
        #endif
    }
}