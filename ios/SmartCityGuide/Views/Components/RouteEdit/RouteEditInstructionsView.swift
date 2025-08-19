//
//  RouteEditInstructionsView.swift
//  SmartCityGuide
//
//  Instructions and swipe hints for Route Edit interface
//

import SwiftUI

struct RouteEditInstructionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Finde besseren Stopp")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Swipe die Karten, um Alternativen zu entdecken")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Swipe gesture hints
            HStack(spacing: 24) {
                SwipeHintView(
                    direction: .left,
                    text: "Nehmen",
                    color: .green
                )
                
                SwipeHintView(
                    direction: .right,
                    text: "Überspringen",
                    color: .red
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Supporting View

private struct SwipeHintView: View {
    let direction: SwipeDirection
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: direction.indicatorIcon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(direction == .left ? "Nach links" : "Nach rechts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    RouteEditInstructionsView()
        .padding()
}
