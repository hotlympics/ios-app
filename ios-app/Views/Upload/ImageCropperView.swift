//
//  ImageCropperView.swift
//  ios-app
//
//  Created by Assistant on 23/08/2025.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Bridge

struct ImageCropperView: UIViewRepresentable {
    let image: UIImage
    @Binding var croppedImage: UIImage?
    let cropSize: CGSize
    
    func makeUIView(context: Context) -> ImageCropperUIView {
        let cropperView = ImageCropperUIView()
        // Delay configuration to ensure view is in hierarchy
        DispatchQueue.main.async {
            cropperView.configure(with: image, cropSize: cropSize)
        }
        return cropperView
    }
    
    func updateUIView(_ uiView: ImageCropperUIView, context: Context) {
        // When croppedImage is requested (nil -> needs value)
        if croppedImage == nil {
            croppedImage = uiView.performCrop()
        }
    }
}

// MARK: - Main Cropper View

class ImageCropperUIView: UIView {
    
    // MARK: - Properties
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let overlayView = CropOverlayView()
    
    private var image: UIImage?
    private var cropSize: CGSize = CGSize(width: 400, height: 400)
    private var isInitialSetupComplete = false
    
    // The actual crop frame in view coordinates
    private var cropFrame: CGRect {
        let dimension = min(bounds.width, bounds.height) * 0.8
        let x = (bounds.width - dimension) / 2
        let y = (bounds.height - dimension) / 2
        return CGRect(x: x, y: y, width: dimension, height: dimension)
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .black
        
        setupScrollView()
        setupImageView()
        setupOverlay()
        setupGestures()
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = true // Important: prevent dragging outside bounds
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        addSubview(scrollView)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
    }
    
