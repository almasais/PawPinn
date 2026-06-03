//
//  RegisterView.swift
//  PawPin
//

import SwiftUI
import Supabase

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                    Text("Join PawPin and help reunite pets.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                VStack(spacing: 16) {
                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $fullName,
                        autoCapitalization: .words
                    )
                    
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
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                
                PrimaryButton(title: "Sign Up", isLoading: isLoading) {
                    register()
                }
                .padding(.top, 16)
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Log In") {
                        dismiss()
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
    
    private func register() {
        guard !fullName.isEmpty, !email.isEmpty, password.count >= 6 else {
            errorMessage = "Please fill all fields and use at least 6 characters for password."
            return
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password
                )
                
                if let userId = response.user.id {
                    struct InsertUser: Encodable {
                        let id: UUID
                        let full_name: String
                        let email: String
                    }
                    try await SupabaseManager.shared.client
                        .from("users")
                        .insert(InsertUser(id: userId, full_name: fullName, email: email))
                        .execute()
                }
                
                // AuthManager will automatically handle redirect if sign up auto-logs in.
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
