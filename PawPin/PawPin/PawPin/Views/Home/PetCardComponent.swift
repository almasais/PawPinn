//
//  PetCardComponent.swift
//  PawPin

import SwiftUI

struct PetCardComponent: View {
    @Environment(\.colorScheme) var colorScheme
    
    let report: CatReport
    
    var displayName: String {
        if report.reportType == "lost" {
            return report.petName ?? "Lost Pet"
        } else {
            return "Found Pet"
        }
    }

    // Map eye color name to asset name
    var eyeAssetName: String? {
        let raw = report.features.eyeColor.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { return nil }
        switch raw.lowercased() {
        case "amber":               return "eye_amber"
        case "aquamarine":          return "eye_aquamarine"
        case "blue / gold",
             "blue gold":           return "eye_blue_gold"
        case "blue":                return "eye_blue"
        case "blue-gray",
             "blue gray":           return "eye_bluegray"
        case "brown":               return "eye_brown"
        case "copper":              return "eye_copper"
        case "gray", "grey":        return "eye_gray"
        case "green / blue",
             "green blue":          return "eye_green_blue"
        case "green":               return "eye_green"
        case "hazel":               return "eye_hazel"
        case "olive":               return "eye_olive"
        case "turquoise":           return "eye_turquoise"
        case "yellow-green",
             "yellow green":        return "eye_yellowgreen"
        default:                    return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            // ── Photo ──
            Group {
                if let photoUrlStr = report.photoURL, let url = URL(string: photoUrlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(red: 0.92, green: 0.88, blue: 0.82))
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .foregroundColor(Color.brand.opacity(0.4))
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color(red: 0.92, green: 0.88, blue: 0.82))
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(Color.brand.opacity(0.4))
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // ── Info ──
            VStack(alignment: .leading, spacing: 5) {
                
                // Status badge + pet name
                HStack(spacing: 6) {
                    Text(report.reportType == "lost" ? "Lost" : "Found")
                        .font(.caption2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(report.reportType == "lost" ? Color.red : Color.green)
                        .clipShape(Capsule())
                    
                    Text(displayName)
                        .font(.subheadline).bold()
                        .foregroundColor(.primary)
                }
                
                // Location
                if let locationName = report.locationName, !locationName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.caption2)
                            .foregroundColor(Color.brand)
                        Text(locationName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Eye color — show asset image instead of yellow eye icon
                if !report.features.eyeColor.isEmpty {
                    HStack(spacing: 5) {
                        if let asset = eyeAssetName {
                            Image(asset)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                                .foregroundColor(Color.brand)
                        }
                        Text(report.features.eyeColor.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Date
                Text(report.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
