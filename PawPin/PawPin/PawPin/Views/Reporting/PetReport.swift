//
//  PetReport.swift
//  PawPin
//
//  Created by lay on 24/11/1447 AH.
//

import SwiftUI
import MapKit

// MARK: - Report Model
struct PetReport: Identifiable {
    let id:              String
    let type:            PetReportType
    let petName:         String?
    let photoURL:        String?
    let localImage:      UIImage?
    let gender:          PetGender
    let eyeColor:        String?
    let eyeAssetName:    String?
    let description:     String
    let locationName:    String
    let coordinate:      CLLocationCoordinate2D?
    let rewardAmount:    Double?
    let isHighlighted:   Bool
    let highlightExpiry: Date?
    let postedAt:        Date
    let ownerID:         String
    let viewerID:        String
}

// MARK: - Report Card View
struct ReportCardView: View {
    let report: PetReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.showTabBar) private var showTabBar
    @State private var activeChat: ChatPreviewUI? = nil
    @State private var mapRegion: MKCoordinateRegion

    init(report: PetReport) {
        self.report = report
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: report.coordinate ?? CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            span:   MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        ))
    }

    @Environment(\.colorScheme) var colorScheme

    var cardBg:  Color { colorScheme == .dark ? Color(.systemBackground)          : Color(white: 1.0) }
    var pageBg:  Color { colorScheme == .dark ? Color(.secondarySystemBackground) : Color(white: 0.95) }
    var fieldBg: Color { colorScheme == .dark ? Color(.tertiarySystemBackground)  : Color(red: 0.96, green: 0.96, blue: 0.97) }

    var isOwner: Bool { report.viewerID == report.ownerID }

    var genderTitle: String {
        switch report.gender {
        case .female: return "Female"
        case .male:   return "Male"
        default:      return "Unknown"
        }
    }

    // Use text symbols instead of SF Symbols since gender.male/female aren't reliable
    var genderSymbol: String {
        switch report.gender {
        case .female: return "♀"
        case .male:   return "♂"
        default:      return "?"
        }
    }

    var hasEyeColor: Bool {
        guard let color = report.eyeColor else { return false }
        return !color.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func contactOwner() {
        guard let currentUserId = AuthManager.shared.currentUserID else { return }
        guard let ownerUUID = UUID(uuidString: report.ownerID) else { return }
        guard ownerUUID != currentUserId else { return }

        Task {
            do {
                let chatSession = try await ChatManager.shared.getOrCreateChat(
                    otherUserId: ownerUUID,
                    reportId: UUID(uuidString: report.id)
                )
                let preview = ChatPreviewUI(
                    id: chatSession.id,
                    chatSession: chatSession,
                    otherUserId: ownerUUID,
                    username: report.petName ?? "Owner",
                    avatarURL: nil,
                    lastMessage: "Tap to view messages",
                    timeAgo: "Just now",
                    isUnread: false
                )
                await MainActor.run { self.activeChat = preview }
            } catch {
                print("Failed to open chat: \(error)")
            }
        }
    }

    var timeSincePosted: String {
        let diff = Date().timeIntervalSince(report.postedAt)
        if diff < 3600  { return "\(Int(diff / 60)) mins ago" }
        if diff < 86400 { return "\(Int(diff / 3600)) hrs ago" }
        return "\(Int(diff / 86400)) days ago"
    }

    var highlightTimeRemaining: String? {
        guard report.isHighlighted, let expiry = report.highlightExpiry else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        guard remaining > 0 else { return nil }
        let hrs  = Int(remaining / 3600)
        let mins = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        return hrs > 0 ? "\(hrs)h \(mins)m left" : "\(mins)m left"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                ZStack(alignment: .topLeading) {
                    Group {
                        if let photoURLString = report.photoURL, let url = URL(string: photoURLString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:   ProgressView().frame(height: 300)
                                case .success(let image): image.resizable().scaledToFill()
                                case .failure:
                                    Rectangle().fill(Color(red: 0.92, green: 0.88, blue: 0.82))
                                        .overlay(Image(systemName: "pawprint.fill").font(.system(size: 60)).foregroundColor(Color.brand.opacity(0.4)))
                                @unknown default: EmptyView()
                                }
                            }
                        } else {
                            Rectangle().fill(Color(red: 0.92, green: 0.88, blue: 0.82))
                                .overlay(Image(systemName: "pawprint.fill").font(.system(size: 60)).foregroundColor(Color.brand.opacity(0.4)))
                        }
                    }
                    .frame(height: 300).clipped()

                    LinearGradient(colors: [Color.black.opacity(0.35), Color.clear], startPoint: .top, endPoint: .center)
                        .frame(height: 300)

                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.brand).padding(12)
                            .background(cardBg).clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    }
                    .padding(.top, 56).padding(.leading, 16)

                    if let remaining = highlightTimeRemaining {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill").font(.caption2)
                                    Text("Boosted · \(remaining)").font(.caption2).bold()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.brand).clipShape(Capsule())
                                .padding(.top, 60).padding(.trailing, 16)
                            }
                            Spacer()
                        }
                        .frame(height: 300)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let name = report.petName, !name.isEmpty {
                                Text(name).font(.system(size: 32, weight: .bold)).foregroundColor(.primary)
                            } else {
                                Text(report.type == .lost ? "Lost Pet" : "Found Pet")
                                    .font(.system(size: 32, weight: .bold)).foregroundColor(.primary)
                            }
                            HStack(spacing: 4) {
                                Text("Last seen").font(.subheadline).foregroundColor(.secondary)
                                Text(timeSincePosted).font(.subheadline).bold().foregroundColor(Color.brand)
                                Text("ago").font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if let reward = report.rewardAmount, reward > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "pawprint.fill").font(.subheadline).foregroundColor(Color.brand)
                                Text("\(Int(reward))").font(.title3).bold().foregroundColor(Color.brand)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.brand.opacity(0.12)).clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)

                    // Gender + Eye Color tiles
                    HStack(spacing: 12) {

                        // Gender tile — uses text symbol ♂ ♀
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Text(genderSymbol)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.brand)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(genderTitle).font(.subheadline).bold()
                                Text("Gender").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12).background(fieldBg).clipShape(RoundedRectangle(cornerRadius: 14))

                        // Eye color tile
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.95, blue: 0.90))
                                    .frame(width: 44, height: 44)
                                if hasEyeColor, let asset = report.eyeAssetName, !asset.isEmpty {
                                    Image(asset)
                                        .resizable().scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "eye.fill").foregroundColor(Color.brand)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hasEyeColor ? report.eyeColor! : "Not set")
                                    .font(.subheadline).bold()
                                Text("Eye color").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12).background(fieldBg).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20).padding(.bottom, 18)

                    if !report.description.isEmpty && report.description != "No description provided." {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill").foregroundColor(Color.brand).font(.subheadline)
                                Text("Description").font(.headline)
                            }
                            Text(report.description)
                                .font(.subheadline).foregroundColor(.secondary).lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14).background(fieldBg).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 18)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill").foregroundColor(Color.brand).font(.subheadline)
                            Text("Location").font(.headline)
                        }
                        if let coord = report.coordinate {
                            ZStack(alignment: .bottomTrailing) {
                                Map(coordinateRegion: $mapRegion, annotationItems: [MapPinItem(coordinate: coord)]) { item in
                                    MapAnnotation(coordinate: item.coordinate) {
                                        VStack(spacing: 0) {
                                            ZStack {
                                                Circle().fill(Color.brand).frame(width: 54, height: 54)
                                                if let photoStr = report.photoURL, let url = URL(string: photoStr) {
                                                    AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { ProgressView() }
                                                        .frame(width: 46, height: 46).clipShape(Circle())
                                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                                } else {
                                                    Image(systemName: "pawprint.fill").foregroundColor(.white).font(.title3)
                                                }
                                            }
                                            Image(systemName: "arrowtriangle.down.fill")
                                                .foregroundColor(Color.brand).font(.system(size: 12)).offset(y: -2)
                                        }
                                    }
                                }
                                .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16)).allowsHitTesting(true)

                                if !isOwner {
                                    Button { contactOwner() } label: {
                                        Image(systemName: "bubble.left.fill")
                                            .font(.title3).foregroundColor(Color.brand)
                                            .padding(14).background(cardBg).clipShape(Circle())
                                            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                                    }
                                    .padding(12)
                                }
                            }
                            if !report.locationName.isEmpty && report.locationName != "Unknown location" {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin").foregroundColor(Color.brand).font(.caption)
                                    Text(report.locationName).font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.top, 2)
                            }
                        } else {
                            Text("Location not specified")
                                .font(.subheadline).foregroundColor(.secondary)
                                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                .background(fieldBg).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 18)

                    if let reward = report.rewardAmount, reward > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "gift.fill").foregroundColor(Color.brand).font(.subheadline)
                                Text("Reward Offered").font(.headline)
                            }
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(Int(reward)) SAR").font(.system(size: 28, weight: .bold)).foregroundColor(Color.brand)
                                    Text("Offered by the owner if found").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if !isOwner {
                                    Button { contactOwner() } label: {
                                        Text("I found it!").font(.subheadline).bold().foregroundColor(.white)
                                            .padding(.horizontal, 18).padding(.vertical, 10)
                                            .background(Color.brand).clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(16).background(Color.brand.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.25), lineWidth: 1))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 28)
                    }

                    if !isOwner && (report.rewardAmount ?? 0) == 0 {
                        Button { contactOwner() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.fill")
                                Text("Contact Owner").font(.headline)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                            .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 28)
                    }

                    if isOwner {
                        VStack(spacing: 10) {
                            Button {
                                Task {
                                    do {
                                        try await SupabaseManager.shared.markReportAsFoundAsync(reportID: report.id)
                                        dismiss()
                                    } catch { print("Error: \(error)") }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Found").font(.headline)
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                                .background(Color(red: 0.20, green: 0.65, blue: 0.40))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                Task {
                                    do {
                                        try await SupabaseManager.shared.deleteReportAsync(reportID: report.id)
                                        dismiss()
                                    } catch { print("Error: \(error)") }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Delete Post").font(.headline)
                                }
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                .frame(maxWidth: .infinity).padding()
                                .background(Color(red: 0.85, green: 0.25, blue: 0.25).opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 20).padding(.bottom, 36)
                    }
                }
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .offset(y: -28)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(pageBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { showTabBar.wrappedValue = false }
        .onDisappear { if activeChat == nil { showTabBar.wrappedValue = true } }
        .navigationDestination(item: $activeChat) { preview in
            MessageView(chatPreview: preview, shouldRestoreTabBarOnDisappear: false)
        }
    }
}

// MARK: - Sub-components
struct InfoTile: View {
    @Environment(\.colorScheme) var colorScheme
    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String

    var fieldBg: Color {
        colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(iconColor).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold()
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12).background(fieldBg).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
