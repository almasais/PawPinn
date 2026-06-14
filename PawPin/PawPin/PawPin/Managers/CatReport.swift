//
//  CatReport.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation
import MapKit

struct CatReport: Identifiable, Hashable {
    let id: String
    let reportType: String    // "lost" or "found"
    let ownerName: String
    let petName: String?      // pet name entered by user (nil for found pets)
    let contactInfo: String
    let photoURL: String?
    let features: CatFeatures
    let date: Date
    let userId: UUID?
    let latitude: Double?
    let gender: String
    let longitude: Double?
    let description: String?
    let locationName: String?
    let rewardAmount: Double?
}

extension CatReport {
    func toPetReport(viewerId: String?) -> PetReport {
        let type: PetReportType = (self.reportType == "lost") ? .lost : .found
        let ownerIDStr  = self.userId?.uuidString ?? ""
        let viewerIDStr = viewerId ?? ""

        let coord: CLLocationCoordinate2D?
        if let lat = self.latitude, let lon = self.longitude {
            coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coord = nil
        }
<<<<<<< HEAD

        let desc     = self.description ?? "No description provided."
        let location = self.locationName ?? "Unknown location"

=======
        let eyeAssetName: String

        switch self.features.eyeColor.lowercased() {
        case "amber":
            eyeAssetName = "eye_amber"

        case "aquamarine":
            eyeAssetName = "eye_aquamarine"

        case "blue gold":
            eyeAssetName = "eye_blue_gold"

        case "blue":
            eyeAssetName = "eye_blue"

        case "blue gray":
            eyeAssetName = "eye_bluegray"

        case "brown":
            eyeAssetName = "eye_brown"

        case "copper":
            eyeAssetName = "eye_copper"

        case "gray":
            eyeAssetName = "eye_gray"

        case "green gold":
            eyeAssetName = "eye_green_gold"

        case "green":
            eyeAssetName = "eye_green"

        case "olive":
            eyeAssetName = "eye_olive"

        case "turquoise":
            eyeAssetName = "eye_turquoise"

        case "yellow green":
            eyeAssetName = "eye_yellowgreen"

        default:
            eyeAssetName = "eye_blue"
        }
        let desc = self.description ?? "No description provided."
        let location = self.locationName ?? "Unknown location"
        let gender: PetGender

        switch self.gender {
        case "Male":
            gender = .male

        case "Female":
            gender = .female

        default:
            gender = .unknown
        }
        
>>>>>>> main
        return PetReport(
            id: self.id,
            type: type,
            petName: self.petName,
            photoURL: self.photoURL,
            localImage: nil,
            gender: .unknown,
            eyeColor: self.features.eyeColor,
            eyeAssetName: eyeAssetName,
            description: desc,
            locationName: location,
            coordinate: coord,
            rewardAmount: self.rewardAmount,
            isHighlighted: false,
            highlightExpiry: nil,
            postedAt: self.date,
            ownerID: ownerIDStr,
            viewerID: viewerIDStr
        )
    }

    func distance(to userLocation: CLLocation) -> Double? {
        guard let lat = latitude, let lon = longitude else { return nil }
        let reportLoc = CLLocation(latitude: lat, longitude: lon)
        return userLocation.distance(from: reportLoc)
    }
}
