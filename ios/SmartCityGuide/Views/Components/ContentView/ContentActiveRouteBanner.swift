import SwiftUI
import CoreLocation

/// Legacy active route banner (shown when bottom sheet is disabled)
struct ContentActiveRouteBanner: View {
    
    let route: GeneratedRoute
    let onEndRoute: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deine Tour läuft!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(route.totalDistance / 1000)) km • \(formatExperienceTime(route.totalExperienceTime))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                Text("\(route.numberOfStops) coole Stopps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .background(.blue.opacity(0.8))
            )
            
            Button(action: onEndRoute) {
                Text("Tour beenden")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.red)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
            }
            .accessibilityIdentifier("home.route.end")
            .accessibilityLabel("Tour beenden")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
    }
    
    // MARK: - Helper Methods
    
    /// Format experience time for display
    private func formatExperienceTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

#Preview {
    let sampleRoute = GeneratedRoute(
        waypoints: [
            RoutePoint(
                name: "Start",
                coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                address: "Startpunkt",
                category: .attraction
            ),
            RoutePoint(
                name: "Museum",
                coordinate: CLLocationCoordinate2D(latitude: 52.5210, longitude: 13.4060),
                address: "Museumsinsel",
                category: .museum
            )
        ],
        routes: [],
        totalDistance: 2500.0,
        totalTravelTime: 30.0 * 60,
        totalVisitTime: 90.0 * 60,
        totalExperienceTime: 120.0 * 60,
        endpointOption: .roundtrip
    )
    
    ContentActiveRouteBanner(
        route: sampleRoute,
        onEndRoute: { print("End route tapped") }
    )
    .background(Color.gray.opacity(0.2))
}
