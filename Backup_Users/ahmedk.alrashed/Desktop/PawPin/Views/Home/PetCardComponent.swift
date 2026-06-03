//
//  PetCardComponent.swift
//  PawPin
//

import SwiftUI

struct PetCardComponent: View {
    let report: CatReport
    
    var body: some View {
        HStack(spacing: 12) {
            
            // ── Image ──
            if let urlString = report.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        SkeletonView(cornerRadius: 12)
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
            
            // ── Info ──
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(report.features.breed.isEmpty ? "Unknown Breed" : report.features.breed)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Status Badge
                    Text(report.reportType.capitalized)
                        .font(.caption2).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(report.reportType == "lost" ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .foregroundColor(report.reportType == "lost" ? .red : .green)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(report.features.eyeColor.isEmpty ? "Unknown Eyes" : report.features.eyeColor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(report.ownerName.isEmpty ? "Anonymous" : report.ownerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: report.date))
                        .font(.caption2)
                        .foregroundColor(Color.brand)
                        .bold()
                }
            }
            .padding(.vertical, 4)
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
    
    private var fallbackImage: some View {
        Rectangle()
            .fill(Color(white: 0.95))
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.title)
            )
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
