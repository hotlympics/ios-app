//
//  ImageCropperView.swift
//  ios-app
//
//  Created by Assistant on 23/08/2025.
//

import SwiftUI
import UIKit

struct ImageCropperView: UIViewRepresentable {
    let image: UIImage
    @Binding var croppedImage: UIImage?
    let cropSize: CGSize
    
    func makeUIView(context: Context) -> CropperUIView {
        let cropperView = CropperUIView()
        cropperView.image = image
        cropperView.cropSize = cropSize
        cropperView.delegate = context.coordinator
        return cropperView
    }
    
    func updateUIView(_ uiView: CropperUIView, context: Context) {
        // Trigger crop when needed
        if croppedImage == nil {
            croppedImage = uiView.cropImage()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CropperUIViewDelegate {
        let parent: ImageCropperView
        
        init(_ parent: ImageCropperView) {
            self.parent = parent
        }
        
        func cropperDidCrop(_ image: UIImage) {
            parent.croppedImage = image
        }
    }
}

protocol CropperUIViewDelegate: AnyObject {
    func cropperDidCrop(_ image: UIImage)
}

class CropperUIView: UIView {
    weak var delegate: CropperUIViewDelegate?
    
    var image: UIImage? {
        didSet {
            imageView.image = image
            setupImageView()
        }
    }
    
    var cropSize: CGSize = CGSize(width: 400, height: 400)
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let overlayView = CropOverlayView()
    
    private var cropRect: CGRect {
        let size = min(bounds.width, bounds.height) * 0.8
        let x = (bounds.width - size) / 2
        let y = (bounds.height - size) / 2
        return CGRect(x: x, y: y, width: size, height: size)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .black
        
        // Setup scroll view
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = false
        addSubview(scrollView)
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        // Setup overlay
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)
        
        // Setup double tap gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = bounds
        overlayView.frame = bounds
        overlayView.cropRect = cropRect
        
        if imageView.image != nil {
            updateScrollViewSettings()
        }
    }
    
    private func setupImageView() {
        guard let image = image else { return }
        
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
        
        updateScrollViewSettings()
        centerImageView()
    }
    
    private func updateScrollViewSettings() {
        guard let image = image else { return }
        
        let cropSize = cropRect.size
        
        // Calculate zoom scales
        let scaleWidth = cropSize.width / image.size.width
        let scaleHeight = cropSize.height / image.size.height
        let minScale = max(scaleWidth, scaleHeight)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = minScale * 4
        scrollView.zoomScale = minScale * 1.2 // Start slightly zoomed in
        
        updateContentInset()
    }
    
    private func updateContentInset() {
        let cropSize = cropRect.size
        let contentSize = scrollView.contentSize
        
        let horizontalInset = max(0, (scrollView.bounds.width - contentSize.width) / 2)
        let verticalInset = max(0, (scrollView.bounds.height - contentSize.height) / 2)
        
        // Additional insets to keep image centered in crop area
        let cropHorizontalInset = (bounds.width - cropSize.width) / 2
        let cropVerticalInset = (bounds.height - cropSize.height) / 2
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset + cropVerticalInset,
            left: horizontalInset + cropHorizontalInset,
            bottom: verticalInset + cropVerticalInset,
            right: horizontalInset + cropHorizontalInset
        )
    }
    
    private func centerImageView() {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let rect = CGRect(x: location.x, y: location.y, width: 1, height: 1)
            scrollView.zoom(to: rect, animated: true)
        }
    }
    
    func cropImage() -> UIImage? {
        guard let image = image else { 
            print("❌ No image to crop")
            return nil 
        }
        
        print("📸 Starting crop - Image size: \(image.size), Crop rect: \(cropRect)")
        
        // Get the visible rect in scroll view coordinates
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x,
            y: scrollView.contentOffset.y,
            width: cropRect.width,
            height: cropRect.height
        )
        
        print("📸 Visible rect: \(visibleRect), ScrollView zoom: \(scrollView.zoomScale)")
        
        // Convert to image coordinates
        let scale = imageView.frame.width / image.size.width
        let imageRect = CGRect(
            x: visibleRect.origin.x / scale,
            y: visibleRect.origin.y / scale,
            width: visibleRect.width / scale,
            height: visibleRect.height / scale
        )
        
        // Render the cropped portion
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        let croppedImage = renderer.image { context in
            // Draw the image scaled and positioned
            let drawRect = CGRect(
                x: -imageRect.origin.x * (cropSize.width / imageRect.width),
                y: -imageRect.origin.y * (cropSize.height / imageRect.height),
                width: image.size.width * (cropSize.width / imageRect.width),
                height: image.size.height * (cropSize.height / imageRect.height)
            )
            image.draw(in: drawRect)
        }
        
        return croppedImage
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension CropperUIView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateContentInset()
        centerImageView()
    }
}

// Crop Overlay View
class CropOverlayView: UIView {
    var cropRect: CGRect = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw dimmed overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        context.fill(bounds)
        
        // Clear the crop area
        context.setBlendMode(.clear)
        context.fill(cropRect)
        context.setBlendMode(.normal)
        
        // Draw border around crop area
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1)
        context.stroke(cropRect)
        
        // Draw grid lines (3x3)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        
        // Vertical lines
        let thirdWidth = cropRect.width / 3
        for i in 1..<3 {
            let x = cropRect.origin.x + thirdWidth * CGFloat(i)
            context.move(to: CGPoint(x: x, y: cropRect.origin.y))
            context.addLine(to: CGPoint(x: x, y: cropRect.maxY))
        }
        
        // Horizontal lines
        let thirdHeight = cropRect.height / 3
        for i in 1..<3 {
            let y = cropRect.origin.y + thirdHeight * CGFloat(i)
            context.move(to: CGPoint(x: cropRect.origin.x, y: y))
            context.addLine(to: CGPoint(x: cropRect.maxX, y: y))
        }
        
        context.strokePath()
    }
}