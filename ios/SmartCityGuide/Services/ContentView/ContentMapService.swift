import Foundation
import SwiftUI
import MapKit
import CoreLocation
import os.log

/// Service for managing map camera positioning and location-based operations
@MainActor
class ContentMapService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "ContentMap")
    
    // Track if we're currently showing a route to prevent location interference
    private var isShowingRoute = false
    
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.4500, longitude: 11.0760), // Nuremberg default (closer to user)
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    // MARK: - Public Interface
    
    /// Adjust camera to show the entire route
    /// - Parameter route: The route to display
    func adjustCamera(to route: GeneratedRoute) {
        guard let firstWaypoint = route.waypoints.first else {
            logger.warning("Cannot adjust camera: route has no waypoints")
            return
        }
        
        // Mark that we're showing a route
        isShowingRoute = true
        
        let coordinates = route.waypoints.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? firstWaypoint.coordinate.latitude
        let maxLat = coordinates.map { $0.latitude }.max() ?? firstWaypoint.coordinate.latitude
        let minLon = coordinates.map { $0.longitude }.min() ?? firstWaypoint.coordinate.longitude
        let maxLon = coordinates.map { $0.longitude }.max() ?? firstWaypoint.coordinate.longitude
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.005, (maxLat - minLat) * 1.3),
            longitudeDelta: max(0.005, (maxLon - minLon) * 1.3)
        )
        
        logger.info("🗺️ Adjusting camera to show route with \(route.waypoints.count) waypoints")
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = MapCameraPosition.region(
                MKCoordinateRegion(center: center, span: span)
            )
        }
    }
    
    /// Center camera on user's current location
    /// - Parameter location: User's current location
    func centerOnUserLocation(_ location: CLLocation) {
        // Don't interfere if we're currently showing a route
        if isShowingRoute {
            logger.info("🗺️ Skipping user location centering - route is active")
            return
        }
        
        logger.info("🗺️ Centering camera on user location")
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
    
    /// Clear route state (called when route ends)
    func clearRouteState() {
        logger.info("🗺️ Clearing route state")
        isShowingRoute = false
    }
    
    /// Set camera to a specific coordinate with custom zoom
    /// - Parameters:
    ///   - coordinate: Target coordinate
    ///   - span: Map span for zoom level
    ///   - animated: Whether to animate the transition
    func setCameraPosition(
        to coordinate: CLLocationCoordinate2D,
        span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01),
        animated: Bool = true
    ) {
        logger.debug("🗺️ Setting camera position to \(coordinate.latitude), \(coordinate.longitude)")
        
        let newPosition = MapCameraPosition.region(
            MKCoordinateRegion(center: coordinate, span: span)
        )
        
        if animated {
            withAnimation(.easeInOut(duration: 0.8)) {
                cameraPosition = newPosition
            }
        } else {
            cameraPosition = newPosition
        }
    }
    
    /// Reset camera to default position (Berlin)
    func resetToDefaultPosition() {
        logger.info("🗺️ Resetting camera to default position (Berlin)")
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
    
    /// Get current map center coordinate
    /// - Returns: Current center coordinate of the map
    func getCurrentCenter() -> CLLocationCoordinate2D? {
        // Simple implementation for now - just return Berlin default
        return CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
    }
    
    /// Calculate appropriate span for multiple coordinates
    /// - Parameter coordinates: Array of coordinates to include
    /// - Returns: Span that includes all coordinates with padding
    func calculateSpan(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        guard !coordinates.isEmpty else {
            return MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let latDelta = max(0.005, (maxLat - minLat) * 1.3)
        let lonDelta = max(0.005, (maxLon - minLon) * 1.3)
        
        return MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    }
}
