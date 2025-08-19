# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Native iOS application for the Hotlympics face rating platform built with SwiftUI. Users can rate face images, view leaderboards, and manage their profile through a tabbed interface.

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
- **Dependencies**: Firebase Auth, Google Sign-In (via Swift Package Manager)

### Post-Change Verification
After making changes, build the project and fix any warnings or errors. Test on iPhone 16 Pro simulator.

## High-Level Architecture

### App Structure
- **Main Entry**: `ios_appApp.swift` - Configures Firebase, handles URL schemes for Google Sign-In
- **Navigation**: Tab-based UI with three main sections:
  - Rating (flame icon) - Image pair rating interface
  - Leaderboard (trophy icon) - Top-rated images display
  - Profile (person icon) - User authentication and account management

### Services Layer (Singleton Pattern)
- **ImageQueueService**: Manages dual-block image queue system for seamless rating flow
  - Maintains active and buffer blocks (10 images each)
  - Pre-fetches next block while user rates current pairs
  - Gender-based filtering (shows opposite gender to authenticated user)
- **RatingService**: Handles rating submissions to backend API
- **FirebaseAuthService**: Manages Firebase authentication and Google Sign-In
- **AuthService**: Protocol-based abstraction for authentication operations
- **ImagePreloader**: Pre-loads images for smooth transitions

### View Components
- **SwipeCardView**: Core rating interface with swipe gestures and animations
- **CachedAsyncImage**: Custom image loader with caching and placeholder support
- **ImageElement**: Individual image display component with loading states
- **SignInView**: Authentication UI with email/password and Google Sign-In options

### Data Flow
1. App launches → Firebase configured
2. ImageQueueService fetches initial blocks from API
3. User rates pairs → RatingService submits to backend
4. Queue advances → Buffer block becomes active, new buffer fetched
5. Authentication state changes → Queue resets with appropriate gender filter

### API Integration
- **Base URL**: Currently hardcoded to `http://localhost:3000` in service classes
- **Endpoints Used**:
  - `GET /images/block?gender={gender}&count={count}` - Fetch image blocks
  - `POST /ratings` - Submit rating with winnerId/loserId
  - `GET /leaderboards/{gender}` - Fetch leaderboard data
- **Authentication**: Bearer token from Firebase Auth added to requests when available

### Key Patterns
- Singleton services for shared state management
- @StateObject and @ObservedObject for SwiftUI data binding
- Async/await for network operations
- Task-based concurrent fetching for performance
- Protocol-oriented design for service abstractions