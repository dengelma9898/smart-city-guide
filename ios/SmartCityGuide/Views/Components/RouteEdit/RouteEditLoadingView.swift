import SwiftUI

/// Loading view for route edit interface
struct RouteEditLoadingView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            VStack(spacing: 8) {
                Text("Lade Alternativen...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Suche nach besseren Stopps in der Nähe")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    RouteEditLoadingView()
}
