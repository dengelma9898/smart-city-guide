import SwiftUI

/// Generating route view for route optimization phase in manual route planning
struct ManualRouteGeneratingView: View {
    let selectedPOICount: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Erstelle deine Route...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Optimiere die Reihenfolge deiner \(selectedPOICount) ausgewählten POIs")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Debug hint for long-running operations
                Text("Sollte das länger als 15s dauern, breche ich automatisch ab.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ManualRouteGeneratingView(selectedPOICount: 8)
}
