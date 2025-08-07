//
//  TaskCard.swift
//  Scheduler
//
//  Created by ByteDance on 6/3/25.
//

import SwiftUI

struct CardView: View {
    let title: String
    @Binding var isCompleted: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isCompleted ? [.green.opacity(0.8), .green] : [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(isCompleted ? 0.3 : 0.2),
                        radius: isCompleted ? 8 : 5,
                        x: 0, y: isCompleted ? 4 : 2)
            
            VStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isCompleted ? .white : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isCompleted.toggle()
            }
        }
    }
}
