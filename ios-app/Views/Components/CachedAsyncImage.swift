//
//  CachedAsyncImage.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    private let preloader = ImagePreloader.shared
    
    init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else if isLoading {
                placeholder()
            } else if loadFailed {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Failed to load")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onChange(of: urlString) {
            loadedImage = nil
            loadFailed = false
            loadImage()
        }
    }
    
    private func loadImage() {
        if let cachedImage = preloader.getCachedImage(for: urlString) {
            self.loadedImage = cachedImage
            return
        }
        
        isLoading = true
        loadFailed = false
        
        Task {
            let image = await preloader.loadImage(from: urlString).value
            
            await MainActor.run {
                self.isLoading = false
                if let image = image {
                    self.loadedImage = image
                } else {
                    self.loadFailed = true
                }
            }
        }
    }
}

extension CachedAsyncImage {
    init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content
    ) where Placeholder == AnyView {
        self.init(
            urlString: urlString,
            content: content,
            placeholder: {
                AnyView(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                )
            }
        )
    }
}