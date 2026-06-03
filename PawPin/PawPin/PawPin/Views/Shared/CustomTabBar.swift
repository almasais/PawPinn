//
//  CustomTabBar.swift
//  PawPin
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: String
    @Environment(\.colorScheme) var colorScheme
    
    let tabs = [
        ("Home", "house.fill"),
        ("Map", "map.fill"),
        ("Search", "camera.fill"),
        ("Chat", "message.fill")
    ]
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.0) { tab in
                let name = tab.0
                let icon = tab.1
                let isSelected = selectedTab == name
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = name
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? Color.brand : .gray)
                            .scaleEffect(isSelected ? 1.15 : 1.0)
                        
                        Text(name)
                            .font(.caption2)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundColor(isSelected ? Color.brand : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            (colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
