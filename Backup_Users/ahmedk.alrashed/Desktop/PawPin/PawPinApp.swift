//
//  PawPinApp.swift
//  PawPin
//

import SwiftUI

@main
struct PawPinApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else if authManager.isAuthenticated {
                ContentView()
            } else {
                LandingPageView()
            }
        }
    }
}
