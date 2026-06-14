//
//  LoginView.swift
//  PawPin
//
//  Created by Ahmed Alrashed on 2026-05-26.
//

import SwiftUI
import Supabase

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                        Text("Log in to continue finding paws")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        
                        HStack {
                            Spacer()
                            NavigationLink("Forgot Password?") {
                                ForgotPasswordView()
                            }
                            .font(.footnote)
                            .foregroundColor(Color.brand)
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    PrimaryButton(title: "Log In", isLoading: isLoading) {
                        login()
                    }
                    .padding(.top, 16)
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        NavigationLink("Sign Up") {
                            RegisterView()
                        }
                        .foregroundColor(Color.brand)
                        .bold()
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.brand)
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
    }
    
    private func login() {
        guard !isLoading else { return }
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )
                // AuthManager will automatically detect state change and redirect
            } catch {
                await MainActor.run {
                    let errStr = error.localizedDescription.lowercased()
                    if errStr.contains("invalid credentials") || errStr.contains("invalid login") || errStr.contains("email not confirmed") || errStr.contains("invalid_grant") {
                        self.errorMessage = "Invalid email or password"
                    } else if errStr.contains("rate limit") || errStr.contains("429") || errStr.contains("too many requests") {
                        self.errorMessage = "Please wait a moment before trying again."
                    } else {
                        self.errorMessage = "Unable to login right now. Please try again."
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

