//
//  PawPinApp.swift
//  PawPin
//
//  Created by almasah on 24/11/1447 AH.
//

import SwiftUI

@main
struct PawPinApp: App {
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("app_theme") private var appTheme: Theme = .system
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(appTheme.colorScheme == .dark ? Color.black : Color.white)
                } else if authManager.isAuthenticated {
                    ContentView()
                } else {
                    SplashView()
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
        }
    }
}
