//
//  PetCardComponent.swift
//  PawPin

import SwiftUI

struct PetCardComponent: View {
    @Environment(\.colorScheme) var colorScheme
    let report: CatReport

    var displayName: String {
        report.reportType == "lost" ? (report.petName ?? "Lost Pet") : "Found Pet"
    }

    var eyeAssetName: String? {
        let raw = report.features.eyeColor.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { return nil }
        switch raw.lowercased() {
        case "amber":                         return "eye_amber"
        case "aquamarine":                    return "eye_aquamarine"
        case "blue / gold", "blue gold":     return "eye_blue_gold"
        case "blue":                          return "eye_blue"
        case "blue-gray", "blue gray":       return "eye_bluegray"
        case "brown":                         return "eye_brown"
        case "copper":                        return "eye_copper"
        case "gray", "grey":                  return "eye_gray"
        case "green / blue", "green blue":   return "eye_green_blue"
        case "green":                         return "eye_green"
        case "hazel":                         return "eye_hazel"
        case "olive":                         return "eye_olive"
        case "turquoise":                     return "eye_turquoise"
        case "yellow-green", "yellow green":  return "eye_yellowgreen"
        default:                              return nil
        }
    }

    var isLost: Bool { report.reportType == "lost" }

    var body: some View {
        HStack(spacing: 0) {

            // ── Photo ──
            ZStack(alignment: .topLeading) {
                Group {
                    if let urlStr = report.photoURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(red: 0.94, green: 0.91, blue: 0.87))
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.brand.opacity(0.25))
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(Color(red: 0.94, green: 0.91, blue: 0.87))
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color.brand.opacity(0.25))
                            )
                    }
                }
                .frame(width: 100, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Lost/Found badge on photo
                Text(isLost ? "Lost" : "Found")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(isLost ? Color(red: 0.92, green: 0.25, blue: 0.25) : Color(red: 0.18, green: 0.72, blue: 0.42))
                    .clipShape(Capsule())
                    .padding(7)
            }

            // ── Info ──
            VStack(alignment: .leading, spacing: 7) {

                Text(displayName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let loc = report.locationName, !loc.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.brand)
                        Text(loc)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if !report.features.eyeColor.isEmpty {
                    HStack(spacing: 5) {
                        if let asset = eyeAssetName {
                            Image(asset)
                                .resizable().scaledToFill()
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 0.5))
                        }
                        Text(report.features.eyeColor)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(report.date, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Reward badge if exists
                if let reward = report.rewardAmount, reward > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.brand)
                        Text("\(Int(reward)) SAR Reward")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.brand)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.brand.opacity(0.10))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
                .padding(.trailing, 14)
        }
        .background(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 10, y: 4)
    }
}
