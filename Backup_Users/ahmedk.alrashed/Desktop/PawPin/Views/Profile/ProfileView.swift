//
//  ProfileView.swift
//  PawPin
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showAddReport = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header Row
                Section {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.brand.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.brand)
                            )
                        
                        Text("My Profile")
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
                        Divider().frame(height: 40)
                        StatBox(
                            number: "\(viewModel.myReports.count)",
                            label: "Total"
                        )
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Add Report Button Row
                Section {
                    Button {
                        showAddReport = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Report a Pet")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // My Reports Section
                Section(header: Text("My Reports").font(.headline).bold().foregroundColor(.primary).textCase(nil)) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else if viewModel.myReports.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint")
                                .font(.system(size: 40))
                                .foregroundColor(Color.brand.opacity(0.4))
                            Text("No reports yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap Report a Pet to post a lost or found pet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.myReports, id: \.id) { report in
                            NavigationLink(destination: ReportCardView(report: convertToPetReport(report))) {
                                PetCardComponent(report: report)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteReport(id: report.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color(red: 0.97, green: 0.97, blue: 0.97).ignoresSafeArea())
            .refreshable {
                viewModel.loadMyReports()
            }
            .onAppear {
                viewModel.loadMyReports()
            }
            .sheet(isPresented: $showAddReport) {
                NavigationStack {
                    ReportPetView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func convertToPetReport(_ catReport: CatReport) -> PetReport {
        return PetReport(
            id: catReport.id,
            type: catReport.reportType == "lost" ? .lost : .found,
            petName: catReport.ownerName,
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
            ownerID: catReport.userId?.uuidString ?? "",
            viewerID: AuthManager.shared.currentUserID?.uuidString ?? "viewer"
        )
    }
}
