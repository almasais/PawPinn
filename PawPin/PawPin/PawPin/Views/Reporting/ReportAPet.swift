//
//  ReportAPet.swift
//  PawPin
//
//  Created by Abeer Alshabrami on 5/19/26.
//

import SwiftUI
import PhotosUI
import MapKit
import Combine
import CoreLocation

// MARK: - Eye Options
struct EyeOption: Identifiable {
    let id        = UUID()
    let name:       String
    let assetName:  String
}

let allEyeOptions: [EyeOption] = [
    EyeOption(name: "Green",        assetName: "eye_green"),
    EyeOption(name: "Hazel",        assetName: "eye_hazel"),
    EyeOption(name: "Amber",        assetName: "eye_amber"),
    EyeOption(name: "Copper",       assetName: "eye_copper"),
    EyeOption(name: "Brown",        assetName: "eye_brown"),
    EyeOption(name: "Blue",         assetName: "eye_blue"),
    EyeOption(name: "Turquoise",    assetName: "eye_turquoise"),
    EyeOption(name: "Aquamarine",   assetName: "eye_aquamarine"),
    EyeOption(name: "Gray",         assetName: "eye_gray"),
    EyeOption(name: "Olive",        assetName: "eye_olive"),
    EyeOption(name: "Blue-Gray",    assetName: "eye_bluegray"),
    EyeOption(name: "Yellow-Green", assetName: "eye_yellowgreen"),
    EyeOption(name: "Blue / Gold",  assetName: "eye_blue_gold"),
    EyeOption(name: "Green / Blue", assetName: "eye_green_blue"),
]

// MARK: - Eye Picker Sheet
struct EyePickerSheet: View {
    @Binding var selectedID: UUID?
    @Binding var selectedEyeName: String  // ✅ directly bind the name
    @Environment(\.dismiss) private var dismiss

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allEyeOptions) { eye in
                        Button {
                            selectedID = eye.id
                            selectedEyeName = eye.name  // ✅ set name directly on tap
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Image(eye.assetName)
                                        .resizable().scaledToFill()
                                        .frame(width: 64, height: 64).clipShape(Circle())
                                    if selectedID == eye.id {
                                        Circle().strokeBorder(Color.brand, lineWidth: 3).frame(width: 68, height: 68)
                                        Circle().fill(Color.brand.opacity(0.22)).frame(width: 64, height: 64)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white).shadow(radius: 2)
                                    } else {
                                        Circle().strokeBorder(Color.adaptiveBorder, lineWidth: 1.5).frame(width: 68, height: 68)
                                    }
                                }
                                Text(eye.name)
                                    .font(.system(size: 10, weight: selectedID == eye.id ? .bold : .regular))
                                    .foregroundColor(selectedID == eye.id ? .brand : .secondary)
                                    .multilineTextAlignment(.center).lineLimit(2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Eye Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundColor(.brand)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Location Manager Helper
@MainActor
class ReportLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.lastLocation = locations.last }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {}
}

// MARK: - Map Location Picker
struct MapPin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct MapLocationPicker: View {
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locManager = ReportLocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var pin: MapPin? = nil
    @State private var isResolving  = false
    @State private var addressLabel = ""
    @State private var didCenterOnUser = false

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let pin {
                            Annotation("", coordinate: pin.coordinate) {
                                VStack(spacing: 0) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 36)).foregroundColor(.brand).shadow(radius: 3)
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 10)).foregroundColor(.brand).offset(y: -4)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .mapControls { MapCompass(); MapScaleView(); MapUserLocationButton() }
                    .onTapGesture { screenPoint in
                        if let coord = proxy.convert(screenPoint, from: .local) { movePinTo(coord) }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    Group {
                        if isResolving {
                            Label("Finding address…", systemImage: "location.circle")
                        } else if addressLabel.isEmpty {
                            Label("Tap the map or use your location", systemImage: "hand.tap")
                        } else {
                            Label(addressLabel, systemImage: "mappin")
                        }
                    }
                    .font(.caption).multilineTextAlignment(.center)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16).padding(.top, 8)
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { jumpToUserLocation() } label: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.brand).padding(14)
                                .background(.ultraThinMaterial).clipShape(Circle()).shadow(radius: 4)
                        }
                        .padding(.trailing, 16).padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.brand)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        selectedLocation   = addressLabel
                        selectedCoordinate = pin?.coordinate
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(pin == nil ? .secondary : .brand)
                    .disabled(pin == nil)
                }
            }
            .onAppear {
                locManager.requestLocation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { jumpToUserLocation() }
            }
            .onChange(of: locManager.lastLocation) { _, loc in
                guard !didCenterOnUser, let loc else { return }
                didCenterOnUser = true
                let coord = loc.coordinate
                cameraPosition = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                movePinTo(coord)
            }
        }
    }

    private func jumpToUserLocation() {
        guard let coord = locManager.lastLocation?.coordinate else { return }
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
        movePinTo(coord)
    }
    private func movePinTo(_ coord: CLLocationCoordinate2D) {
        pin = MapPin(coordinate: coord); reverseGeocode(coord)
    }
    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isResolving = true
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { marks, _ in
            isResolving = false
            if let p = marks?.first {
                addressLabel = [p.name, p.locality, p.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
            }
        }
    }
}

