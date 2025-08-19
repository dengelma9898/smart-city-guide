import SwiftUI

/// Toast notification view for POI selection feedback
struct POISelectionToastView: View {
    
    let message: String
    let isVisible: Bool
    
    var body: some View {
        Group {
            if isVisible {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

#Preview {
    VStack(spacing: 20) {
        POISelectionToastView(
            message: "POI zur Auswahl hinzugefügt",
            isVisible: true
        )
        
        POISelectionToastView(
            message: "POI abgelehnt",
            isVisible: false
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
