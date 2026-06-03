//
//  CustomTextField.swift
//  PawPin
//
//  Created by Ahmed Alrashed on 2026-05-26.
//

import SwiftUI

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var keyboardType: UIKeyboardType
    var autoCapitalization: TextInputAutocapitalization
    
    // Order 1: Icon first (used in Auth views)
    init(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autoCapitalization: TextInputAutocapitalization = .never
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.autoCapitalization = autoCapitalization
    }
    
    // Order 2: Placeholder first (used in Report views)
    init(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autoCapitalization: TextInputAutocapitalization = .never
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.autoCapitalization = autoCapitalization
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .secondary)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.primary)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autoCapitalization)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 0.96, green: 0.96, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 1)
        )
    }
}