struct MiniMapPreview: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.isUserInteractionEnabled = false; m.isScrollEnabled = false; m.isZoomEnabled = false
        return m
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: false)
        map.removeAnnotations(map.annotations)
        let p = MKPointAnnotation(); p.coordinate = coordinate; map.addAnnotation(p)
    }
}

// MARK: - Report Pet View
struct ReportPetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let preselectedImage: UIImage?
    init(preselectedImage: UIImage? = nil) { self.preselectedImage = preselectedImage }

    @StateObject private var viewModel = AddReportViewModel()
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var petImage: Image?                 = nil
    @State private var reportType: PetReportType        = .found
    @State private var gender: PetGender                = .unknown
    @State private var selectedEyeID: UUID?             = nil
    @State private var selectedEyeName: String          = ""  // ✅ local state for eye name
    @State private var showEyePicker                    = false
    @State private var showLocationPicker               = false
    @State private var goToReward                       = false

    var cardBg: Color { colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 0.97, green: 0.95, blue: 0.91) }
    var pageBg: Color { colorScheme == .dark ? Color(.systemBackground)          : Color(red: 0.99, green: 0.98, blue: 0.96) }
    var selectedEye: EyeOption? { allEyeOptions.first { $0.id == selectedEyeID } }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Found / Lost Switcher
                    HStack(spacing: 0) {
                        SegmentButton(label: "Found a Pet", icon: "pawprint", isSelected: reportType == .found) {
                            reportType = .found; viewModel.selectedReportType = "found"
                        }
                        SegmentButton(label: "Lost a Pet", icon: "pawprint.fill", isSelected: reportType == .lost) {
                            reportType = .lost; viewModel.selectedReportType = "lost"
                        }
                    }
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))

                    // Photo Picker
                    SectionLabel("Pet Photo")
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(cardBg).frame(height: 90)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.adaptiveBorder, lineWidth: 1))
                            if let petImage {
                                petImage.resizable().scaledToFill()
                                    .frame(height: 90).clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                HStack(spacing: 14) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(white: 0.90))
                                        .frame(width: 58, height: 58)
                                        .overlay(Image(systemName: "camera").foregroundColor(.secondary))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Add Photo").font(.subheadline).bold().foregroundColor(.primary)
                                        Text("Upload a clear photo of the pet").font(.caption).foregroundColor(.secondary)
                                        Text("1 photo only").font(.caption2).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }.padding(.horizontal, 14)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let ui = UIImage(data: data) {
                                await MainActor.run {
                                    petImage = Image(uiImage: ui)
                                    viewModel.selectedPhoto = ui
                                }
                            }
                        }
                    }

                    // Pet Name
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel("Pet Name")
                        if reportType == .found {
                            HStack {
                                Text("Unknown (Found Pet)").font(.subheadline).foregroundColor(Color.adaptivePlaceholder)
                                Spacer()
                                Image(systemName: "lock.fill").foregroundColor(.secondary).font(.caption)
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(white: 0.94))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                        } else {
                            TextField("e.g. Fluffy", text: $viewModel.catName)
                                .font(.subheadline).padding()
                                .background(cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                        }
                    }

                    // Gender
                    SectionLabel("Gender")
                    HStack(spacing: 12) {
                        GenderButton(label: "Male",   icon: "♂", isSelected: gender == .male) {
                            gender = .male; viewModel.selectedGender = "Male"
                        }
                        GenderButton(label: "Female", icon: "♀", isSelected: gender == .female) {
                            gender = .female; viewModel.selectedGender = "Female"
                        }
                    }

                    // Eye Color
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Eye Color")
                        Button { showEyePicker = true } label: {
                            HStack(spacing: 12) {
                                if let eye = selectedEye {
                                    Image(eye.assetName).resizable().scaledToFill()
                                        .frame(width: 32, height: 32).clipShape(Circle())
                                        .overlay(Circle().strokeBorder(Color.brand, lineWidth: 1.5))
                                    Text(eye.name).font(.subheadline).foregroundColor(.primary)
                                } else {
                                    Image(systemName: "eye").foregroundColor(.secondary)
                                    Text("Select eye color").font(.subheadline).foregroundColor(Color.adaptivePlaceholder)
                                }
                                Spacer()
                                if selectedEye != nil {
                                    Button {
                                        selectedEyeID = nil
                                        selectedEyeName = ""
                                        viewModel.eyeColor = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                            }
                            .padding().background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        // ✅ Pass selectedEyeName binding directly into the sheet
                        .sheet(isPresented: $showEyePicker) {
                            EyePickerSheet(selectedID: $selectedEyeID, selectedEyeName: $selectedEyeName)
                        }
                    }
                    // ✅ Sync selectedEyeName → viewModel.eyeColor whenever it changes
                    .onChange(of: selectedEyeName) { _, name in
                        viewModel.eyeColor = name
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            SectionLabel("Description")
                            Text("(optional)").font(.caption).foregroundColor(.secondary)
                        }
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12).fill(cardBg).frame(height: 115)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                            TextEditor(text: $viewModel.description)
                                .frame(height: 95).padding(.horizontal, 8).padding(.top, 6)
                                .scrollContentBackground(.hidden).background(Color.clear).scrollDisabled(true)
                                .foregroundColor(.primary)
                            if viewModel.description.isEmpty {
                                Text("Any details about the pet (behaviour, marks, where it was last seen...)")
                                    .font(.caption).foregroundColor(Color.adaptivePlaceholder)
                                    .padding(.horizontal, 14).padding(.top, 14).allowsHitTesting(false)
                            }
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("\(viewModel.description.count)/300").font(.caption2).foregroundColor(.secondary).padding(8)
                                }
                            }.frame(height: 115)
                        }
                        .onChange(of: viewModel.description) { _, new in
                            if new.count > 300 { viewModel.description = String(new.prefix(300)) }
                        }
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Last Seen Location")
                        if let coord = viewModel.selectedCoordinate {
                            MiniMapPreview(coordinate: coord)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                        }
                        Button { showLocationPicker = true } label: {
                            HStack {
                                Text(viewModel.locationName.isEmpty ? "Select location" : viewModel.locationName)
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.locationName.isEmpty ? Color.adaptivePlaceholder : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: viewModel.selectedCoordinate == nil ? "map" : "map.fill")
                                    .foregroundColor(viewModel.selectedCoordinate == nil ? .secondary : .brand)
                            }
                            .padding().background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showLocationPicker) {
                            MapLocationPicker(selectedLocation: $viewModel.locationName, selectedCoordinate: $viewModel.selectedCoordinate)
                        }
                    }

                    // Reward banner (Lost only)
                    if reportType == .lost {
                        Button { goToReward = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "gift").foregroundColor(.brand).font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add a Reward (optional)").font(.subheadline).bold().foregroundColor(.primary)
                                    Text("Offering a reward can motivate people to help and increase trust in your report.")
                                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                            .padding().background(cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brand.opacity(0.4), lineWidth: 1))
                        }
                    }

                    // Post Button
                    Button { viewModel.saveReport() } label: {
                        if viewModel.isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Text("Post").font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.top, 4).padding(.bottom, 24)
                    .disabled(viewModel.isSaving)
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("Report a Pet")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Home")
                    }.foregroundColor(.brand)
                }
            }
        }
        .navigationDestination(isPresented: $goToReward) { AddRewardView(viewModel: viewModel) }
        .onChange(of: viewModel.saveSuccess) { _, success in if success { dismiss() } }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.saveError != nil },
            set: { _ in viewModel.saveError = nil }
        )) {
            Button("OK") { viewModel.saveError = nil }
        } message: { Text(viewModel.saveError ?? "") }
        .onAppear {
            if let preselectedImage {
                petImage = Image(uiImage: preselectedImage)
                viewModel.selectedPhoto = preselectedImage
            }
        }
    }
}

