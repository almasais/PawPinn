//
//  CustomTextField.swift
//  PawPin
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autoCapitalization)
            }
        }
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(white: 0.9), lineWidth: 1)
        )
    }
}
