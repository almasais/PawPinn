//
//  ContactSupport.swift
//  PawPin
//
//  Created by Abeer Alshabrami on 6/20/26.
//

import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedType: SupportType = .suggestion
    @State private var messageText = ""
    @State private var isSent = false
    @State private var isSending = false
    @FocusState private var isTextFocused: Bool

    private let email = "cat4running@gmail.com"
    private let whatsapp = "0507825344"

    enum SupportType: String, CaseIterable {
        case suggestion = "Suggestion"
        case complaint  = "Complaint"

        var icon: String {
            switch self {
            case .suggestion: return "lightbulb.fill"
            case .complaint:  return "exclamationmark.bubble.fill"
            }
        }
        var color: Color {
            switch self {
            case .suggestion: return .orange
            case .complaint:  return .red
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark
                    ? Color(.systemBackground)
                    : Color(red: 0.97, green: 0.97, blue: 0.97))
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Hero banner ──
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "headset")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color.brand)
                            }
                            Text("We're here to help")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("Send us a message or reach out directly.\nWe'll get back to you as soon as possible.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 24)

                        // ── Type picker ──
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            HStack(spacing: 10) {
                                ForEach(SupportType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = type
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 13))
                                            Text(type.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(selectedType == type ? .white : .primary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedType == type
                                                ? type.color
                                                : Color(.secondarySystemGroupedBackground)
                                        )
                                        .clipShape(Capsule())
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }

                        // ── Message box ──
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark
                                        ? Color(.secondarySystemBackground)
                                        : Color.white)
                                    .shadow(color: .black.opacity(0.04), radius: 8, y: 3)

                                if messageText.isEmpty {
                                    Text(selectedType == .suggestion
                                         ? "Share your idea or feature request…"
                                         : "Describe the issue you're experiencing…")
                                        .foregroundColor(Color(.placeholderText))
                                        .font(.system(size: 15))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 14)
                                }

                                TextEditor(text: $messageText)
                                    .focused($isTextFocused)
                                    .font(.system(size: 15))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(minHeight: 130)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .frame(minHeight: 130)
                            .padding(.horizontal, 20)
                        }

                        // ── Send via Email button ──
                        Button {
                            sendEmail()
                        } label: {
                            HStack(spacing: 10) {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: isSent ? "checkmark.circle.fill" : "paperplane.fill")
                                        .font(.system(size: 16))
                                    Text(isSent ? "Message Sent!" : "Send via Email")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isSent
                                    ? Color.green
                                    : (messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.brand.opacity(0.4)
                                        : Color.brand)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.brand.opacity(0.3), radius: 10, y: 4)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSent)
                        .padding(.horizontal, 20)

                        // ── Divider ──
                        HStack {
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                            Text("or reach out directly")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .fixedSize()
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                        }
                        .padding(.horizontal, 20)

                        // ── Direct contact cards ──
                        VStack(spacing: 12) {
                            ContactCard(
                                icon: "envelope.fill",
                                iconColor: Color.brand,
                                title: "Email",
                                subtitle: email,
                                action: { openEmail() }
                            )
                            ContactCard(
                                icon: "message.fill",
                                iconColor: .green,
                                title: "WhatsApp",
                                subtitle: whatsapp,
                                action: { openWhatsApp() }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
                .onTapGesture { isTextFocused = false }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color.brand)
                }
            }
        }
    }

    // MARK: - Actions

    private func sendEmail() {
        let subject = "[\(selectedType.rawValue)] PawPin Feedback"
        let body = messageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(body)") {
            UIApplication.shared.open(url)
            withAnimation { isSent = true }
        }
    }

    private func openEmail() {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    private func openWhatsApp() {
        let number = whatsapp.replacingOccurrences(of: "0", with: "966", range: whatsapp.startIndex..<whatsapp.index(whatsapp.startIndex, offsetBy: 1))
        if let url = URL(string: "https://wa.me/\(number)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Contact Card
private struct ContactCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(colorScheme == .dark
                ? Color(.secondarySystemBackground)
                : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview { ContactSupportView() }
