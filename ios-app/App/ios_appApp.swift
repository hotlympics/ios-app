//
//  ios_appApp.swift
//  ios-app
//
//  Created by Jørgen Henriksen on 18/08/2025.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct ios_appApp: App {
    init() {
        FirebaseApp.configure()
        print("Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("Handling URL: \(url)")
                    let handled = GIDSignIn.sharedInstance.handle(url)
                    print("URL handled by GIDSignIn: \(handled)")
                }
        }
    }
}
