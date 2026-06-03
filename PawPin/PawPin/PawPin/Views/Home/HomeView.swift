//
//  HomeView.swift
//  PawPin
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddReport = false
    @State private var selectedFilter = "All Reports"
    @Environment(\.colorScheme) var colorScheme
    
    let filters = ["Recent", "Nearby", "Rewards"]
    
    var filteredReports: [CatReport] {
        switch selectedFilter {
        case "Recent":
            return viewModel.allReports.sorted { $0.date > $1.date }
        case "Nearby":
            if let userLoc = viewModel.userLocation {
                return viewModel.allReports.sorted { r1, r2 in
                    let d1 = r1.distance(to: userLoc) ?? Double.greatestFiniteMagnitude
                    let d2 = r2.distance(to: userLoc) ?? Double.greatestFiniteMagnitude
                    return d1 < d2
                }
            } else {
                return viewModel.allReports.sorted { $0.date > $1.date }
            }
        case "Lost":
            return viewModel.lostReports
        case "Found":
            return viewModel.foundReports
        default: // "All Reports"
            return viewModel.allReports
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            (colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.97, green: 0.97, blue: 0.97))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // ── Header ──
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
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // ── Filter chips ──
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter)
                                    .font(.subheadline)
                                    .fontWeight(
                                        selectedFilter == filter ?
                                        .bold : .regular
                                    )
                                    .foregroundColor(
                                        selectedFilter == filter ?
                                        .white : (colorScheme == .dark ? .white : .primary)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ?
                                        Color.brand : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // ── Reports list ──
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading reports...")
                    Spacer()
                    
                } else if filteredReports.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "pawprint")
                            .font(.system(size: 50))
                            .foregroundColor(Color.brand.opacity(0.4))
                        Text("No reports yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Be the first to post!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredReports, id: \.id) { report in
                                NavigationLink(destination: ReportCardView(report: report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString))) {
                                    PetCardComponent(report: report)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 100)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: filteredReports)
                    }
                }
            }
            
            // ── Add report button ──
            Button {
                showAddReport = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.brand)
                    .clipShape(Circle())
                    .shadow(
                        color: Color.brand.opacity(0.4),
                        radius: 8, y: 4
                    )
            }
            .padding(.trailing, 20)
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
#Preview{
    HomeView()
}
