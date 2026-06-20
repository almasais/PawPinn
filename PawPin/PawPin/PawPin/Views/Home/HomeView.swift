import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddReport = false
    @State private var selectedFilter = "Recent"
    @Environment(\.colorScheme) var colorScheme

    let filters = ["Recent", "Nearby", "Rewards"]

    var rewardReports: [CatReport] {
        viewModel.allReports.filter { ($0.rewardAmount ?? 0) > 0 }
    }

    var lostReportsOnly: [CatReport] {
        let lost = viewModel.allReports.filter { $0.reportType == "lost" }
        switch selectedFilter {
        case "Recent":  return lost.sorted { $0.date > $1.date }
        case "Nearby":
            if let userLoc = viewModel.userLocation {
                return lost.sorted {
                    ($0.distance(to: userLoc) ?? .greatestFiniteMagnitude) <
                    ($1.distance(to: userLoc) ?? .greatestFiniteMagnitude)
                }
            }
            return lost
        default: return lost
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ──
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PawPin 🐾")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Find & report lost pets")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    NavigationLink(destination: ProfileView()) {
                        ZStack {
                            Circle()
                                .fill(Color.brand.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.brand)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color(.systemGroupedBackground))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {

                        // ── Rewarded Section ──
                        if !rewardReports.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("🎁  Rewarded")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    Spacer()
                                    
                                }
                                .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(rewardReports, id: \.id) { report in
                                            NavigationLink(destination: ReportCardView(
                                                report: report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString)
                                            )) {
                                                RewardCard(report: report)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // ── Lost Pets Section ──
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("🐾  Lost Pets")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Spacer()
                                Text("\(lostReportsOnly.count) reports")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)

                            // Filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(filters, id: \.self) { filter in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedFilter = filter
                                            }
                                        } label: {
                                            Text(filter)
                                                .font(.system(size: 13, weight: selectedFilter == filter ? .semibold : .regular))
                                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    selectedFilter == filter
                                                    ? Color.brand
                                                    : Color(.secondarySystemGroupedBackground)
                                                )
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Cards
                            if viewModel.isLoading {
                                VStack(spacing: 12) {
                                    ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
                                }
                                .padding(.horizontal, 20)
                            } else if lostReportsOnly.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "pawprint.circle.fill")
                                        .font(.system(size: 52))
                                        .foregroundColor(Color.brand.opacity(0.25))
                                    Text("No lost pets reported yet")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Text("Tap + to post a report")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(lostReportsOnly, id: \.id) { report in
                                        NavigationLink(destination: ReportCardView(
                                            report: report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString)
                                        )) {
                                            PetCardComponent(report: report)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                // Pull-to-refresh
                .refreshable { viewModel.loadReports() }
            }

            // ── FAB ──
            Button { showAddReport = true } label: {
                ZStack {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.brand.opacity(0.4), radius: 14, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .onAppear { viewModel.loadReports() }
        .sheet(isPresented: $showAddReport) {
            NavigationStack {
                // Pass a callback so the new report appears instantly
                ReportPetView { newReport in
                    viewModel.optimisticallyInsert(newReport)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Reward Card
struct RewardCard: View {
    let report: CatReport

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let photoURL = report.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color(.systemGray5))
                            .overlay(Image(systemName: "pawprint.fill").font(.largeTitle).foregroundColor(.gray))
                    }
                } else {
                    Rectangle().fill(Color(.systemGray5))
                        .overlay(Image(systemName: "pawprint.fill").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(width: 155, height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            LinearGradient(
                colors: [.black.opacity(0.72), .clear],
                startPoint: .bottom, endPoint: .top
            )
            .frame(width: 155, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 4) {
                Text(report.petName ?? "Lost Pet")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text("\(Int(report.rewardAmount ?? 0)) SAR")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.brand)
                .clipShape(Capsule())
            }
            .frame(width: 155, alignment: .leading)
            .padding(.horizontal, 12).padding(.bottom, 12)
        }
        .frame(width: 155, height: 210)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    @State private var shimmer = false
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(width: 100, height: 13)
                RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(width: 140, height: 11)
                RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(width: 80, height: 11)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(shimmer ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.85).repeatForever(), value: shimmer)
        .onAppear { shimmer = true }
    }
}

#Preview { NavigationStack { HomeView() } }