    private func setupOverlay() {
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)
    }
    
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    // MARK: - Configuration
    
    func configure(with image: UIImage, cropSize: CGSize) {
        self.image = image
        self.cropSize = cropSize
        self.imageView.image = image
        
        // Reset the initial setup flag when configuring with new image
        isInitialSetupComplete = false
        
        // Force immediate layout if we have valid bounds
        if bounds.width > 0 && bounds.height > 0 {
            layoutIfNeeded()
            
            // If layout didn't trigger configuration, do it now
            if !isInitialSetupComplete && cropFrame.width > 0 {
                configureScrollViewForImage(image)
                isInitialSetupComplete = true
            }
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Don't configure if bounds are zero
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // Scroll view fills the entire view so we can see the whole image
        scrollView.frame = bounds
        
        // Update overlay
        overlayView.frame = bounds
        overlayView.cropRect = cropFrame
        
        // Configure scroll view for image only on initial setup
        if let image = image, !isInitialSetupComplete, cropFrame.width > 0 {
            configureScrollViewForImage(image)
            isInitialSetupComplete = true
        }
    }
    
    private func configureScrollViewForImage(_ image: UIImage) {
        // Set image view size to match image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
        
        // Calculate minimum zoom to fill crop area
        let widthScale = cropFrame.width / image.size.width
        let heightScale = cropFrame.height / image.size.height
        let minScale = max(widthScale, heightScale)
        
        // Set zoom scales
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = max(minScale * 3, 1.0)
        
        // Set initial zoom (slightly zoomed in for better cropping)
        scrollView.zoomScale = minScale * 1.1
        
        // Center the image content on the crop area
        centerImageOnCropArea()
        
        print("📸 Configured image: size=\(image.size), minScale=\(minScale), zoom=\(scrollView.zoomScale)")
    }
    
    private func centerImageOnCropArea() {
        // Update content insets to allow scrolling even when image is smaller than scroll view
        updateScrollViewInsets()
        
        // Get the actual scaled content size after zoom
        let scaledWidth = imageView.frame.width
        let scaledHeight = imageView.frame.height
        
        // Calculate the offset to center the image in the crop area
        // We want the center of the image to align with the center of the crop frame
        let cropCenterX = cropFrame.midX
        let cropCenterY = cropFrame.midY
        
        // Calculate ideal offset (can be negative due to insets)
        let idealOffsetX = (scaledWidth / 2) - cropCenterX
        let idealOffsetY = (scaledHeight / 2) - cropCenterY
        
        // Set the content offset - the insets will handle the bounds
        scrollView.contentOffset = CGPoint(x: idealOffsetX, y: idealOffsetY)
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(scrollView.maximumZoomScale, center: location)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(
            width: scrollView.bounds.width / scale,
            height: scrollView.bounds.height / scale
        )
        
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
        
        return CGRect(origin: origin, size: size)
    }
    
    // MARK: - Cropping
    
    func performCrop() -> UIImage? {
        guard let image = image else { return nil }
        
        // Account for content insets when calculating visible rect
        let contentInset = scrollView.contentInset
        let contentOffset = scrollView.contentOffset
        let zoomScale = scrollView.zoomScale
        
        // The actual content offset adjusted for insets
        let adjustedOffsetX = contentOffset.x + contentInset.left
        let adjustedOffsetY = contentOffset.y + contentInset.top
        
        // Calculate what part of the image is visible in the crop frame
        // The crop frame position relative to the image origin
        let cropInImageX = adjustedOffsetX + cropFrame.origin.x
        let cropInImageY = adjustedOffsetY + cropFrame.origin.y
        
        // Convert to original image coordinates
        let cropRect = CGRect(
            x: cropInImageX / zoomScale,
            y: cropInImageY / zoomScale,
            width: cropFrame.width / zoomScale,
            height: cropFrame.height / zoomScale
        )
        
        print("📸 Crop Debug:")
        print("  - Content offset: \(contentOffset)")
        print("  - Content inset: \(contentInset)")
        print("  - Adjusted offset: (\(adjustedOffsetX), \(adjustedOffsetY))")
        print("  - Crop frame: \(cropFrame)")
        print("  - Zoom scale: \(zoomScale)")
        print("  - Final crop rect: \(cropRect)")
        
        // Perform the crop
        return cropImage(image, toRect: cropRect, targetSize: cropSize)
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect, targetSize: CGSize) -> UIImage? {
        // Ensure we have a CGImage
        guard let cgImage = image.cgImage else { return nil }
        
        // Handle image orientation
        let imageSize: CGSize
        let cropRect: CGRect
        
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Image is rotated 90 degrees
            imageSize = CGSize(width: image.size.height, height: image.size.width)
            cropRect = CGRect(
                x: rect.origin.y,
                y: rect.origin.x,
                width: rect.height,
                height: rect.width
            )
        default:
            imageSize = image.size
            cropRect = rect
        }
        
        // Scale crop rect to actual CGImage dimensions
        let scaleX = CGFloat(cgImage.width) / imageSize.width
        let scaleY = CGFloat(cgImage.height) / imageSize.height
        
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * scaleX,
            y: cropRect.origin.y * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )
        
        // Ensure the rect is within bounds
        let boundedRect = scaledCropRect.intersection(
            CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        )
        
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: boundedRect) else { return nil }
        
        // Create UIImage preserving orientation
        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
        
        // Resize to target size
        return resizeImage(croppedImage, to: targetSize)
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCropperUIView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateScrollViewInsets()
    }
    
    private func updateScrollViewInsets() {
        // Calculate insets to allow the image to be scrolled so any part can be in the crop area
        let imageWidth = imageView.frame.width
        let imageHeight = imageView.frame.height
        
        // We need enough inset so the image edges can reach the crop frame edges
        // Top inset: allows bottom of image to reach bottom of crop frame
        let topInset = max(0, cropFrame.maxY - imageHeight)
        // Bottom inset: allows top of image to reach top of crop frame  
        let bottomInset = max(0, bounds.height - cropFrame.minY)
        // Left inset: allows right edge of image to reach right edge of crop frame
        let leftInset = max(0, cropFrame.maxX - imageWidth)
        // Right inset: allows left edge of image to reach left edge of crop frame
        let rightInset = max(0, bounds.width - cropFrame.minX)
        
        scrollView.contentInset = UIEdgeInsets(
            top: topInset,
            left: leftInset,
            bottom: bottomInset,
            right: rightInset
        )
    }
}

// MARK: - Crop Overlay View

class CropOverlayView: UIView {
    var cropRect: CGRect = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw semi-transparent overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.fill(bounds)
        
        // Clear the crop area
        context.setBlendMode(.clear)
        context.fill(cropRect)
        context.setBlendMode(.normal)
        
        // Draw white border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2)
        context.stroke(cropRect)
        
        // Draw grid lines
        drawGrid(in: context)
    }
    
    private func drawGrid(in context: CGContext) {
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        
        let numberOfLines = 3
        
        // Vertical lines
        let columnWidth = cropRect.width / CGFloat(numberOfLines)
        for i in 1..<numberOfLines {
            let x = cropRect.origin.x + columnWidth * CGFloat(i)
            context.move(to: CGPoint(x: x, y: cropRect.minY))
            context.addLine(to: CGPoint(x: x, y: cropRect.maxY))
        }
        
        // Horizontal lines
        let rowHeight = cropRect.height / CGFloat(numberOfLines)
        for i in 1..<numberOfLines {
            let y = cropRect.origin.y + rowHeight * CGFloat(i)
            context.move(to: CGPoint(x: cropRect.minX, y: y))
            context.addLine(to: CGPoint(x: cropRect.maxX, y: y))
        }
        
        context.strokePath()
    }
}