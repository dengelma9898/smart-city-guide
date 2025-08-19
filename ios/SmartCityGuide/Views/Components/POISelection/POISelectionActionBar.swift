import SwiftUI

/// Action bar for manual POI selection with accept/reject/skip buttons
struct POISelectionActionBar: View {
    
    let hasCurrentCard: Bool
    let selectionCount: Int
    let onAccept: () -> Void
    let onReject: () -> Void
    let onSkip: () -> Void
    let onViewSelections: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main action buttons
            HStack(spacing: 20) {
                // Reject button
                Button(action: onReject) {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.red)
                        Text("Nein")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.red.opacity(0.1)))
                    .overlay(Circle().stroke(.red.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!hasCurrentCard)
                .opacity(hasCurrentCard ? 1.0 : 0.5)
                
                // Skip button
                Button(action: onSkip) {
                    VStack(spacing: 4) {
                        Image(systemName: "forward")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange)
                        Text("Skip")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(.orange.opacity(0.1)))
                    .overlay(Circle().stroke(.orange.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!hasCurrentCard)
                .opacity(hasCurrentCard ? 1.0 : 0.5)
                
                // Accept button
                Button(action: onAccept) {
                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                        Text("Ja!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.green.opacity(0.1)))
                    .overlay(Circle().stroke(.green.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!hasCurrentCard)
                .opacity(hasCurrentCard ? 1.0 : 0.5)
            }
            
            // Selection summary button
            if selectionCount > 0 {
                Button(action: onViewSelections) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("\(selectionCount) ausgewählt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.opacity(0.1))
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        POISelectionActionBar(
            hasCurrentCard: true,
            selectionCount: 0,
            onAccept: { print("Accept") },
            onReject: { print("Reject") },
            onSkip: { print("Skip") },
            onViewSelections: { print("View Selections") }
        )
        
        POISelectionActionBar(
            hasCurrentCard: true,
            selectionCount: 3,
            onAccept: { print("Accept") },
            onReject: { print("Reject") },
            onSkip: { print("Skip") },
            onViewSelections: { print("View Selections") }
        )
        
        POISelectionActionBar(
            hasCurrentCard: false,
            selectionCount: 5,
            onAccept: { print("Accept") },
            onReject: { print("Reject") },
            onSkip: { print("Skip") },
            onViewSelections: { print("View Selections") }
        )
    }
    .padding()
}
