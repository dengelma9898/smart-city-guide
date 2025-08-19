import SwiftUI
import CoreLocation

/// Next waypoint card for active route navigation
struct ActiveRouteNextWaypointCard: View {
    
    let waypoint: RoutePoint
    let distanceToNext: Double?
    let estimatedArrival: Date?
    
    @State private var waypointPulsePhase = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Waypoint icon with pulse animation
                Image(systemName: waypoint.category.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                    .scaleEffect(1.0 + sin(waypointPulsePhase) * 0.1)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: waypointPulsePhase)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(waypoint.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .lineLimit(2)
                    
                    Text(waypoint.address)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let distanceToNext = distanceToNext {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                            Text(formatDistance(distanceToNext))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                            
                            if let eta = estimatedArrival {
                                Text("• \(formatETA(eta))")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            waypointPulsePhase = 1.0
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func formatETA(_ eta: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "ETA \(formatter.string(from: eta))"
    }
}

#Preview {
    let sampleWaypoint = RoutePoint(
        name: "Brandenburger Tor",
        coordinate: CLLocationCoordinate2D(latitude: 52.5163, longitude: 13.3777),
        address: "Pariser Platz, 10117 Berlin",
        category: .attraction
    )
    
    VStack(spacing: 20) {
        ActiveRouteNextWaypointCard(
            waypoint: sampleWaypoint,
            distanceToNext: 450.0,
            estimatedArrival: Date().addingTimeInterval(8 * 60) // 8 minutes from now
        )
        
        ActiveRouteNextWaypointCard(
            waypoint: sampleWaypoint,
            distanceToNext: 1250.0,
            estimatedArrival: nil
        )
        
        ActiveRouteNextWaypointCard(
            waypoint: sampleWaypoint,
            distanceToNext: nil,
            estimatedArrival: nil
        )
    }
    .padding()
}
