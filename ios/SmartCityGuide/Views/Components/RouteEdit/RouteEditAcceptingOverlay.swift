import SwiftUI

/// Overlay shown while processing route changes
struct RouteEditAcceptingOverlay: View {
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Route wird erstellt…")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    RouteEditAcceptingOverlay()
}
