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
                
                // Eye color
                if !report.features.eyeColor.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(Color.brand)
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
