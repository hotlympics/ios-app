# AGENTS.md

## Build Commands
```bash
# Open project in Xcode
open ios-app.xcodeproj

# Build for iOS Simulator
xcodebuild -project ios-app.xcodeproj -scheme ios-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run all tests
xcodebuild test -project ios-app.xcodeproj -scheme ios-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run single test class
xcodebuild test -project ios-app.xcodeproj -scheme ios-app -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:ios-appTests/ClassName

# Clean build folder
xcodebuild clean -project ios-app.xcodeproj
```

## Code Style Guidelines
- Use 4 spaces for indentation, no spaces on blank lines
- Import Firebase modules only when needed (Firebase, FirebaseAuth, GoogleSignIn)
- Use SwiftUI property wrappers: @StateObject for owned objects, @ObservedObject for passed objects
- Services use singleton pattern with `static let shared = ClassName()`
- Async/await for all network operations, wrap in Task for concurrent execution
- Use `// MARK: -` sections to organize code (Setup, API Methods, Error Handling, etc.)
- Prefer computed properties over functions for simple boolean checks
- Use guard statements for early returns and input validation
- Error handling with do-catch blocks, print errors for debugging
- Use Constants.swift for API URLs and configuration values
- No comments unless documenting complex logic or TODO items