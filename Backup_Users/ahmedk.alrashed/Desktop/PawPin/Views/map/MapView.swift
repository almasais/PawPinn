//
//  MapView.swift
//  PawPin
//

import SwiftUI
import MapKit

struct MapViewScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedReport: CatReport?
    @State private var isShowingSheet = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $position) {
                UserAnnotation()
                
                ForEach(viewModel.allReports, id: \.id) { report in
                    // In a full implementation, you would store coordinates in the DB.
                    // For now, we simulate coordinates near Riyadh if missing.
                    let coord = CLLocationCoordinate2D(
                        latitude: 24.7136 + Double.random(in: -0.05...0.05),
                        longitude: 46.6753 + Double.random(in: -0.05...0.05)
                    )
                    
                    Annotation(report.features.breed, coordinate: coord) {
                        ZStack {
                            Circle()
                                .fill(report.reportType == "lost" ? Color.red : Color.green)
                                .frame(width: 32, height: 32)
                                .shadow(radius: 4)
                            
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .onTapGesture {
                            selectedReport = report
                            isShowingSheet = true
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .top)
            
            // Quick reload button
            Button {
                viewModel.loadReports()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding()
                    .background(.thickMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .onAppear {
            viewModel.loadReports()
        }
        .sheet(isPresented: $isShowingSheet) {
            if let report = selectedReport {
                NavigationStack {
                    ReportCardView(report: convertToPetReport(report))
                }
                .presentationDetents([.medium, .large])
            }
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
            ownerID: catReport.ownerName,
            viewerID: AuthManager.shared.currentUserID?.uuidString ?? "viewer"
        )
    }
}
