//
//  ImagePreloader.swift
//  ios-app
//
//  Created on 18/08/2025.
//

import SwiftUI
import Combine

class ImagePreloader: ObservableObject {
    static let shared = ImagePreloader()
    
    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    private let queue = DispatchQueue(label: "com.hotlympics.imagepreloader", attributes: .concurrent)
    
    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024
    }
    
    func preloadImages(from imageData: [ImageData]) {
        for data in imageData {
            let _ = loadImage(from: data.imageUrl)
        }
    }
    
    func getCachedImage(for urlString: String) -> UIImage? {
        return cache.object(forKey: NSString(string: urlString))
    }
    
    @discardableResult
    func loadImage(from urlString: String) -> Task<UIImage?, Never> {
        let cacheKey = NSString(string: urlString)
        
        if let cachedImage = cache.object(forKey: cacheKey) {
            return Task { cachedImage }
        }
        
        if let existingTask = loadingTasks[urlString] {
            return existingTask
        }
        
        let task = Task { () -> UIImage? in
            guard let url = URL(string: urlString) else { return nil }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                
                await MainActor.run {
                    self.cache.setObject(image, forKey: cacheKey, cost: data.count)
                    self.loadingTasks.removeValue(forKey: urlString)
                }
                
                return image
            } catch {
                print("Failed to load image from \(urlString): \(error)")
                await MainActor.run {
                    self.loadingTasks.removeValue(forKey: urlString)
                }
                return nil
            }
        }
        
        loadingTasks[urlString] = task
        return task
    }
    
    func clearCache() {
        cache.removeAllObjects()
        for task in loadingTasks.values {
            task.cancel()
        }
        loadingTasks.removeAll()
    }
    
    func removeFromCache(urlString: String) {
        cache.removeObject(forKey: NSString(string: urlString))
        loadingTasks[urlString]?.cancel()
        loadingTasks.removeValue(forKey: urlString)
    }
}