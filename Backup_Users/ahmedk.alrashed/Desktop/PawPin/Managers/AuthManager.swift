//
//  AuthManager.swift
//  PawPin
//

import Foundation
import Supabase
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUserID: UUID? = nil
    @Published var currentUserFullName: String? = nil
    @Published var isLoading: Bool = true
    
    private init() {
        // Start auth listener
        Task {
            await checkSession()
            listenToAuthChanges()
        }
    }
    
    private func checkSession() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            self.isAuthenticated = true
            self.currentUserID = session.user.id
            await fetchUserProfile(userId: session.user.id)
            self.isLoading = false
        } catch {
            self.isAuthenticated = false
            self.currentUserID = nil
            self.isLoading = false
        }
    }
    
    private func listenToAuthChanges() {
        Task {
            for await event in SupabaseManager.shared.client.auth.authStateChanges {
                switch event.event {
                case .signedIn, .tokenRefreshed:
                    if let session = event.session {
                        self.isAuthenticated = true
                        self.currentUserID = session.user.id
                        await fetchUserProfile(userId: session.user.id)
                    }
                case .signedOut, .userDeleted:
                    self.isAuthenticated = false
                    self.currentUserID = nil
                    self.currentUserFullName = nil
                default:
                    break
                }
            }
        }
    }
    
    private func fetchUserProfile(userId: UUID) async {
        do {
            struct UserProfile: Decodable {
                let full_name: String?
            }
            let profile: UserProfile = try await SupabaseManager.shared.client
                .from("users")
                .select("full_name")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            self.currentUserFullName = profile.full_name
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
    }
    
    func logout() async throws {
        try await SupabaseManager.shared.client.auth.signOut()
    }
}
