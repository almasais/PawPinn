//
//  CatReport.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation
import MapKit

struct CatReport: Identifiable, Hashable, Codable {
    let id: String
    let reportType: String
    let ownerName: String
    let petName: String?
    let contactInfo: String
    let photoURL: String?
    let features: CatFeatures
    let date: Date
    let userId: UUID?
    let latitude: Double?
    let longitude: Double?
    let gender: String
    let description: String?
    let locationName: String?
    let rewardAmount: Double?

    // Map Supabase column names → Swift property names
    enum CodingKeys: String, CodingKey {
        case id
        case reportType   = "report_type"
        case ownerName    = "owner_name"
        case petName      = "pet_name"
        case contactInfo  = "contact_info"
        case photoURL     = "photo_url"
        case features
        case date         = "created_at"
        case userId       = "user_id"
        case latitude
        case longitude
        case gender
        case description
        case locationName = "location_name"
        case rewardAmount = "reward_amount"
    }
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

        let rawEyeColor = self.features.eyeColor.trimmingCharacters(in: .whitespaces)
        let eyeAssetName: String?

        if rawEyeColor.isEmpty {
            eyeAssetName = nil
        } else {
            switch rawEyeColor.lowercased() {
            case "amber":                               eyeAssetName = "eye_amber"
            case "aquamarine":                          eyeAssetName = "eye_aquamarine"
            case "blue / gold", "blue gold", "blue/gold": eyeAssetName = "eye_blue_gold"
            case "blue":                                eyeAssetName = "eye_blue"
            case "blue-gray", "blue gray", "blue/gray": eyeAssetName = "eye_bluegray"
            case "brown":                               eyeAssetName = "eye_brown"
            case "copper":                              eyeAssetName = "eye_copper"
            case "gray", "grey":                        eyeAssetName = "eye_gray"
            case "green / blue", "green blue", "green/blue": eyeAssetName = "eye_green_blue"
            case "green":                               eyeAssetName = "eye_green"
            case "hazel":                               eyeAssetName = "eye_hazel"
            case "olive":                               eyeAssetName = "eye_olive"
            case "turquoise":                           eyeAssetName = "eye_turquoise"
            case "yellow-green", "yellow green":        eyeAssetName = "eye_yellowgreen"
            default:                                    eyeAssetName = nil
            }
        }

        let petGender: PetGender
        switch self.gender {
        case "Male":   petGender = .male
        case "Female": petGender = .female
        default:       petGender = .unknown
        }

        let displayEyeColor = rawEyeColor.isEmpty ? nil : rawEyeColor

        return PetReport(
            id: self.id,
            type: type,
            petName: self.petName,
            photoURL: self.photoURL,
            localImage: nil,
            gender: petGender,
            eyeColor: displayEyeColor,
            eyeAssetName: eyeAssetName,
            description: self.description ?? "",
            locationName: self.locationName ?? "",
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
        return userLocation.distance(from: CLLocation(latitude: lat, longitude: lon))
    }
}
