//
//  AIPage.swift
//  PawPin
//
//  Created by Afnan hassan on 01/12/1447 AH.
//

import SwiftUI
import AVFoundation
import PhotosUI
import Combine

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
        #if targetEnvironment(simulator)
        self.isRunning = true
        #else
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
        #endif
    }
    
    func stop() {
        #if targetEnvironment(simulator)
        self.isRunning = false
        #else
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
        #endif
    }
    
    private var isBackCamera = true
    
    func flipCamera() {
        #if targetEnvironment(simulator)
        self.isBackCamera.toggle()
        #else
        session.beginConfiguration()
        
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }
        
        let newPosition: AVCaptureDevice.Position = isBackCamera ? .front : .back
        isBackCamera.toggle()
        
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        session.commitConfiguration()
        #endif
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
    @Binding var selectedTab: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.showTabBar) private var showTabBar
    @StateObject private var cam = CameraManager()
    @State private var showResults = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var libraryThumb: UIImage?
    
    @State private var isAnalyzing = false
    @State private var matches: [CatMatch] = []
    @State private var scanOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(session: cam.session)
                    .ignoresSafeArea()
                
                #if targetEnvironment(simulator)
                VStack(spacing: 16) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 40))
                        .foregroundColor(Color.brand)
                        .padding()
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                    
                    Text("Simulator Live Feed")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Select a photo from your photo library to run the AI cat matcher.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.stack.fill")
                            Text("Choose Cat Photo")
                        }
                        .font(.subheadline).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.brand)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, y: 3)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.55))
                .cornerRadius(24)
                .padding(.horizontal, 32)
                .offset(y: -40)
                #endif
                
                VStack {
                    HStack {
                        Button {
                            dismiss()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = "Home"
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.45))
                                        .background(BlurView(style: .systemUltraThinMaterialDark).clipShape(Circle()))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        .contentShape(Circle())
                        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
                        .padding(.top, (geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top : 20) + 24)
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 0) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.45))
                                        .frame(width: 54, height: 54)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                        .background(BlurView(style: .systemUltraThinMaterialDark).clipShape(Circle()))
                                    
                                    if let img = libraryThumb {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 46, height: 46)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                }
                                Text("Library")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2)
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
                                    .stroke(Color.white, lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.2), radius: 4)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 62, height: 62)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isAnalyzing)
                        
                        Button {
                            cam.flipCamera()
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.45))
                                        .frame(width: 54, height: 54)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                        .background(BlurView(style: .systemUltraThinMaterialDark).clipShape(Circle()))
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                Text("Flip")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                }
                
                if isAnalyzing, let img = libraryThumb {
                    ZStack {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .blur(radius: 25)
                            .ignoresSafeArea()
                        
                        Color.black.opacity(0.45).ignoresSafeArea()
                        
                        VStack(spacing: 32) {
                            ZStack(alignment: .top) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 220, height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
                                
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.brand.opacity(0.0), Color.brand, Color.brand.opacity(0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 5)
                                        .shadow(color: Color.brand, radius: 6, x: 0, y: 0)
                                        .offset(y: scanOffset)
                                        .onAppear {
                                            scanOffset = 0
                                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                                scanOffset = geo.size.height - 5
                                            }
                                        }
                                }
                                .frame(width: 220, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                            }
                            
                            VStack(spacing: 8) {
                                Text("PawPin AI Engine")
                                    .font(.system(.title3, design: .rounded)).bold()
                                    .foregroundColor(.white)
                                
                                Text("Analyzing features & looking for matches...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                            }
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.brand))
                                .scaleEffect(1.3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .navigationDestination(isPresented: $showResults) {
                ResultsView(matches: matches, heroImage: libraryThumb)
            }
            .onAppear {
                showTabBar.wrappedValue = false
                cam.start()
            }
            .onDisappear {
                showTabBar.wrappedValue = true
                cam.stop()
            }
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
        .ignoresSafeArea()
    }
    
    private func analyzeImage(_ image: UIImage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnalyzing = true
        }
        Task {
            do {
                let allReports = try await SupabaseManager.shared.getLostReportsAsync()
                
                let foundMatches = try await Task.detached(priority: .userInitiated) {
                    let matcher = CatMatcher()
                    return try await matcher.findMatchesAsync(photo: image, allReports: allReports)
                }.value
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.matches = foundMatches
                        self.isAnalyzing = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.showResults = true
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isAnalyzing = false
                    }
                    print("Error analyzing: \(error)")
                }
            }
        }
    }
}

