import SwiftUI

/// Intro view with swipe hints and animations for route editing
struct RouteEditIntroView: View {
    
    let showingIntroAnimation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Alternative Stopps entdecken")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Swipe die Karten, um Alternativen zu entdecken")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Swipe gesture hints
            HStack(spacing: 24) {
                swipeHint(
                    direction: .left,
                    text: "Nehmen",
                    color: .green
                )
                
                swipeHint(
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
        .scaleEffect(showingIntroAnimation ? 0.95 : 1.0)
        .opacity(showingIntroAnimation ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showingIntroAnimation)
    }
    
    private func swipeHint(direction: SwipeDirection, text: String, color: Color) -> some View {
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
    VStack(spacing: 20) {
        RouteEditIntroView(showingIntroAnimation: false)
        RouteEditIntroView(showingIntroAnimation: true)
    }
    .padding()
}
