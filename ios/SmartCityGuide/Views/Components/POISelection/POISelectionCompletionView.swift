import SwiftUI

/// Completion view shown when all POIs have been processed
struct POISelectionCompletionView: View {
    
    let hasSelections: Bool
    let selectionCount: Int
    let onComplete: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Status icon and message
            VStack(spacing: 16) {
                Image(systemName: hasSelections ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(hasSelections ? .green : .orange)
                
                Text(hasSelections ? "Auswahl abgeschlossen!" : "Keine POIs ausgewählt")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if hasSelections {
                    Text("Du hast \(selectionCount) interessante Orte ausgewählt")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Du kannst trotzdem fortfahren oder nochmal durch die POIs swipen")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Text(hasSelections ? "Weiter zur Route" : "Ohne POIs fortfahren")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(hasSelections ? .blue : .gray)
                        )
                }
                
                Button(action: onRestart) {
                    Text("Nochmal von vorne")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 40) {
        POISelectionCompletionView(
            hasSelections: true,
            selectionCount: 5,
            onComplete: { print("Complete with selections") },
            onRestart: { print("Restart") }
        )
        
        POISelectionCompletionView(
            hasSelections: false,
            selectionCount: 0,
            onComplete: { print("Complete without selections") },
            onRestart: { print("Restart") }
        )
    }
}
