//
//  SplashView.swift
//  PawPin
//
//  Created by Afnan hassan on 22/12/1447 AH.
//

import SwiftUI

// MARK: - Paw Print Data
struct PawPrint: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

// MARK: - Single Paw View (يستخدم صورة Frame 5)
struct PawView: View {
    let paw: PawPrint
    @State private var isVisible = false

    var body: some View {
        GeometryReader { geo in
            Image("Frame 5")
                .resizable()
                .scaledToFit()
                .frame(width: 150 * paw.scale, height: 180 * paw.scale)
                .rotationEffect(.degrees(paw.rotation))
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.3)
                .position(
                    x: geo.size.width  * paw.x,
                    y: geo.size.height * paw.y
                )
                .onAppear {
                    withAnimation(
                        .spring(response: 0.4, dampingFraction: 0.6)
                        .delay(paw.delay)
                    ) {
                        isVisible = true
                    }
                }
        }
    }
}

// MARK: - Splash Screen
// MARK: - Splash Screen
struct SplashView: View {

    // نفس المواضع الأصلية
    private let basePawPrints: [PawPrint] = [
        PawPrint(x: 0.82, y: 0.88, rotation: 18,  scale: 1.05, delay: 0),
        PawPrint(x: 0.18, y: 0.78, rotation: -25, scale: 1.02, delay: 0),
        PawPrint(x: 0.78, y: 0.64, rotation: 15,  scale: 1.00, delay: 0),
        PawPrint(x: 0.22, y: 0.52, rotation: -20, scale: 0.98, delay: 0),
        PawPrint(x: 0.74, y: 0.38, rotation: 12,  scale: 0.96, delay: 0),
        PawPrint(x: 0.26, y: 0.26, rotation: -18, scale: 0.94, delay: 0),
        PawPrint(x: 0.80, y: 0.14, rotation: 10,  scale: 0.85, delay: 0),
        PawPrint(x: 0.18, y: 0.06, rotation: -12, scale: 0.80, delay: 0),
    ]

    // نحسب التأخير تلقائيًا بحيث الأكبر y (أسفل) يبدأ أولًا
    var pawPrints: [PawPrint] {
        let sorted = basePawPrints.sorted { $0.y > $1.y } // من أسفل لأعلى
        let step: Double = 0.12 // الفاصل الزمني بين كل بصمة
        return sorted.enumerated().map { index, p in
            PawPrint(x: p.x, y: p.y, rotation: p.rotation, scale: p.scale, delay: Double(index) * step)
        }
    }

    @State private var showMain = false

    var body: some View {
        Group {
            if showMain {
                LandingPageView()
                    .ignoresSafeArea()
            } else {
                ZStack {
                    Color.white.ignoresSafeArea()

                    ForEach(pawPrints) { paw in
                        PawView(paw: paw)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showMain = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showMain)
    }
}

#Preview {
    SplashView()
}

