import Foundation
import CoreLocation
import MapKit

// MARK: - Route Service Protocol

/// Protocol for route generation services to enable dependency injection and testing
@MainActor
protocol RouteServiceProtocol: ObservableObject {
    // Published properties for UI binding
    var isGenerating: Bool { get }
    var errorMessage: String? { get }
    var generatedRoute: GeneratedRoute? { get }
    
    // Route generation methods
    func generateRoute(
        startingCity: String,
        numberOfPlaces: Int,
        endpointOption: EndpointOption,
        customEndpoint: String,
        routeLength: RouteLength,
        availablePOIs: [POI]?
    ) async
    
    func generateRoute(
        fromCurrentLocation location: CLLocation,
        maximumStops: MaximumStops,
        endpointOption: EndpointOption,
        customEndpoint: String,
        maximumWalkingTime: MaximumWalkingTime,
        minimumPOIDistance: MinimumPOIDistance,
        availablePOIs: [POI]?
    ) async
    
    // Cache and state management
    func clearErrorMessage()
    func resetGeneratedRoute()
    
    // Wikipedia integration support
    func getDiscoveredPOIs() async -> [POI]?
}

// MARK: - Route History Protocol

/// Protocol for route history management to enable dependency injection and testing
protocol RouteHistoryManagerProtocol: ObservableObject {
    // Note: RouteHistory will be defined when implementing the actual manager
    // var routeHistory: [RouteHistory] { get }
    
    func saveRoute(_ route: GeneratedRoute, routeLength: RouteLength, endpointOption: EndpointOption)
    // func getHistory() -> [RouteHistory]
    func clearHistory()
    func deleteRoute(at index: Int)
}

// MARK: - Cache Manager Protocol

/// Protocol for cache management services
@MainActor
protocol CacheManagerProtocol: ObservableObject {
    var isLoading: Bool { get }
    var diskCacheStatistics: DiskCacheStatistics? { get }
    
    func loadFromDisk() async
    func saveToDisk() async
    func clearAllCaches() async
    func performMaintenace() async
    func getCacheStatistics() async -> CacheStatistics
}

// MARK: - Location Manager Protocol

/// Protocol for location services to enable dependency injection and testing
@MainActor
protocol LocationManagerProtocol: ObservableObject {
    var location: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var isAuthorized: Bool { get }
    var errorMessage: String? { get }
    
    func requestLocationPermission() async
    func requestLocationPermissionSync()
    func startLocationUpdates()
    func stopLocationUpdates()
}

// MARK: - POI Service Protocol

/// Protocol for POI discovery services
@MainActor
protocol POIServiceProtocol {
    func fetchPOIs(for cityName: String, categories: [PlaceCategory]) async throws -> [POI]
    func fetchPOIs(at coordinates: CLLocationCoordinate2D, cityName: String, categories: [PlaceCategory], radiusMeters: Double) async throws -> [POI]
}

// MARK: - Default Implementations
// Note: Conformance will be added gradually during migration

// MARK: - Mock Services for Testing

#if DEBUG

class MockRouteService: RouteServiceProtocol {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedRoute: GeneratedRoute?
    
    func generateRoute(
        startingCity: String,
        numberOfPlaces: Int,
        endpointOption: EndpointOption,
        customEndpoint: String,
        routeLength: RouteLength,
        availablePOIs: [POI]?
    ) async {
        isGenerating = true
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock successful route generation
        let mockWaypoints = [
            RoutePoint(name: "Start", coordinate: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767), address: "Startpunkt", category: .attraction),
            RoutePoint(name: "Mock POI 1", coordinate: CLLocationCoordinate2D(latitude: 49.4530, longitude: 11.0780), address: "Mock Museum", category: .museum),
            RoutePoint(name: "Mock POI 2", coordinate: CLLocationCoordinate2D(latitude: 49.4540, longitude: 11.0790), address: "Mock Park", category: .park)
        ]
        
        let mockRoute = GeneratedRoute(
            waypoints: mockWaypoints,
            routes: [], // Empty for mock
            totalDistance: 2500.0,
            totalTravelTime: 1800.0, // 30 minutes
            totalVisitTime: 3600.0, // 1 hour
            totalExperienceTime: 5400.0, // 1.5 hours
            endpointOption: endpointOption
        )
        
        generatedRoute = mockRoute
        isGenerating = false
    }
    
    func generateRoute(
        fromCurrentLocation location: CLLocation,
        maximumStops: MaximumStops,
        endpointOption: EndpointOption,
        customEndpoint: String,
        maximumWalkingTime: MaximumWalkingTime,
        minimumPOIDistance: MinimumPOIDistance,
        availablePOIs: [POI]?
    ) async {
        // Similar mock implementation
        await generateRoute(
            startingCity: "Mock City",
            numberOfPlaces: maximumStops.intValue,
            endpointOption: endpointOption,
            customEndpoint: customEndpoint,
            routeLength: .medium,
            availablePOIs: availablePOIs
        )
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func resetGeneratedRoute() {
        generatedRoute = nil
    }
    
    func getDiscoveredPOIs() async -> [POI]? {
        return nil
    }
}

class MockRouteHistoryManager: RouteHistoryManagerProtocol {
    private var savedRoutes: [GeneratedRoute] = []
    
    func saveRoute(_ route: GeneratedRoute, routeLength: RouteLength, endpointOption: EndpointOption) {
        savedRoutes.append(route)
    }
    
    func clearHistory() {
        savedRoutes.removeAll()
    }
    
    func deleteRoute(at index: Int) {
        guard index >= 0 && index < savedRoutes.count else { return }
        savedRoutes.remove(at: index)
    }
}

class MockLocationManager: LocationManagerProtocol {
    @Published var location: CLLocation? = CLLocation(latitude: 49.4521, longitude: 11.0767)
    @Published var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    @Published var errorMessage: String?
    
    var isAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    func requestLocationPermission() async {
        authorizationStatus = .authorizedWhenInUse
    }
    
    func requestLocationPermissionSync() {
        Task {
            await requestLocationPermission()
        }
    }
    
    func startLocationUpdates() {
        // Mock implementation
    }
    
    func stopLocationUpdates() {
        // Mock implementation
    }
}

#endif