// MARK: - Add Reward View
struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: AddReportViewModel

    var cardBg:  Color { colorScheme == .dark ? Color(.secondarySystemBackground)  : Color(red: 0.97, green: 0.95, blue: 0.91) }
    var pageBg:  Color { colorScheme == .dark ? Color(.systemBackground)           : Color(red: 0.99, green: 0.98, blue: 0.96) }
    var boostBg: Color { colorScheme == .dark ? Color(.tertiarySystemBackground)   : Color(red: 1.00, green: 0.97, blue: 0.88) }

    var rewardValue:     Double { Double(viewModel.rewardAmount) ?? 0 }
    var rewardFormatted: String { String(format: "%.0f", rewardValue) }
    var canPay:          Bool   { rewardValue >= 1 }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.brand.opacity(0.15)).frame(width: 46, height: 46)
                            Image(systemName: "gift.fill").foregroundColor(.brand).font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add a Reward").font(.subheadline).bold()
                            Text("Offering a reward can increase finding success and motivate searchers.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding().background(cardBg).clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reward Amount").font(.subheadline).bold()
                        Text("Reserved fully for whoever finds your pet.").font(.caption).foregroundColor(.secondary)

                        HStack(alignment: .center, spacing: 0) {
                            Text("SAR").font(.headline).bold().foregroundColor(.secondary).padding(.horizontal, 14)
                            Divider().frame(height: 28)
                            TextField("0", text: $viewModel.rewardAmount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(canPay ? .primary : Color.adaptivePlaceholder)
                                .padding(.horizontal, 14)
                            Spacer()
                        }
                        .frame(height: 64).background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(canPay ? Color.brand : Color.adaptiveBorder, lineWidth: canPay ? 2 : 1))
                    }

                    if canPay {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundColor(.brand)
                                Text("Reward Promise").font(.subheadline).bold()
                            }
                            Text("Your promised reward of \(rewardFormatted) SAR will be displayed publicly on the listing to help motivate finders. You do not need to make any payment now.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding().background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.brand.opacity(0.35), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill").foregroundColor(Color.brand).font(.subheadline)
                            Text("Highlight Features").font(.subheadline).bold()
                        }
                        VStack(spacing: 8) {
                            BoostFeatureRow(icon: "flame.fill", color: Color(red: 0.95, green: 0.45, blue: 0.15), text: "Your post will be styled with special accents")
                            BoostFeatureRow(icon: "star.fill",  color: Color.brand, text: "Reward badge shown clearly on card and details")
                        }
                    }
                    .padding(16).background(boostBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brand.opacity(0.25), lineWidth: 1))

                    Button { viewModel.saveReport() } label: {
                        if viewModel.isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Text("Post Report").font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.top, 4).padding(.bottom, 24)
                    .disabled(viewModel.isSaving)
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
        }
        .navigationTitle("Add a Reward")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.saveSuccess) { _, success in if success { dismiss() } }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.saveError != nil },
            set: { _ in viewModel.saveError = nil }
        )) {
            Button("OK") { viewModel.saveError = nil }
        } message: { Text(viewModel.saveError ?? "") }
    }
}

// MARK: - UI Sub-components
struct SegmentButton: View {
    let label: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { Image(systemName: icon); Text(label).font(.subheadline).bold() }
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(isSelected ? Color.brand : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct GenderButton: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) { Text(icon).font(.title3); Text(label).font(.subheadline).bold() }
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isSelected ? Color.brand : (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 0.97, green: 0.95, blue: 0.91)))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct BoostFeatureRow: View {
    let icon: String; let color: Color; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).font(.subheadline)
            Text(text).font(.caption).foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.subheadline).bold().foregroundColor(.primary) }
}
