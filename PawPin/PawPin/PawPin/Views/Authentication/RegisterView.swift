//
//  RegisterView.swift
//  PawPin
//
//  Created by Ahmed Alrashed on 2026-05-26.
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
        guard !isLoading else { return }
        guard !fullName.isEmpty, !email.isEmpty, password.count >= 6 else {
            errorMessage = "Please fill all fields and use at least 6 characters for password."
            return
        }
        isLoading = true
        errorMessage = nil
        
        // 🔥 عدلنا هنا: شلنا السطور القديمة اللي كانت تفعل فلاق المنع لمنع الدخول التلقائي
        AuthManager.shared.pendingRegisterFullName = fullName
        
        Task {
            do {
                let response = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password,
                    data: ["full_name": .string(fullName)]
                )
                
                let userId = response.user.id
                struct InsertUser: Encodable {
                    let id: UUID
                    let full_name: String
                    let email: String
                }
                
                // حفظ بيانات المستخدم في جدول users العام
                try await SupabaseManager.shared.client
                    .from("users")
                    .upsert(InsertUser(id: userId, full_name: fullName, email: email))
                    .execute()
                
                // 🔥 التعديل الأهم: شلنا الـ signOut والـ dismiss القديم.
                // الـ AuthManager الحين راح يلقط الـ .signedIn الإيفينت ويدخله للـ HomeView تلقائياً.
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    AuthManager.shared.isRegistering = false
                    let errStr = error.localizedDescription.lowercased()
                    if errStr.contains("rate limit") || errStr.contains("429") || errStr.contains("too many requests") || errStr.contains("limit exceeded") {
                        self.errorMessage = "Please wait a moment before trying again."
                    } else if errStr.contains("already exists") || errStr.contains("already registered") || errStr.contains("conflict") || errStr.contains("email_exists") {
                        self.errorMessage = "Email already exists"
                    } else {
                        self.errorMessage = "Unable to create account right now"
                    }
                    self.isLoading = false
                }
            }
        }
    }
}
