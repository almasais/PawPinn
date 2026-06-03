//
//  ProfileViewModel.swift
//  PawPin
//
//  Created by Antigravity on 2026-05-26.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var myReports: [CatReport] = []
    @Published var isLoading = false
    @Published var deleteError: String? = nil
    
    var lostCount: Int {
        myReports.filter { $0.reportType == "lost" }.count
    }
    
    var foundCount: Int {
        myReports.filter { $0.reportType == "found" }.count
    }
    
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
