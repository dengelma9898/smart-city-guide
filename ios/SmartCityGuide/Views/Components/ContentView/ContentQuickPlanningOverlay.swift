import SwiftUI

/// Overlay shown during quick planning process
struct ContentQuickPlanningOverlay: View {
    
    let message: String
    let isVisible: Bool
    
    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text(message)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.55))
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

#Preview {
    VStack(spacing: 20) {
        ContentQuickPlanningOverlay(
            message: "Wir basteln deine Route!",
            isVisible: true
        )
        
        ContentQuickPlanningOverlay(
            message: "Entdecke coole Orte…",
            isVisible: false
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.3))
}
