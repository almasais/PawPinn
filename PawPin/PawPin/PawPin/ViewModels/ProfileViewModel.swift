//
//  ProfileViewModel.swift
//  PawPin
//
//  Created by Antigravity on 2026-05-26.
//

import Foundation
import Combine
import UIKit
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var myReports: [CatReport] = []
    @Published var isLoading = false
    @Published var deleteError: String? = nil
    @Published var profileImageURL: String? = nil
    @Published var profileImage: UIImage? = nil

    var lostCount: Int  { myReports.filter { $0.reportType == "lost"  }.count }
    var foundCount: Int { myReports.filter { $0.reportType == "found" }.count }

    func loadMyReports() {
        guard let currentUserId = AuthManager.shared.currentUserID else { return }
        isLoading = true
        Task {
            do {
                let reports = try await SupabaseManager.shared.getUserReportsAsync(userId: currentUserId)
                self.myReports = reports.sorted { $0.date > $1.date }
            } catch {
                print("Error loading user reports: \(error)")
            }
            isLoading = false
        }
    }

    func loadProfilePhoto() {
        guard let userId = AuthManager.shared.currentUserID else { return }
        Task {
            do {
                // Try to get public URL for user's avatar
                let url = try SupabaseManager.shared.client.storage
                    .from("avatars")
                    .getPublicURL(path: "\(userId.uuidString).jpg")

                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    self.profileImage = img
                    self.profileImageURL = url.absoluteString
                }
            } catch {
                // No avatar yet — that's fine
                print("No profile photo found: \(error)")
            }
        }
    }

    func uploadProfilePhoto(_ image: UIImage) async throws {
        guard let userId = AuthManager.shared.currentUserID else { return }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        // Upload to Supabase storage bucket "avatars"
        try await SupabaseManager.shared.client.storage
            .from("avatars")
            .upload(
                "\(userId.uuidString).jpg",
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let url = try SupabaseManager.shared.client.storage
            .from("avatars")
            .getPublicURL(path: "\(userId.uuidString).jpg")

        // Save URL to users table
        try await SupabaseManager.shared.client
            .from("users")
            .update(["avatar_url": url.absoluteString])
            .eq("id", value: userId.uuidString)
            .execute()

        self.profileImage = image
        self.profileImageURL = url.absoluteString
    }

    func deleteReport(id: String) {
        Task {
            do {
                try await SupabaseManager.shared.deleteReportAsync(reportID: id)
                self.myReports.removeAll { $0.id == id }
            } catch {
                self.deleteError = error.localizedDescription
                print("Error deleting report: \(error)")
            }
        }
    }
}
