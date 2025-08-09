import SwiftUI
import CoreLocation

// MARK: - Manual Route Planning View
struct ManualRoutePlanningView: View {
    @Environment(\.dismiss) private var dismiss
    
    // CONFIG
    let config: ManualRouteConfig
    let onRouteGenerated: (GeneratedRoute) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Manual Route Feature")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Wird in Phase 2 implementiert!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Konfiguration:")
                            .font(.headline)
                        
                        Text("Stadt: \(config.startingCity)")
                        Text("Endpunkt: \(config.endpointOption.rawValue)")
                        if !config.customEndpoint.isEmpty {
                            Text("Custom Ziel: \(config.customEndpoint)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Manuelle Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ManualRoutePlanningView(
        config: ManualRouteConfig(
            startingCity: "Berlin",
            startingCoordinates: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            usingCurrentLocation: false,
            endpointOption: .roundtrip,
            customEndpoint: "",
            customEndpointCoordinates: nil
        ),
        onRouteGenerated: { _ in }
    )
}