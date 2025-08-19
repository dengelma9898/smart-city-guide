import SwiftUI
import MapKit

/// Main map view component for ContentView
struct ContentMapView: View {
    
    @Binding var cameraPosition: MapCameraPosition
    @ObservedObject var locationService: LocationManagerService
    let activeRoute: GeneratedRoute?
    
    var body: some View {
        Map(position: $cameraPosition) {
            // User location marker
            if locationService.currentLocation != nil {
                UserAnnotation()
            }
            
            // Active route display
            if let route = activeRoute {
                // Route polylines
                ForEach(Array(route.routes.enumerated()), id: \.offset) { _, mkRoute in
                    MapPolyline(mkRoute)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
                
                // Route waypoint markers
                ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                    Marker(
                        waypoint.name,
                        coordinate: waypoint.coordinate
                    )
                    .tint(waypointColor(for: index, total: route.waypoints.count, category: waypoint.category))
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Methods
    
    /// Get appropriate color for waypoint marker
    private func waypointColor(for index: Int, total: Int, category: PlaceCategory) -> Color {
        if index == 0 {
            return .green // Start point
        } else if index == total - 1 {
            return .red // End point
        } else {
            return category.color // Category-based color for intermediate points
        }
    }
}

#Preview {
    @Previewable @State var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    ContentMapView(
        cameraPosition: $cameraPosition,
        locationService: LocationManagerService.shared,
        activeRoute: nil
    )
}
