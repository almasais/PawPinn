import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddReport = false
    @State private var selectedFilter = "Recent"
    @Environment(\.colorScheme) var colorScheme
    
    let filters = ["Recent", "Nearby", "Rewards"]
    
    var rewardReports: [CatReport] {
        viewModel.allReports.filter {
            ($0.rewardAmount ?? 0) > 0
        }
    }
    
    var lostReportsOnly: [CatReport] {
        let lost = viewModel.allReports.filter { $0.reportType == "lost" }
        
        switch selectedFilter {
        case "Recent":
            return lost.sorted { $0.date > $1.date }
            
        case "Nearby":
            if let userLoc = viewModel.userLocation {
                return lost.sorted {
                    ($0.distance(to: userLoc) ?? .greatestFiniteMagnitude) <
                        ($1.distance(to: userLoc) ?? .greatestFiniteMagnitude)
                }
            }
            return lost
            
        default:
            return lost
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            (colorScheme == .dark
             ? Color(.systemBackground)
             : Color(red: 0.97, green: 0.97, blue: 0.97))
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PawPin 🐾")
                            .font(.title).bold()
                        
                        Text("Find lost pets near you")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: ProfileView()) {
                        Circle()
                            .fill(Color.brand.opacity(0.15))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.brand)
                            )
                    }
                }
                .padding()
                
                // MARK: CONTENT
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // =====================
                        // REWARDS
                        // =====================
                        if !rewardReports.isEmpty {
                            
                            Text("Rewarded ")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    
                                    ForEach(rewardReports, id: \.id) { report in
                                        
                                        ZStack(alignment: .bottomTrailing) {
                                            
                                            if let photoURL = report.photoURL,
                                               let url = URL(string: photoURL) {
                                                
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                .frame(width: 150, height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                                
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 150, height: 150)
                                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                            }
                                            
                                            Text("\(Int(report.rewardAmount ?? 0)) SAR")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.brand)
                                                .clipShape(Capsule())
                                                .padding(6)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // =====================
                        // LOST PETS HEADER
                        // =====================
                        
                        Text("Lost Pets 🐶")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        // =====================
                        // FILTERS (UNDER TITLE)
                        // =====================
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(filters, id: \.self) { filter in
                                    Button {
                                        selectedFilter = filter
                                    } label: {
                                        Text(filter)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedFilter == filter
                                                ? Color.brand
                                                : Color.gray.opacity(0.2)
                                            )
                                            .foregroundColor(
                                                selectedFilter == filter ? .white : .primary
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // =====================
                        // PET CARDS (FILTERED)
                        // =====================
                        
                        VStack(spacing: 12) {
                            ForEach(lostReportsOnly, id: \.id) { report in
                                NavigationLink(
                                    destination: ReportCardView(
                                        report: report.toPetReport(
                                            viewerId: AuthManager.shared.currentUserID?.uuidString
                                        )
                                    )
                                ) {
                                    PetCardComponent(report: report)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding(.bottom, 120)
                }
            }
            
            // Floating Button
            Button {
                showAddReport = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.brand)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(.trailing, 15)
            .padding(.bottom, 100)
        }
        .onAppear {
            viewModel.loadReports()
        }
        .sheet(isPresented: $showAddReport) {
            NavigationStack {
                ReportPetView()
            }
        }
        .navigationBarHidden(true)
    }
}
#Preview {
    NavigationStack {
        HomeView()
    }
}