// MARK: - Results Screen
struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.showTabBar) private var showTabBar
    
    let matches: [CatMatch]
    let heroImage: UIImage?
    
    @State private var currentMatches: [CatMatch] = []
    @State private var currentHeroImage: UIImage? = nil
    @State private var isReanalyzing = false
    @State private var selectedPhotoInResults: PhotosPickerItem? = nil
    @State private var showAddReport = false
    @State private var showNoMatches = false  // ← جديد
    
    init(matches: [CatMatch], heroImage: UIImage?) {
        self.matches = matches
        self.heroImage = heroImage
        _currentMatches = State(initialValue: matches)
        _currentHeroImage = State(initialValue: heroImage)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    heroImageView
                    
                    ScrollView {
                        if isReanalyzing {
                            VStack(spacing: 20) {
                                ProgressView("Analyzing features...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.brand))
                                    .scaleEffect(1.2)
                                    .padding(.top, 40)
                            }
                            .frame(maxWidth: .infinity)
                        } else if currentMatches.isEmpty {
                            // لا شي هنا — الشاشة الكاملة تطلع تلقائي
                            Color.clear
                                .onAppear {
                                    showNoMatches = true
                                }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(currentMatches, id: \.report.id) { match in
                                    NavigationLink(destination: ReportCardView(report: match.report.toPetReport(viewerId: AuthManager.shared.currentUserID?.uuidString))) {
                                        MatchRow(match: match)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
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
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 4)
            }
            .padding(.leading, 16)
            .padding(.top, 56)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            showTabBar.wrappedValue = false
        }
        .onChange(of: selectedPhotoInResults) { _, item in
            guard let item = item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        currentHeroImage = img
                        isReanalyzing = true
                    }
                    do {
                        let allReports = try await SupabaseManager.shared.getLostReportsAsync()
                        let foundMatches = try await Task.detached(priority: .userInitiated) {
                            let matcher = CatMatcher()
                            return try await matcher.findMatchesAsync(photo: img, allReports: allReports)
                        }.value
                        await MainActor.run {
                            self.currentMatches = foundMatches
                            self.isReanalyzing = false
                        }
                    } catch {
                        await MainActor.run {
                            self.isReanalyzing = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showNoMatches) {
            NoMatchesFullScreenView(
                onDismissToCamera: { dismiss() },
                onUploadAnother: {
                    showNoMatches = false
                },
                onAddReport: {
                    showNoMatches = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddReport = true
                    }
                }
            )
        }
        .sheet(isPresented: $showAddReport) {
            NavigationStack {
                ReportPetView(preselectedImage: currentHeroImage)
            }
        }
    }
    
    @ViewBuilder
    var heroImageView: some View {
        if let img = currentHeroImage {
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

// MARK: - No Matches Screen (Updated to Match the New UI البصري الجديد)
struct NoMatchesFullScreenView: View {
    let onDismissToCamera: () -> Void
    let onUploadAnother: () -> Void
    let onAddReport: () -> Void

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showPrimaryBtn = false
    @State private var showOR = false
    @State private var showSecBtn1 = false
    @State private var showSecBtn2 = false

    // تحديد درجات الألوان المتطابقة مع الصور الجديدة لتناسق الـ Brand
    private let customGold = Color(red: 242/255, green: 181/255, blue: 89/255) // لون Found a Pet الذهبي
    private let customLightBeige = Color(red: 253/255, green: 248/255, blue: 242/255) // الخلفية الفاتحة للأزرار

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Card container similar to the form card in the screenshot
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(customGold)
                        .padding(.top, 8)
                        .opacity(showIcon ? 1 : 0)
                        .scaleEffect(showIcon ? 1 : 0.6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showIcon)

                    // Title
                    Text("No Matches Found")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: showTitle)

                    // Subtitle
                    Text("We couldn't find any matching reports in our database. You can create a new report using this photo immediately.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                        .lineSpacing(3)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 14)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showSubtitle)

                    // Primary action button (gold)
                    Button(action: { onAddReport() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                            Text("Add Lost/Found Report").font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(customGold)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .shadow(color: customGold.opacity(0.25), radius: 8, x: 0, y: 4)
                    .opacity(showPrimaryBtn ? 1 : 0)
                    .offset(y: showPrimaryBtn ? 0 : 12)
                    .animation(.easeOut(duration: 0.35).delay(0.4), value: showPrimaryBtn)

                    // OR divider
                    Text("OR")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .opacity(showOR ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.48), value: showOR)

                    // Secondary buttons (beige background, gold text)
                    VStack(spacing: 12) {
                        Button(action: { onDismissToCamera() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                Text("Take Another Photo")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(customGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(customLightBeige)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .opacity(showSecBtn1 ? 1 : 0)
                        .offset(y: showSecBtn1 ? 0 : 10)
                        .animation(.easeOut(duration: 0.32).delay(0.54), value: showSecBtn1)

                        Button(action: { onUploadAnother() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.fill")
                                Text("Upload Another Image")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(customGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(customLightBeige)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .opacity(showSecBtn2 ? 1 : 0)
                        .offset(y: showSecBtn2 ? 0 : 10)
                        .animation(.easeOut(duration: 0.32).delay(0.60), value: showSecBtn2)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            showIcon       = true
            showTitle      = true
            showSubtitle   = true
            showPrimaryBtn = true
            showOR         = true
            showSecBtn1    = true
            showSecBtn2    = true
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

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
#Preview("NoMatches Full Screen") {
    NoMatchesFullScreenView(
        onDismissToCamera: {},
        onUploadAnother: {},
        onAddReport: {}
    )
}

