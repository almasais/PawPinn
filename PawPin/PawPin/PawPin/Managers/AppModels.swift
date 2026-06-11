//
//  AppModels.swift
//  PawPin
//
//  Created by Abeer Alshabrami on 6/14/26.
//
import SwiftUI

// MARK: - Shared Enums (used across PetReport, CatReport, ReportAPet)
enum PetReportType { case found, lost }
enum PetGender     { case male, female, unknown }

// MARK: - Brand Color + Adaptive Colors
extension Color {
    static let brand = Color(red: 238/255, green: 182/255, blue: 81/255)
    static var adaptiveBorder: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.15)
                : UIColor(white: 0.88, alpha: 1.0)
        })
    }
    static var adaptivePlaceholder: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.placeholderText
                : UIColor(white: 0.65, alpha: 1.0)
        })
    }
}

// MARK: - Double helper
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
