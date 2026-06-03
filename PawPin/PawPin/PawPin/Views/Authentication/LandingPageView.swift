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
            ZStack(alignment: .top) {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Image("OnboardingBackground")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.85)
                        .padding(.top, 20)

                    Spacer().frame(height: 230)

                    VStack(spacing: 18) {
                        VStack(spacing: 10) {
                            Text("Lost or found? We connect you")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text("One post can bring them home 🐾")
                                .font(.system(size: 15))
                                .foregroundColor(subTextColor)
                        }
                        
                        Spacer()

                        NavigationLink(destination: RegisterView()) {
                            Text("Sign Up")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(lightOrange)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 35)

                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(lightOrange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(lightOrange, lineWidth: 2)
                                )
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 35)
                        .padding(.bottom, 50)
                    }
                }

                VStack {
                    Image("FindMyPetLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130)
                        .padding(.top, 350)
                }
                .zIndex(2)
            }
        }
    }
}

#Preview {
    LandingPageView()
}
