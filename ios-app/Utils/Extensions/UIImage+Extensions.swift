//
//  UIImage+Extensions.swift
//  ios-app
//
//  Created on 23/08/2025.
//

import UIKit

extension UIImage {
    /// Resizes the image to fit within the specified size while maintaining aspect ratio
    func resized(toFit targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
    
    /// Compresses the image to JPEG with specified quality
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return jpegData(compressionQuality: quality)
    }
    
    /// Creates a square crop from the center of the image
    func squareCropped() -> UIImage {
        let originalWidth = size.width
        let originalHeight = size.height
        let cropSize = min(originalWidth, originalHeight)
        
        let cropRect = CGRect(
            x: (originalWidth - cropSize) / 2,
            y: (originalHeight - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )
        
        guard let cgImage = cgImage?.cropping(to: cropRect) else {
            return self
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    /// Fixes image orientation issues
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}