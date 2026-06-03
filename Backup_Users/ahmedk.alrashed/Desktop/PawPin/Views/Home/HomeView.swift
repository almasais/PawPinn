//
//  HomeView.swift
//  PawPin
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddReport = false
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Lost 🔴", "Found 🟢"]
    
    var filteredReports: [CatReport] {
        switch selectedFilter {
        case "Lost 🔴":  return viewModel.lostReports
        case "Found 🟢": return viewModel.foundReports
        default:         return viewModel.allReports
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(red: 0.97, green: 0.97, blue: 0.97)
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
                                withAnimation {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .bold : .regular)
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.brand : Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // ── Reports list ──
                ScrollView {
                    if viewModel.isLoading {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                PetCardSkeleton()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    } else if filteredReports.isEmpty {
                        EmptyStateView(
                            icon: "pawprint",
                            title: "No reports yet",
                            message: "Be the first to post a lost or found pet!"
                        )
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReports, id: \.id) { report in
                                NavigationLink(destination: ReportCardView(report: convertToPetReport(report))) {
                                    PetCardComponent(report: report)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    viewModel.loadReports()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    .shadow(color: Color.brand.opacity(0.4), radius: 8, y: 4)
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
    
    private func convertToPetReport(_ catReport: CatReport) -> PetReport {
        // Quick helper to map the older CatReport struct to the new PetReport used in ReportCardView
        return PetReport(
            id: catReport.id,
            type: catReport.reportType == "lost" ? .lost : .found,
            petName: catReport.ownerName, // Using ownerName temporarily as pet name if needed
            photoURL: catReport.photoURL,
            localImage: nil,
            gender: .unknown,
            eyeColor: catReport.features.eyeColor,
            eyeAssetName: nil,
            description: "",
            locationName: "Unknown",
            coordinate: nil,
            rewardAmount: nil,
            isHighlighted: false,
            highlightExpiry: nil,
            postedAt: catReport.date,
            ownerID: catReport.ownerName,
            viewerID: AuthManager.shared.currentUserID?.uuidString ?? "viewer"
        )
    }
}
