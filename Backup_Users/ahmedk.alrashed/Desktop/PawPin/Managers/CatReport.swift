//
//  CatReport.swift
//  PawPin
//
//  Created by AlAnoud Alsaaid on 09/12/1447 AH.
//

import Foundation

struct CatReport {
    let id: String
    let reportType: String    // "lost" or "found"
    let ownerName: String
    let contactInfo: String
    let photoURL: String?
    let features: CatFeatures
    let date: Date
    let userId: UUID?
}