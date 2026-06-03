//
//  AddReportViewModel.swift
//  PawPin
//

import Foundation
import UIKit
import CoreLocation

@MainActor
final class AddReportViewModel: ObservableObject {
    @Published var selectedReportType: String = "lost" // "lost" or "found"
    @Published var selectedGender: String = "Male"
    
    @Published var breed: String = ""
    @Published var furColors: String = ""
    @Published var eyeColor: String = ""
    @Published var pattern: String = ""
    @Published var earType: String = ""
    @Published var size: String = ""
    @Published var catName: String = ""
    @Published var description: String = ""
    @Published var contactInfo: String = ""
    @Published var rewardAmount: String = ""
    
    @Published var selectedPhoto: UIImage? = nil
    @Published var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    @Published var isAnalyzing = false
    @Published var isSaving = false
    @Published var saveError: String? = nil
    @Published var saveSuccess = false
    
    private let gemini = GeminiService()
    
    func analyzePhoto() {
        guard let photo = selectedPhoto else { return }
        isAnalyzing = true
        
        Task {
            do {
                if let features = try await gemini.analyzeCatPhotoAsync(photo: photo) {
                    await MainActor.run {
                        self.breed = features.breed
                        self.furColors = features.furColors.joined(separator: ", ")
                        self.eyeColor = features.eyeColor
                        self.pattern = features.pattern
                        self.earType = features.earType
                        self.size = features.size
                        self.isAnalyzing = false
                    }
                } else {
                    await MainActor.run { self.isAnalyzing = false }
                }
            } catch {
                await MainActor.run { self.isAnalyzing = false }
            }
        }
    }
    
    func saveReport() {
        guard let photo = selectedPhoto else {
            saveError = "Please select a photo."
            return
        }
        guard !contactInfo.isEmpty else {
            saveError = "Contact info is required."
            return
        }
        
        isSaving = true
        saveError = nil
        
        Task {
            do {
                let features = CatFeatures(
                    breed: breed,
                    furColors: furColors.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                    eyeColor: eyeColor,
                    pattern: pattern,
                    earType: earType,
                    size: size
                )
                
                let report = CatReport(
                    id: UUID().uuidString,
                    reportType: selectedReportType,
                    ownerName: AuthManager.shared.currentUserFullName ?? "Anonymous",
                    contactInfo: contactInfo,
                    photoURL: nil,
                    features: features,
                    date: Date(),
                    userId: AuthManager.shared.currentUserID
                )
                
                try await SupabaseManager.shared.saveReportAsync(report: report, photo: photo)
                
                await MainActor.run {
                    self.saveSuccess = true
                    self.isSaving = false
                }
            } catch {
                await MainActor.run {
                    self.saveError = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
}
