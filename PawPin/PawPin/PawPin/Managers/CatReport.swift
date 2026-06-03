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
    let contactInfo: String
    let photoURL: String?
    let features: CatFeatures
    let date: Date
    let userId: UUID?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let locationName: String?
    let rewardAmount: Double?
}

extension CatReport {
    func toPetReport(viewerId: String?) -> PetReport {
        let type: PetReportType = (self.reportType == "lost") ? .lost : .found
        let ownerIDStr = self.userId?.uuidString ?? ""
        let viewerIDStr = viewerId ?? ""
        
        let coord: CLLocationCoordinate2D?
        if let lat = self.latitude, let lon = self.longitude {
            coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coord = nil
        }
        
        let desc = self.description ?? "No description provided."
        let location = self.locationName ?? "Unknown location"
        let gender: PetGender = .unknown
        
        return PetReport(
            id: self.id,
            type: type,
            petName: self.ownerName == "Anonymous" ? nil : self.ownerName,
            photoURL: self.photoURL,
            localImage: nil,
            gender: gender,
            eyeColor: self.features.eyeColor,
            eyeAssetName: nil,
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