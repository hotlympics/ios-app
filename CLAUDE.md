# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native iOS application for the Hotlympics face rating platform built with SwiftUI. Users can rate face images, view leaderboards, upload photos, and manage their profile through a tabbed interface.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open ios-app.xcodeproj

# Build from command line
xcodebuild -project ios-app.xcodeproj -scheme ios-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild test -project ios-app.xcodeproj -scheme ios-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Clean build folder
xcodebuild clean -project ios-app.xcodeproj
```

### Xcode Configuration
- **Target iOS**: 18.5+
- **Swift Version**: 5.0
- **Bundle ID**: hotlympics.ios-app
- **Preferred Simulator**: iPhone 16 Pro
- **Dependencies**: Firebase Auth, Firebase Storage, Google Sign-In (via Swift Package Manager)

### Post-Change Verification
After making changes, build the project and fix any warnings or errors. Test on iPhone 16 Pro simulator.

## High-Level Architecture

### App Structure
- **Main Entry**: `App/ios_appApp.swift` - Configures Firebase, handles URL schemes for Google Sign-In
- **Navigation**: Tab-based UI with five main sections:
  - Rating (flame icon) - Image pair rating interface with swipe gestures
  - Leaderboard (trophy icon) - Top-rated images display with Glicko-2 scores
  - Upload (plus icon) - Photo upload with cropping (requires authentication)
  - My Photos (photo stack icon) - User's uploaded photos and pool management
  - Profile (person icon) - User authentication and account management

### Services Layer (Singleton Pattern)
- **auth/FirebaseAuthService**: Manages Firebase authentication and Google Sign-In
  - Google OAuth flow with GIDSignIn SDK
  - Token management and automatic session restoration
  - Backend profile sync on authentication changes
- **data/ImageQueueService**: Dual-block image queue system for seamless rating flow
  - Maintains active and buffer blocks (10 images each)
  - Pre-fetches next block while user rates current pairs
  - Gender-based filtering (shows opposite gender to authenticated user)
  - Automatic queue reset on authentication changes
- **api/RatingService**: Handles rating submissions to backend API
- **data/ImagePreloader**: Pre-loads images for smooth transitions
  - NSCache-based image caching with 50-image limit
  - Shared across all views for consistent cache access
  - Automatic cache clearing on memory pressure
- **api/UploadService**: Manages photo upload workflow
  - Requests signed upload URL from backend
  - Uploads compressed images to Firebase Storage
  - Tracks upload progress with URLSession delegation
  - Confirms successful upload with backend
- **data/UserService**: Manages user photos and pool selections
  - Smart caching with 5-minute validity period
  - Preloads images when fetching user data
  - Forces refresh after pool updates or photo uploads
  - Handles photo deletion with optimistic UI updates
  - Automatically removes deleted photos from pool

### View Components Structure
- **Rating/**: Core rating interface components
  - SwipeCardView: Swipe gestures, velocity detection, spring animations
  - ImagePairView: Dual image display with tap handlers
  - SwipeIndicatorView: Visual feedback during swipe
  - ImageElementView: Individual image display with loading states
- **Upload/**: Photo upload workflow
  - UploadView: Main upload interface with source selection
  - PhotoSourcePickerView: Camera vs. gallery selection
  - CameraView: UIImagePickerController wrapper
  - UploadProgressView: Real-time upload progress
  - ImageCropperView: Custom 400x400 square cropper with pinch/pan
  - ImageCropperViewController: Crop confirmation interface
- **Photos/**: User photo management
  - MyPhotosView: Grid display with pool selection (max 2 photos)
  - PhotoGridView: Reusable photo grid component
  - PhotoCellView: Individual photo cell with selection state
  - PoolSelectionBarView: Pool management interface
  - EmptyPhotosView: Empty state display
- **Auth/**: Authentication views
  - SignInView: Email/password and Google Sign-In
  - SignInPromptView: Authentication prompt for protected features
- **shared/**: Reusable components
  - CachedAsyncImageView: Custom image loader with caching

### ViewModels
- **MyPhotosViewModel**: Manages photo grid state and pool selections
  - Optimistic UI updates for deletions
  - Pool selection validation (max 2 photos)
  - Success message management
- **UploadViewModel**: Handles upload workflow state
  - Image processing and compression
  - Upload progress tracking
  - Error handling and retry logic

### Data Flow Patterns
1. **Image Rating Flow**:
   - ImageQueueService fetches initial blocks from API
   - User rates pairs → RatingService submits to backend
   - Queue advances → Buffer block becomes active, new buffer fetched
   - Authentication changes → Queue resets with appropriate gender filter

2. **Photo Upload Flow**:
   - User selects/captures photo → ImageCropper opens
   - User crops to 400x400 square → Image compressed
   - UploadService requests signed URL → Uploads to Firebase Storage
   - Backend confirmation → UserService cache refresh
   - Automatic navigation to My Photos tab

3. **Authentication Flow**:
   - Google Sign-In via OAuth → Firebase credential creation
   - Backend sync for user profile → Token storage
   - All services notified of auth state changes
   - Image queue and caches reset appropriately

### API Integration
- **Base URL**: Currently hardcoded to `http://localhost:3000` in Constants.swift
- **Endpoints Used**:
  - `GET /images/block?gender={gender}&count={count}` - Fetch image blocks
  - `POST /ratings` - Submit rating with winnerId/loserId
  - `GET /leaderboards/{gender}` - Fetch leaderboard data
  - `POST /images/request-upload` - Request signed upload URL
  - `POST /images/confirm-upload/{imageId}` - Confirm successful upload
  - `GET /images/user` - Fetch user's uploaded images
  - `GET /user` - Fetch user profile with pool selections
  - `PUT /user/pool` - Update pool image selections
  - `DELETE /images/{imageId}` - Delete user's uploaded photo
- **Authentication**: Bearer token from Firebase Auth added to requests when available

### Key Implementation Patterns
- Singleton services with shared instances for state management
- @StateObject and @ObservedObject for SwiftUI data binding
- @Published properties for reactive UI updates
- Async/await for all network operations
- Task-based concurrent fetching for performance
- Protocol-oriented design for service abstractions
- Optimistic UI updates with rollback on errors
- Multi-tier caching strategy (images, user data, API responses)