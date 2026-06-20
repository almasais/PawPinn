//
//  ProfileView.swift
//  PawPin
//

import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.showTabBar) private var showTabBar

    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showSettings    = false
    @State private var showEditProfile = false
    @State private var editedName      = ""
    @State private var pickedPhotoItem: PhotosPickerItem? = nil
    @State private var pickedUIImage: UIImage? = nil
    @State private var isSavingProfile = false

    var displayImage: UIImage? { pickedUIImage ?? viewModel.profileImage }

    private var initials: String {
        let parts = (authManager.currentUserFullName ?? "").split(separator: " ")
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((authManager.currentUserFullName ?? "?").prefix(2)).uppercased()
    }

    var body: some View {
        ZStack(alignment: .top) {

            // ── Full page background ──
            Color(.systemGroupedBackground).ignoresSafeArea()

            // ── Brand cover — sits behind everything, fills top including safe area ──
            Color.brand
                .frame(height: 200)
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity, alignment: .top)

            // ── Scrollable content ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Space so content starts below cover
                    Color.clear.frame(height: 140)

                    // ── White profile card ──
                    VStack(spacing: 20) {

                        // Avatar — centered, overlaps cover
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(.systemBackground) : .white)
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.15), radius: 16, y: 6)

                            if let ui = displayImage {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.brand.opacity(0.12))
                                    .frame(width: 92, height: 92)
                                    .overlay(
                                        Text(initials)
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.brand)
                                    )
                            }
                        }
                        .offset(y: -50)
                        .padding(.bottom, -50)

                        // Name + role
                        VStack(spacing: 5) {
                            Text(authManager.currentUserFullName ?? "My Profile")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            Text("PawPin Member")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        // Stats
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("\(viewModel.lostCount)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Lost")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 1, height: 30)

                            VStack(spacing: 4) {
                                Text("\(viewModel.foundCount)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Found")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                        .overlay(
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 0.5),
                            alignment: .top
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        colorScheme == .dark
                            ? Color(.secondarySystemGroupedBackground)
                            : .white
                    )

                    // ── Reports section ──
                    VStack(alignment: .leading, spacing: 14) {

                        HStack {
                            Text("My Reports")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(viewModel.myReports.count) reports")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                        if viewModel.isLoading {
                            VStack(spacing: 10) {
                                ForEach(0..<3, id: \.self) { _ in ProfileSkeletonRow() }
                            }
                            .padding(.horizontal, 16)

                        } else if viewModel.myReports.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(.systemGray4))
                                Text("No reports yet")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Your lost & found reports\nwill appear here")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)

                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.myReports) { report in
                                    NavigationLink(destination: ReportCardView(
                                        report: report.toPetReport(
                                            viewerId: AuthManager.shared.currentUserID?.uuidString
                                        )
                                    )) {
                                        ProfileReportRow(report: report)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            viewModel.deleteReport(id: report.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .refreshable { viewModel.loadMyReports() }

            // ── Nav buttons on top of cover ──
            HStack {
                Button { dismiss() } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                Spacer()
                HStack(spacing: 10) {
                    Button {
                        showEditProfile = true
                        editedName = authManager.currentUserFullName ?? ""
                        pickedUIImage = nil
                    } label: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    Button { showSettings = true } label: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "gearshape")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 54)
        }
        .onAppear {
            showTabBar.wrappedValue = false
            viewModel.loadMyReports()
            viewModel.loadProfilePhoto()
        }
        .onDisappear { showTabBar.wrappedValue = true }
        .fullScreenCover(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                Form {
                    Section(header: Text("Profile Photo")) {
                        HStack(spacing: 16) {
                            if let ui = pickedUIImage ?? viewModel.profileImage {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.brand.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Text(initials)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(Color.brand)
                                    )
                            }
                            PhotosPicker(selection: $pickedPhotoItem, matching: .images) {
                                Text("Change Photo").foregroundColor(Color.brand)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Section(header: Text("Display Name")) {
                        TextField("Full name", text: $editedName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditProfile = false }.foregroundColor(Color.brand)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button { Task { await saveProfileEdits() } } label: {
                            if isSavingProfile { ProgressView() }
                            else { Text("Save").bold().foregroundColor(Color.brand) }
                        }
                        .disabled(isSavingProfile || editedName
                            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: pickedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImg = UIImage(data: data) {
                    await MainActor.run { pickedUIImage = uiImg }
                }
            }
        }
    }

    private func saveProfileEdits() async {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let userId = AuthManager.shared.currentUserID else { return }
        await MainActor.run { isSavingProfile = true }
        do {
            try await SupabaseManager.shared.client
                .from("users").update(["full_name": name])
                .eq("id", value: userId.uuidString).execute()
            try await SupabaseManager.shared.client.auth.update(
                user: UserAttributes(data: ["full_name": .string(name)])
            )
            if let img = pickedUIImage { try await viewModel.uploadProfilePhoto(img) }
            await MainActor.run {
                AuthManager.shared.currentUserFullName = name
                showEditProfile = false
                isSavingProfile = false
                pickedPhotoItem = nil
                pickedUIImage = nil
            }
        } catch {
            print("Failed to update profile: \(error)")
            await MainActor.run { isSavingProfile = false }
        }
    }
}

// MARK: - Skeleton Row
private struct ProfileSkeletonRow: View {
    @State private var shimmer = false
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(width: 140, height: 13)
                RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray6)).frame(width: 90, height: 11)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(shimmer ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: shimmer)
        .onAppear { shimmer = true }
    }
}

// MARK: - Report Row
struct ProfileReportRow: View {
    @Environment(\.colorScheme) var colorScheme
    let report: CatReport

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlStr = report.photoURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                        placeholder: { Color(.systemGray5) }
                } else {
                    Color(.systemGray5)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(Color(.systemGray3))
                        )
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(report.petName ?? (report.reportType == "lost" ? "Lost Pet" : "Found Pet"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(report.reportType.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(report.reportType == "lost" ? .red : .green)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(
                            (report.reportType == "lost" ? Color.red : Color.green).opacity(0.1)
                        )
                        .clipShape(Capsule())

                    Text(report.date, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(colorScheme == .dark
            ? Color(.secondarySystemGroupedBackground)
            : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Stat Box (kept for compatibility)
struct ProfileStatBox: View {
    let number: String
    let label: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(number).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { ProfileView() }
