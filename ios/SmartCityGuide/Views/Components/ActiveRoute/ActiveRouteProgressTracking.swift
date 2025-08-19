import SwiftUI
import CoreLocation

/// Progress tracking display for active route
struct ActiveRouteProgressTracking: View {
    
    let route: GeneratedRoute
    let progress: RouteProgress?
    
    @State private var progressAnimationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress header
            HStack {
                Text("Deine Tour")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let progress = progress {
                    Text("\(progress.completedWaypoints)/\(route.waypoints.count) Stopps")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            // Progress bar with animation
            progressBar
            
            // Time and distance stats
            HStack(spacing: 20) {
                statItem(
                    icon: "clock.fill",
                    title: "Zeit",
                    value: formatDuration(route.totalExperienceTime),
                    color: .orange
                )
                
                statItem(
                    icon: "figure.walk",
                    title: "Distanz",
                    value: formatDistance(route.totalDistance),
                    color: .green
                )
                
                statItem(
                    icon: "map.fill",
                    title: "Stopps",
                    value: "\(route.waypoints.count)",
                    color: .blue
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .onAppear {
            startProgressAnimation()
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                    .scaleEffect(y: 1.0 + sin(progressAnimationPhase) * 0.1)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: progressAnimationPhase)
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Stat Item
    
    private func statItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private var progressPercentage: Double {
        guard let progress = progress else { return 0.0 }
        return Double(progress.completedWaypoints) / Double(route.waypoints.count)
    }
    
    private func startProgressAnimation() {
        progressAnimationPhase = 1.0
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

#Preview {
    let sampleRoute = GeneratedRoute(
        waypoints: [
            RoutePoint(name: "Start", coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), address: "Start", category: .attraction),
            RoutePoint(name: "Museum", coordinate: CLLocationCoordinate2D(latitude: 52.5210, longitude: 13.4060), address: "Museum", category: .museum),
            RoutePoint(name: "Park", coordinate: CLLocationCoordinate2D(latitude: 52.5220, longitude: 13.4070), address: "Park", category: .park)
        ],
        routes: [],
        totalDistance: 2500.0,
        totalTravelTime: 30.0 * 60,
        totalVisitTime: 90.0 * 60,
        totalExperienceTime: 120.0 * 60
    )
    
    let sampleProgress = RouteProgress(
        completedWaypoints: 1,
        currentWaypointIndex: 1,
        totalWaypoints: 3,
        elapsedTime: 25.0 * 60,
        remainingTime: 95.0 * 60
    )
    
    VStack(spacing: 20) {
        ActiveRouteProgressTracking(
            route: sampleRoute,
            progress: sampleProgress
        )
        
        ActiveRouteProgressTracking(
            route: sampleRoute,
            progress: nil
        )
    }
    .padding()
}
