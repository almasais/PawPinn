//
//  AddReportViewModel.swift
//  PawPin
//
//  Created by lay on 24/11/1447 AH.
//

import Foundation
import UIKit
import CoreLocation
import Combine

@MainActor
final class AddReportViewModel: ObservableObject {
    @Published var selectedReportType: String = "lost"
    @Published var selectedGender: String = "Male"
    @Published var eyeColor: String = ""
    @Published var catName: String = ""
    @Published var description: String = ""
    @Published var contactInfo: String = ""
    @Published var rewardAmount: String = ""
    @Published var locationName: String = ""

    @Published var selectedPhoto: UIImage? = nil
    @Published var selectedCoordinate: CLLocationCoordinate2D? = nil

    @Published var isSaving = false
    @Published var saveError: String? = nil
    @Published var saveSuccess = false

    func saveReport() {
        guard let photo = selectedPhoto else {
            saveError = "Please select a photo."
            return
        }

        isSaving = true
        saveError = nil

        Task {
            do {
                let features = CatFeatures(
                    breed: "",
                    furColors: [],
                    eyeColor: eyeColor,
                    pattern: "",
                    earType: "",
                    size: ""
                )

                let lat    = selectedCoordinate?.latitude
                let lon    = selectedCoordinate?.longitude
                let reward = Double(rewardAmount)
                let pet    = catName.isEmpty ? nil : catName

                let report = CatReport(
                    id: UUID().uuidString,
                    reportType: selectedReportType,
                    ownerName: AuthManager.shared.currentUserFullName ?? "Anonymous",
                    petName: pet,
                    contactInfo: contactInfo.isEmpty ? "in-app chat" : contactInfo,
                    photoURL: nil,
                    features: features,
                    date: Date(),
                    userId: AuthManager.shared.currentUserID,
                    latitude: lat,
                    longitude: lon,
                    description: description.isEmpty ? nil : description,
                    locationName: locationName.isEmpty ? nil : locationName,
                    rewardAmount: reward
                )

                try await SupabaseManager.shared.saveReportAsync(
                    report: report,
                    photo: photo,
                    latitude: lat,
                    longitude: lon,
                    description: description.isEmpty ? nil : description,
                    rewardAmount: reward,
                    locationName: locationName.isEmpty ? nil : locationName,
                    petName: pet
                )

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
