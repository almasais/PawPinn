//
//  AIPage.swift
//  PawPin
//

import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Camera Manager
@MainActor
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var isRunning = false
    private let output = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        configure()
    }
    
    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { session.commitConfiguration(); return }
        session.addInput(input)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }
    
    func stop() {
        session.stopRunning()
        isRunning = false
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            photoCompletion?(image)
        } else {
            photoCompletion?(nil)
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoView {
        let v = VideoView()
        v.session = session
        return v
    }
    func updateUIView(_ uiView: VideoView, context: Context) {}
    
    class VideoView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var layer2: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var session: AVCaptureSession? {
            didSet {
                layer2.session = session
                layer2.videoGravity = .resizeAspectFill
            }
        }
    }
}

// MARK: - Camera Screen
struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cam = CameraManager()
    @State private var showResults = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var libraryThumb: UIImage?
    
    @State private var isAnalyzing = false
    @State private var matches: [CatMatch] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(session: cam.session)
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    HStack(alignment: .center, spacing: 0) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 52, height: 52)
                                if let img = libraryThumb {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 52, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            cam.capturePhoto { img in
                                if let img = img {
                                    libraryThumb = img
                                    analyzeImage(img)
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 76, height: 76)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 62, height: 62)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isAnalyzing)
                        
                        Button {
                            // flip camera
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                }
                
                if isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("AI is analyzing features...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showResults) {
                ResultsView(matches: matches, heroImage: libraryThumb)
            }
        }
        .onAppear { cam.start() }
        .onDisappear { cam.stop() }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        libraryThumb = img
                        analyzeImage(img)
                    }
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        Task {
            do {
                let allReports = try await SupabaseManager.shared.getLostReportsAsync()
                let matcher = CatMatcher()
                let foundMatches = try await matcher.findMatchesAsync(photo: image, allReports: allReports)
                
                await MainActor.run {
                    self.matches = foundMatches
                    self.isAnalyzing = false
                    self.showResults = true
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    print("Error analyzing: \(error)")
                }
            }
        }
    }
}

// MARK: - Results Screen
struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let matches: [CatMatch]
    let heroImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                heroImageView
                
                ScrollView {
                    if matches.isEmpty {
                        EmptyStateView(icon: "magnifyingglass", title: "No Matches Found", message: "Try taking another photo.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(matches, id: \.report.id) { match in
                                MatchRow(match: match)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .offset(y: -24)
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    @ViewBuilder
    var heroImageView: some View {
        if let img = heroImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipped()
        } else {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(.systemGray5), Color(.systemGray4)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 380)
                Image(systemName: "cat.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)
        }
    }
}

struct MatchRow: View {
    let match: CatMatch
    
    var body: some View {
        HStack(spacing: 14) {
            if let urlStr = match.report.photoURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)).frame(width: 72, height: 72)
                    Image(systemName: "cat.fill").foregroundColor(Color(.systemGray3))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(match.report.features.breed.isEmpty ? "Unknown" : match.report.features.breed)
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Text("\(match.score)% Match")
                        .font(.caption).bold()
                        .foregroundColor(.green)
                }
                
                Text("Color: \(match.report.features.furColors.joined(separator: ", "))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(match.report.ownerName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(.systemGray5), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}


