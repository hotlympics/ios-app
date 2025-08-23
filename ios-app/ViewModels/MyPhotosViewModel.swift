//
//  MyPhotosViewModel.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import SwiftUI
import Combine

@MainActor
class MyPhotosViewModel: ObservableObject {
    @Published var selectedPhotos = Set<String>()
    @Published var isUpdatingPool = false
    @Published var showSuccessMessage = false
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    @Published var photoToDelete: UserService.UserPhoto?
    @Published var showDeleteConfirmation = false
    @Published var isDeletingPhoto = false
    @Published var successMessageText = ""
    
    private let userService = UserService.shared
    private let authService = FirebaseAuthService.shared
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    var userPhotos: [UserService.UserPhoto] {
        userService.userPhotos
    }
    
    var hasChanges: Bool {
        let currentPoolIds = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
        return selectedPhotos != currentPoolIds
    }
    
    func loadPhotos() async {
        await userService.fetchUserData()
        selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
    }
    
    func refreshPhotos() async {
        isRefreshing = true
        await userService.fetchUserData(forceRefresh: true)
        selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
        isRefreshing = false
    }
    
    func togglePhotoSelection(_ photoId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedPhotos.contains(photoId) {
                selectedPhotos.remove(photoId)
            } else {
                if selectedPhotos.count < 2 {
                    selectedPhotos.insert(photoId)
                } else {
                    errorMessage = "You can only select up to 2 photos for the pool"
                }
            }
        }
    }
    
    func savePoolSelection() {
        isUpdatingPool = true
        errorMessage = nil
        
        Task {
            let success = await userService.updatePoolSelection(imageIds: Array(selectedPhotos))
            
            isUpdatingPool = false
            if success {
                successMessageText = "Pool selections updated successfully!"
                showSuccessMessage = true
                selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
            } else {
                errorMessage = "Failed to update pool selection"
            }
        }
    }
    
    func confirmDeletePhoto(_ photo: UserService.UserPhoto) {
        photoToDelete = photo
        showDeleteConfirmation = true
    }
    
    func deletePhoto() {
        guard let photo = photoToDelete else { return }
        
        isDeletingPhoto = true
        
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        }
        
        Task {
            let success = await userService.deletePhoto(photoId: photo.id)
            
            isDeletingPhoto = false
            photoToDelete = nil
            
            if success {
                successMessageText = "Photo deleted successfully!"
                showSuccessMessage = true
                selectedPhotos = Set(userService.userPhotos.filter { $0.isInPool }.map { $0.id })
            } else {
                errorMessage = "Failed to delete photo. Please try again."
            }
        }
    }
    
    func cancelDelete() {
        photoToDelete = nil
    }
    
    func dismissMessages() {
        if showSuccessMessage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.showSuccessMessage = false
                }
            }
        }
        
        if errorMessage != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.errorMessage = nil
                }
            }
        }
    }
}