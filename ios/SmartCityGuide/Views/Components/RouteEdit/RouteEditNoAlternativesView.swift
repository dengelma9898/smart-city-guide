import SwiftUI

/// Empty state view when no alternatives are available
struct RouteEditNoAlternativesView: View {
    
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "location.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            
            // Content
            VStack(spacing: 8) {
                Text("Keine Alternativen gefunden")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Für diesen Stopp sind leider keine passenden Alternativen in der Nähe verfügbar.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action
            Button(action: onCancel) {
                Text("Zurück")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    RouteEditNoAlternativesView {
        print("Cancel tapped")
    }
}
