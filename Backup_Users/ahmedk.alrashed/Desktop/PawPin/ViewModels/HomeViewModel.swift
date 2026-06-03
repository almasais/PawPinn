//
//  HomeViewModel.swift
//  PawPin
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allReports: [CatReport] = []
    @Published var lostReports: [CatReport] = []
    @Published var foundReports: [CatReport] = []
    @Published var isLoading = false
    
    func loadReports() {
        Task {
            isLoading = true
            do {
                let reports = try await SupabaseManager.shared.getAllReportsAsync()
                self.allReports = reports.sorted { $0.date > $1.date }
                self.lostReports = self.allReports.filter { $0.reportType == "lost" }
                self.foundReports = self.allReports.filter { $0.reportType == "found" }
            } catch {
                print("Error loading reports: \(error)")
            }
            isLoading = false
        }
    }
}
