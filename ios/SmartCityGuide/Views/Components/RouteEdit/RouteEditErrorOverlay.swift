import SwiftUI

/// Error overlay for route editing
struct RouteEditErrorOverlay: View {
    
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Fehler")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button("OK", action: onDismiss)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 100, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue)
                )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.4))
        .onTapGesture {
            onDismiss()
        }
    }
}

#Preview {
    RouteEditErrorOverlay(
        message: "Es konnte keine neue Route berechnet werden. Bitte versuchen Sie es erneut.",
        onDismiss: {
            print("Error dismissed")
        }
    )
}
