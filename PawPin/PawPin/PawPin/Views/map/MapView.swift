//
//  MapView.swift
//  PawPin
//

import SwiftUI
import MapKit

struct MapViewScreen: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 24.7136,
            longitude: 46.6753
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.08,
            longitudeDelta: 0.08
        )
    )
    @State private var selectedReport: CatReport? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // ── Dynamic Map with Annotations ──
            Map(coordinateRegion: $region, annotationItems: viewModel.allReports.filter { $0.latitude != nil && $0.longitude != nil }) { report in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: report.latitude!, longitude: report.longitude!)) {
                    Button {
                        selectedReport = report
                    } label: {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(report.reportType == "lost" ? Color.red : Color.green)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                                
                                if let photoUrlStr = report.photoURL, let url = URL(string: photoUrlStr) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        default:
                                            Image(systemName: "pawprint.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                            }
                            Image(systemName: "arrowtriangle.down.fill")
                                .foregroundColor(report.reportType == "lost" ? Color.red : Color.green)
                                .font(.system(size: 10))
                                .offset(y: -2.5)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            // ── Header ──
            VStack {
                HStack {
                    Text("Map 🗺️")
                        .font(.headline).bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                // ── Report count card ──
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red).frame(width: 8, height: 8)
                            Text("\(viewModel.lostReports.count) Lost")
                                .font(.subheadline).bold()
                                .foregroundColor(.primary)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("\(viewModel.foundReports.count) Found")
                                .font(.subheadline).bold()
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 6)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            viewModel.loadReports()
        }
        .sheet(item: $selectedReport) { report in
            NavigationStack {
                ReportCardView(report: report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString))
            }
        }
        .navigationBarHidden(true)
    }
}
