//
//  LandingPageView.swift
//  PawPin
//
//  Created by lay on 01/12/1447 AH.
//


import SwiftUI

struct LandingPageView: View {
    let lightOrange = Color.brand
    let subTextColor = Color(hex: "7B7B7B")

    var body: some View {
        NavigationStack {
            MainPageView()
        }
    }

    // MARK: - Main Page (PAWPIN)
    struct MainPageView: View {
        @State private var animateIn = false

        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    ZStack {
                        ArcDotsView()
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        ArcAvatarsView()
                            .opacity(animateIn ? 1 : 0)
                    }
                    .frame(height: 220)
                    .padding(.bottom, 10)

                    Text("PAWPIN")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 248/255, green: 179/255, blue: 52/255))
                        .scaleEffect(animateIn ? 1 : 0.7)
                        .opacity(animateIn ? 1 : 0)
                        .padding(.bottom, 8)

                    HStack(spacing: 4) {
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(red: 248/255, green: 179/255, blue: 52/255))
                            .font(.system(size: 14))
                            .rotationEffect(.degrees(15))
                    }
                    .padding(.trailing, 40)
                    .offset(y: -50)

                    Text("Lost or found? We connect you")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        .opacity(animateIn ? 1 : 0)

                    Text("One post can bring them home 🐾")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                        .opacity(animateIn ? 1 : 0)

                    Spacer().frame(height: 50)

                    VStack(spacing: 14) {
                        NavigationLink(destination: RegisterView()) {
                            Text("Sign Up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Color(red: 248/255, green: 179/255, blue: 52/255)
                                )
                                .cornerRadius(27)
                        }
                        .scaleEffect(animateIn ? 1 : 0.9)
                        .opacity(animateIn ? 1 : 0)

                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 248/255, green: 179/255, blue: 52/255))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .cornerRadius(27)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 27)
                                        .stroke(Color(red: 248/255, green: 179/255, blue: 52/255), lineWidth: 1.5)
                                )
                        }
                        .scaleEffect(animateIn ? 1 : 0.9)
                        .opacity(animateIn ? 1 : 0)
                    }
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 50)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Arc Dots
    struct ArcDotsView: View {
        var body: some View {
            Canvas { context, size in
                let cx = size.width * 0.5
                let cy = size.height * 1.1
                let radius: CGFloat = size.height * 0.9
                let startAngle: Double = -160
                let endAngle: Double = -20
                let dotCount = 28

                for i in 0..<dotCount {
                    let t = Double(i) / Double(dotCount - 1)
                    let angle = startAngle + t * (endAngle - startAngle)
                    let rad = angle * .pi / 180
                    let x = cx + radius * cos(rad)
                    let y = cy + radius * sin(rad)

                    let dotSize: CGFloat = i % 3 == 0 ? 7 : 4
                    let color: Color = i % 2 == 0
                        ? Color(red: 1.0, green: 0.90, blue: 0.75)
                        : Color(red: 1.0, green: 0.95, blue: 0.80)

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x - dotSize/2,
                            y: y - dotSize/2,
                            width: dotSize,
                            height: dotSize
                        )),
                        with: .color(color)
                    )
                }
            }
        }
    }

    // MARK: - Arc Avatars
    // استبدل الإيموجي بـ Image("اسم_صورتك") إذا عندك صور حيوانات
    struct ArcAvatarsView: View {
        let pets = ["🐈", "🐾", "🐈", "🐾"]
        let positions: [CGFloat] = [0.15, 0.38, 0.62, 0.85]

        var body: some View {
            GeometryReader { geo in
                let cx = geo.size.width * 0.5
                let cy = geo.size.height * 1.1
                let radius = geo.size.height * 0.9
                let startAngle: Double = -160
                let endAngle:   Double = -20

                ForEach(0..<pets.count, id: \.self) { i in
                    let t = Double(positions[i])
                    let angle = (startAngle + t * (endAngle - startAngle)) * .pi / 180
                    let x = cx + radius * cos(angle)
                    let y = cy + radius * sin(angle)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)

                        Text(pets[i])
                            .font(.system(size: 26))

                        Circle()
                            .stroke(
                                Color(red: 248/255, green: 179/255, blue: 52/255).opacity(0.6),
                                lineWidth: 2
                            )
                            .frame(width: 48, height: 48)
                    }
                    .position(x: x, y: y)
                }
            }
        }
    }
}


#Preview {
    LandingPageView()
}
