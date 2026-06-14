//
//  AuthManager.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
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
    
    // Flag to ignore signedIn events during registration to prevent auto-login
    var isRegistering: Bool = false
    
    private func listenToAuthChanges() {
            Task {
                for await event in SupabaseManager.shared.client.auth.authStateChanges {
                    switch event.event {
                    case .signedIn, .tokenRefreshed:
                        if let session = event.session {
                            self.isAuthenticated = true
                            self.currentUserID = session.user.id
                            await fetchUserProfile(userId: session.user.id)
                            
                            // بعد ما يدخل بنجاح، نصفر الفلاق
                            self.isRegistering = false
                        }
                    case .signedOut, .userDeleted:
                        self.isAuthenticated = false
                        self.currentUserID = nil
                        self.currentUserFullName = nil
                        self.isRegistering = false
                    default:
                        break
                    }
                }
            }
        }
    // Temporary storage for full name during registration to prevent race conditions
    var pendingRegisterFullName: String? = nil
    
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
            
            if let dbName = profile.full_name, !dbName.isEmpty {
                self.currentUserFullName = dbName
            } else if let session = try? await SupabaseManager.shared.client.auth.session,
                       let metaName = session.user.userMetadata["full_name"]?.stringValue,
                       !metaName.isEmpty {
                self.currentUserFullName = metaName
                // Sync to public table
                try? await SupabaseManager.shared.client
                    .from("users")
                    .update(["full_name": metaName])
                    .eq("id", value: userId)
                    .execute()
            } else {
                self.currentUserFullName = "User"
            }
        } catch {
            print("Failed to fetch user profile: \(error). Attempting to auto-create profile row.")
            if let session = try? await SupabaseManager.shared.client.auth.session {
                let email = session.user.email ?? ""
                let metaName = session.user.userMetadata["full_name"]?.stringValue
                
                // Use the pending registration name if available, otherwise metadata, then email prefix
                let defaultName = self.pendingRegisterFullName ?? metaName ?? email.components(separatedBy: "@").first ?? "User"
                self.pendingRegisterFullName = nil // Clear it
                
                struct InsertUser: Encodable {
                    let id: UUID
                    let full_name: String
                    let email: String
                }
                
                do {
                    try await SupabaseManager.shared.client
                        .from("users")
                        .upsert(InsertUser(id: userId, full_name: defaultName, email: email))
                        .execute()
                    self.currentUserFullName = defaultName
                } catch {
                    print("Failed to auto-create user profile row: \(error)")
                    self.currentUserFullName = defaultName
                }
            } else {
                self.currentUserFullName = "User"
            }
        }
    }
    
    func logout() async throws {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            print("Supabase signOut error: \(error)")
        }
        self.isAuthenticated = false
        self.currentUserID = nil
        self.currentUserFullName = nil
    }
    
    func deleteAccount() async throws {
        guard let userId = currentUserID else { return }
        
        do {
            // Try calling the secure RPC first
            try await SupabaseManager.shared.client.rpc("delete_user_account").execute()
        } catch {
            print("RPC delete_user_account failed, trying manual table deletion: \(error)")
            // Fallback: delete public user profile & reports manually
            do {
                try await SupabaseManager.shared.client
                    .from("reports")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                
                try await SupabaseManager.shared.client
                    .from("users")
                    .delete()
                    .eq("id", value: userId.uuidString)
                    .execute()
            } catch {
                print("Manual table deletion failed: \(error)")
            }
        }
        
        // Sign out locally and clear session
        try await logout()
    }
}
