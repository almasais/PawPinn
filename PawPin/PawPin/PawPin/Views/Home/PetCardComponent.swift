//
//  PetCardComponent.swift
//  PawPin

import SwiftUI

struct PetCardComponent: View {
    @Environment(\.colorScheme) var colorScheme
    
    let report: CatReport
    
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
                
                // Status badge + name
                HStack(spacing: 6) {
                    Text(report.reportType == "lost" ? "Lost" : "Found")
                        .font(.caption2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            report.reportType == "lost" ?
                            Color.red : Color.green
                        )
                        .clipShape(Capsule())
                    
                    Text(report.ownerName)
                        .font(.subheadline).bold()
                        .foregroundColor(.primary)
                }
                
                // Breed
                Text(report.features.breed.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Eye + fur color
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundColor(Color.brand)
                    Text(report.features.eyeColor.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text(
                        report.features.furColors.first?
                            .capitalized ?? ""
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
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
