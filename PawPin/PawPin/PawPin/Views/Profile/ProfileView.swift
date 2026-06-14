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
    @State private var showAddReport = false
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var editedName: String = ""
    @State private var pickedPhotoItem: PhotosPickerItem? = nil
    @State private var pickedUIImage: UIImage? = nil
    @State private var isSavingProfile = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color.brand)
                }
                
                Spacer()
                
                Text("Profile")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        showEditProfile = true
                        editedName = authManager.currentUserFullName ?? ""
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.brand)
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(Color.brand)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)
            
            List {
                // Profile Header Row
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            if let ui = pickedUIImage {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.brand.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color.brand)
                                    )
                            }
                        }
                        
                        Text(authManager.currentUserFullName ?? "My Profile")
                            .font(.title2).bold()
                        
                        Text("PawPin Member")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Stats Row
                Section {
                    HStack(spacing: 0) {
                        StatBox(
                            number: "\(viewModel.lostCount)",
                            label: "Lost"
                        )
                        Divider().frame(height: 40)
                        StatBox(
                            number: "\(viewModel.foundCount)",
                            label: "Found"
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, y: 4)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // User Reports List Header
                Section(header: Text("My Reports").font(.footnote).bold()) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if viewModel.myReports.isEmpty {
                        EmptyStateView(
                            icon: "cat",
                            title: "No Reports",
                            message: "You haven't posted any lost or found reports yet."
                        )
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.myReports) { report in
                            NavigationLink(destination: ReportCardView(report: report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString))) {
                                HStack(spacing: 12) {
                                    if let urlStr = report.photoURL, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color(.systemGray5)
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 60, height: 60)
                                            .overlay(Image(systemName: "cat.fill").foregroundColor(.gray))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(report.features.breed)
                                            .font(.headline)
                                        Text(report.reportType.capitalized)
                                            .font(.subheadline)
                                            .foregroundColor(report.reportType == "lost" ? .red : .green)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteReport(id: report.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowBackground(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
            }
            .listStyle(.plain)
            .background((colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.97)).ignoresSafeArea())
        }
        .refreshable {
            viewModel.loadMyReports()
        }
        .onAppear {
            showTabBar.wrappedValue = false
            viewModel.loadMyReports()
        }
        .onDisappear {
            showTabBar.wrappedValue = true
        }
        .sheet(isPresented: $showAddReport) {
            NavigationStack {
                ReportPetView()
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                Form {
                    Section(header: Text("Profile Photo")) {
                        HStack(spacing: 16) {
                            if let ui = pickedUIImage {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.brand.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(Color.brand))
                            }
                            PhotosPicker(selection: $pickedPhotoItem, matching: .images) {
                                Text("Choose Photo")
                            }
                        }
                    }
                    Section(header: Text("Name")) {
                        TextField("Full name", text: $editedName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                }
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditProfile = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task { await saveProfileEdits() }
                        } label: {
                            if isSavingProfile { ProgressView() } else { Text("Save") }
                        }
                        .disabled(isSavingProfile || editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        guard !name.isEmpty else { return }
        guard let userId = AuthManager.shared.currentUserID else { return }
        
        await MainActor.run { isSavingProfile = true }
        
        do {
            try await SupabaseManager.shared.client
                .from("users")
                .update(["full_name": name])
                .eq("id", value: userId.uuidString)
                .execute()
            
            try await SupabaseManager.shared.client.auth.update(
                user: UserAttributes(data: ["full_name": .string(name)])
            )
            
            await MainActor.run {
                AuthManager.shared.currentUserFullName = name
                showEditProfile = false
                isSavingProfile = false
            }
        } catch {
            print("Failed to update profile: \(error)")
            await MainActor.run { isSavingProfile = false }
        }
    }
}

// ── Stat box component ──
struct StatBox: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title2).bold()
                .foregroundColor(Color.brand)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview {
    ProfileView()
}
