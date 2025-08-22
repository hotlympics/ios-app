//
//  ImageCropper.swift
//  ios-app
//
//  Created by Assistant on 19/08/2025.
//

import SwiftUI
import UIKit

struct ImageCropper: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> ImageCropperViewController {
        let controller = ImageCropperViewController()
        controller.image = image
        controller.onCrop = onCrop
        controller.onCancel = onCancel
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ImageCropperViewController, context: Context) {}
}

class ImageCropperViewController: UIViewController, UIScrollViewDelegate {
    var image: UIImage?
    var onCrop: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let cropOverlay = UIView()
    private let cropBoxView = UIView()
    private var cropRect: CGRect = .zero
    private var initialCropSize: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if cropRect == .zero {
            setupCropArea()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup scroll view
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Setup crop overlay (darkened area)
        cropOverlay.isUserInteractionEnabled = false
        cropOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropOverlay)
        
        // Setup crop box view (fixed frame)
        cropBoxView.backgroundColor = .clear
        cropBoxView.layer.borderColor = UIColor.white.cgColor
        cropBoxView.layer.borderWidth = 3  // Thicker border for visibility
        cropBoxView.layer.cornerRadius = 2
        cropBoxView.translatesAutoresizingMaskIntoConstraints = false
        cropBoxView.isUserInteractionEnabled = false  // Disable interaction with crop box
        view.addSubview(cropBoxView)
        
        // Setup navigation bar
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.barStyle = .black
        navBar.isTranslucent = true
        view.addSubview(navBar)
        
        let navItem = UINavigationItem(title: "Crop Image")
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        navItem.leftBarButtonItem = cancelButton
        navItem.rightBarButtonItem = doneButton
        navBar.setItems([navItem], animated: false)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            cropOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            cropOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
    private func setupImage() {
        guard let image = image else { return }
        
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
    }
    
    private func setupCropArea() {
        // Get the actual safe area and view bounds
        let safeAreaInsets = view.safeAreaInsets
        let viewBounds = view.bounds
        
        // Calculate available space (accounting for nav bar and margins)
        let topMargin = safeAreaInsets.top + 44 + 20 // Safe area + nav bar + margin
        let bottomMargin: CGFloat = 40
        let sideMargin: CGFloat = 20
        
        let availableWidth = viewBounds.width - (sideMargin * 2)
        let availableHeight = viewBounds.height - topMargin - bottomMargin
        
        // Calculate crop size (fixed size)
        initialCropSize = min(availableWidth, availableHeight) * 0.85
        
        // PROPERLY CENTER the crop box in the available space
        let centerX = viewBounds.width / 2
        let centerY = topMargin + (availableHeight / 2)
        
        cropRect = CGRect(
            x: centerX - (initialCropSize / 2),
            y: centerY - (initialCropSize / 2),
            width: initialCropSize,
            height: initialCropSize
        )
        
        updateCropBox()
        updateOverlay()
        
        // Dispatch the centering to ensure layout is complete
        DispatchQueue.main.async { [weak self] in
            self?.centerAndZoomImage()
        }
    }
    
    private func updateCropBox() {
        cropBoxView.frame = cropRect
        updateGridLines()
    }
    
    private func updateGridLines() {
        // Remove all grid lines - we don't want them!
        cropBoxView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }
    
    private func updateOverlay() {
        // Clear existing layers
        cropOverlay.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Create darkened overlay with transparent crop area
        let path = UIBezierPath(rect: cropOverlay.bounds)
        let holePath = UIBezierPath(rect: cropRect)
        path.append(holePath)
        path.usesEvenOddFillRule = true
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        
        cropOverlay.layer.addSublayer(shapeLayer)
    }
    
    private func centerAndZoomImage() {
        guard let image = image else { return }
        
        let imageSize = image.size
        let cropSize = cropRect.size
        
        // Calculate scale to fit image in view
        let widthScale = cropSize.width / imageSize.width
        let heightScale = cropSize.height / imageSize.height
        let scale = max(widthScale, heightScale) * 1.2 // Scale up slightly for better initial framing
        
        scrollView.minimumZoomScale = scale * 0.5
        scrollView.maximumZoomScale = scale * 3.0
        scrollView.zoomScale = scale
        
        // Calculate the scaled image size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Calculate insets to position the image correctly relative to the crop box
        let horizontalInset = cropRect.minX
        let verticalInset = cropRect.minY
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: view.bounds.height - cropRect.maxY,
            right: view.bounds.width - cropRect.maxX
        )
        
        // Force layout update before setting content offset
        scrollView.layoutIfNeeded()
        
        // Calculate center offset - the content offset needed to center the scaled image in the crop rect
        // We need to account for the fact that contentOffset is relative to the scrollView's bounds
        // but we want to center relative to the crop rect
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        if scaledImageSize.width > cropRect.width {
            // Image is wider than crop area - center horizontally
            xOffset = (scaledImageSize.width - cropRect.width) / 2
        }
        
        if scaledImageSize.height > cropRect.height {
            // Image is taller than crop area - center vertically
            yOffset = (scaledImageSize.height - cropRect.height) / 2
        }
        
        scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: false)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
    
    @objc private func doneTapped() {
        guard let image = image else { return }
        
        let scale = scrollView.zoomScale
        let scrollOffset = scrollView.contentOffset
        let contentInset = scrollView.contentInset
        
        // Calculate the visible rect in the scroll view's content
        let visibleRect = CGRect(
            x: (scrollOffset.x + cropRect.minX - contentInset.left) / scale,
            y: (scrollOffset.y + cropRect.minY - contentInset.top) / scale,
            width: cropRect.width / scale,
            height: cropRect.height / scale
        )
        
        if let croppedImage = cropImage(image, toRect: visibleRect, outputSize: CGSize(width: 400, height: 400)) {
            onCrop?(croppedImage)
        }
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect, outputSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let scale = image.scale
        let cropRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        
        // Ensure crop rect is within image bounds
        let imageBounds = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let safeCropRect = cropRect.intersection(imageBounds)
        
        guard !safeCropRect.isEmpty,
              let croppedCGImage = cgImage.cropping(to: safeCropRect) else { return nil }
        
        // Resize to output size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        return renderer.image { context in
            UIImage(cgImage: croppedCGImage).draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Update content insets when zooming to keep image properly positioned
        guard let image = image else { return }
        
        let imageViewSize = CGSize(
            width: image.size.width * scrollView.zoomScale,
            height: image.size.height * scrollView.zoomScale
        )
        
        // Calculate how much smaller the image is than the scroll view
        let widthDiff = max(0, scrollView.bounds.width - imageViewSize.width)
        let heightDiff = max(0, scrollView.bounds.height - imageViewSize.height)
        
        // Center the image if it's smaller than the scroll view
        let horizontalInset = widthDiff / 2
        let verticalInset = heightDiff / 2
        
        // Maintain crop rect positioning
        let minHorizontalInset = cropRect.minX
        let minVerticalInset = cropRect.minY
        
        scrollView.contentInset = UIEdgeInsets(
            top: max(verticalInset, minVerticalInset),
            left: max(horizontalInset, minHorizontalInset),
            bottom: max(verticalInset, view.bounds.height - cropRect.maxY),
            right: max(horizontalInset, view.bounds.width - cropRect.maxX)
        )
    }
}