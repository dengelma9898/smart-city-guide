import SwiftUI
import CoreLocation

/// Action buttons for manual card interactions in route editing
struct RouteEditActionButtonsView: View {
    
    let currentTopCard: SwipeCard?
    let onManualAction: (SwipeDirection) -> Void
    
    var body: some View {
        HStack(spacing: 32) {
            // Reject Button
            Button(action: {
                onManualAction(.right)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    Text("Überspringen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentTopCard == nil)
            .opacity(currentTopCard == nil ? 0.5 : 1.0)
            
            // Accept Button
            Button(action: {
                onManualAction(.left)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("Nehmen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentTopCard == nil)
            .opacity(currentTopCard == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: currentTopCard != nil)
    }
}

#Preview {
    VStack(spacing: 20) {
        RouteEditActionButtonsView(
            currentTopCard: nil,
            onManualAction: { direction in
                print("Direction: \(direction)")
            }
        )
        
        RouteEditActionButtonsView(
            currentTopCard: nil,
            onManualAction: { direction in
                print("Direction: \(direction)")
            }
        )
    }
    .padding()
}
