//
//  SettingsView.swift
//  PawPin
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.showTabBar) private var showTabBar
    @AppStorage("app_theme") private var appTheme: Theme = .system
    
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    
    @State private var notificationsEnabled = true
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.97))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(Color.brand)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Spacer to balance back button
                    Color.clear
                        .frame(width: 50, height: 10)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                
                Form {
                    Section(header: Text("Account").font(.footnote).bold()) {
                        Button {
                            showEditProfile = true
                        } label: {
                            HStack {
                                Label("Edit Profile", systemImage: "person.circle.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            showChangePassword = true
                        } label: {
                            HStack {
                                Label("Change Password", systemImage: "lock.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    
                    Section(header: Text("Preferences").font(.footnote).bold()) {
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Push Notifications", systemImage: "bell.fill")
                        }
                        .tint(Color.brand)
                        
                        Picker(selection: $appTheme, label: Label("Appearance", systemImage: "paintpalette.fill")) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.brand)
                    }
                    .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    
                    Section(header: Text("Legal & Safety").font(.footnote).bold()) {
                        Button {
                            showPrivacy = true
                        } label: {
                            HStack {
                                Label("Privacy Policy", systemImage: "shield.righthalf.filled")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            showTerms = true
                        } label: {
                            HStack {
                                Label("Terms of Service", systemImage: "doc.text.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    
                    Section {
                        // Log Out Row
                        Button {
                            showLogoutConfirmation = true
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                        
                        // Delete Account Row
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Account Permanently", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showPrivacy) {
            LegalSheetView(title: "Privacy Policy", content: privacyPolicyText)
        }
        .sheet(isPresented: $showTerms) {
            LegalSheetView(title: "Terms of Service", content: termsText)
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out of PawPin?")
        }
        .alert("Delete Account Permanently", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Permanently", role: .destructive) {
                performDeleteAccount()
            }
        } message: {
            Text("WARNING: This will permanently delete your PawPin account, all your pet reports, and associated data. This action CANNOT be undone.")
        }
        .onAppear {
            showTabBar.wrappedValue = false
        }
    }
    
    private func performLogout() {
        isLoading = true
        Task {
            do {
                try await AuthManager.shared.logout()
            } catch {
                print("Failed to log out: \(error)")
            }
            isLoading = false
        }
    }
    
    private func performDeleteAccount() {
        isLoading = true
        Task {
            do {
                try await AuthManager.shared.deleteAccount()
            } catch {
                print("Failed to delete account: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Subviews for Edit & Change password
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var fullName = AuthManager.shared.currentUserFullName ?? ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Update your profile display name.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                CustomTextField(
                    icon: "person.fill",
                    placeholder: "Full Name",
                    text: $fullName,
                    autoCapitalization: .words
                )
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                PrimaryButton(title: "Save Changes", isLoading: isLoading) {
                    saveProfile()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.97))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color.brand)
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !fullName.isEmpty else {
            errorMessage = "Name cannot be empty."
            return
        }
        guard let userId = AuthManager.shared.currentUserID else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Update public table
                try await SupabaseManager.shared.client
                    .from("users")
                    .update(["full_name": fullName])
                    .eq("id", value: userId.uuidString)
                    .execute()
                
                // Update Supabase Auth user metadata
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(data: ["full_name": .string(fullName)])
                )
                
                await MainActor.run {
                    AuthManager.shared.currentUserFullName = fullName
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose a strong password containing at least 6 characters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "New Password",
                    text: $newPassword,
                    isSecure: true
                )
                .padding(.horizontal)
                
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Confirm New Password",
                    text: $confirmPassword,
                    isSecure: true
                )
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                PrimaryButton(title: "Change Password", isLoading: isLoading) {
                    updatePassword()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.97))
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color.brand)
                }
            }
        }
    }
    
    private func updatePassword() {
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(password: newPassword)
                )
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Legal Info View
struct LegalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.body)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.brand)
                }
            }
        }
    }
}

// MARK: - Appearance theme Enum
enum Theme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Local Mock Legal Texts
let privacyPolicyText = """
Privacy Policy for PawPin

Last updated: May 2026

1. Information We Collect
We collect the information you provide when registering, posting reports (including photos, location details, and eye colors), or messaging other users.

2. Location Sharing
PawPin's primary mission is locating lost pets. Exact location coordinates you attach to a report will be shared with other users on the map to help find your pet.

3. Account Deletion
You can delete your account and all associated data at any time from Settings. All your posts, photos, and messages will be permanently removed.
"""

let termsText = """
Terms of Service for PawPin

Last updated: May 2026

1. Acceptance of Terms
By accessing or using PawPin, you agree to comply with and be bound by these Terms.

2. User Content
You are solely responsible for the reports, photos, and messages you submit. You must not submit fraudulent, misleading, or abusive content.

3. Disclaimer of Warranty
PawPin is provided "as is" without warranty of any kind. We do not guarantee the recovery of any lost pet.
"""
