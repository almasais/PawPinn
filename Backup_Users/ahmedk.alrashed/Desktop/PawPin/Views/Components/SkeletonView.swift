//
//  SkeletonView.swift
//  PawPin
//

import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        Rectangle()
            .fill(Color(white: 0.9))
            .opacity(isAnimating ? 0.5 : 1.0)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

struct PetCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(cornerRadius: 12)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(cornerRadius: 4)
                    .frame(width: 120, height: 16)
                
                SkeletonView(cornerRadius: 4)
                    .frame(width: 80, height: 12)
                
                SkeletonView(cornerRadius: 4)
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}
