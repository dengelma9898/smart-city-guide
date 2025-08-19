import SwiftUI
import CoreLocation

/// Route modification tools for active route sheet
struct ActiveRouteModificationTools: View {
    
    let route: GeneratedRoute
    let onModify: ((RouteModification) -> Void)?
    let onEnd: () -> Void
    let onAddStop: () -> Void
    
    @State private var showingEndConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Modification actions
            if let onModify = onModify {
                modificationActions(onModify: onModify)
            }
            
            // Primary actions
            primaryActions
        }
        .alert("Tour wirklich beenden?", isPresented: $showingEndConfirmation) {
            Button("Abbrechen", role: .cancel) { 
                RouteHaptics.lightImpact.trigger()
            }
            Button("Tour beenden", role: .destructive) {
                RouteHaptics.mediumImpact.trigger()
                onEnd()
            }
        } message: {
            Text("Deine aktuelle Tour wird beendet und kann nicht wiederhergestellt werden.")
        }
    }
    
    // MARK: - Modification Actions
    
    private func modificationActions(onModify: @escaping (RouteModification) -> Void) -> some View {
        VStack(spacing: 12) {
            Text("Route anpassen")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                modificationButton(
                    icon: "plus.circle.fill",
                    title: "Stopp hinzufügen",
                    subtitle: "Neue Sehenswürdigkeit",
                    color: .blue
                ) {
                    onModify(.addWaypoint)
                }
                
                modificationButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Umorganisieren",
                    subtitle: "Reihenfolge ändern",
                    color: .orange
                ) {
                    onModify(.reorderWaypoints)
                }
                
                modificationButton(
                    icon: "minus.circle.fill",
                    title: "Stopp entfernen",
                    subtitle: "Weniger besuchen",
                    color: .red
                ) {
                    onModify(.removeWaypoint)
                }
                
                modificationButton(
                    icon: "wand.and.stars",
                    title: "Optimieren",
                    subtitle: "Beste Route finden",
                    color: .purple
                ) {
                    onModify(.optimizeRoute)
                }
            }
        }
    }
    
    private func modificationButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Primary Actions
    
    private var primaryActions: some View {
        VStack(spacing: 12) {
            // Add stop button
            Button(action: onAddStop) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Stopp hinzufügen")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.blue)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // End tour button
            Button(action: { showingEndConfirmation = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Tour beenden")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                    
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    let sampleRoute = GeneratedRoute(
        waypoints: [
            RoutePoint(name: "Start", coordinate: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), address: "Start", category: .attraction),
            RoutePoint(name: "Museum", coordinate: CLLocationCoordinate2D(latitude: 52.5210, longitude: 13.4060), address: "Museum", category: .museum)
        ],
        routes: [],
        totalDistance: 1500.0,
        totalTravelTime: 20.0 * 60,
        totalVisitTime: 60.0 * 60,
        totalExperienceTime: 80.0 * 60
    )
    
    ScrollView {
        VStack(spacing: 20) {
            ActiveRouteModificationTools(
                route: sampleRoute,
                onModify: { modification in
                    print("Route modification: \(modification)")
                },
                onEnd: { print("End tour") },
                onAddStop: { print("Add stop") }
            )
            
            ActiveRouteModificationTools(
                route: sampleRoute,
                onModify: nil,
                onEnd: { print("End tour") },
                onAddStop: { print("Add stop") }
            )
        }
        .padding()
    }
}
