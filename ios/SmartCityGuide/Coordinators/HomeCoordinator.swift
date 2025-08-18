import Foundation
import SwiftUI
import CoreLocation
import MapKit

/// Central coordinator for app-level state management and navigation
@MainActor
class HomeCoordinator: ObservableObject {
    
    // MARK: - Dependencies (Injected)
    private let routeService: RouteServiceProtocol
    private let historyManager: RouteHistoryManagerProtocol?
    private let cacheManager: CacheManagerProtocol
    private let locationManager: LocationManagerProtocol
    
    // MARK: - Published State
    @Published var activeRoute: GeneratedRoute?
    @Published var presentedSheet: SheetDestination?
    @Published var isGeneratingRoute = false
    @Published var errorMessage: String?
    
    // MARK: - Quick Planning State
    @Published var quickPlanningLocation: CLLocation?
    @Published var showingQuickPlanning = false
    
    // MARK: - Location State
    @Published var currentLocation: CLLocation?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Map State
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767), // Nuremberg default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // MARK: - Initialization
    init(
        routeService: RouteServiceProtocol,
        historyManager: RouteHistoryManagerProtocol? = nil,
        cacheManager: CacheManagerProtocol = CacheManager.shared,
        locationManager: LocationManagerProtocol
    ) {
        self.routeService = routeService
        self.historyManager = historyManager
        self.cacheManager = cacheManager
        self.locationManager = locationManager
        
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe route service state
        NotificationCenter.default.addObserver(
            forName: .routeServiceStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFromRouteService()
        }
        
        // Observe location updates
        NotificationCenter.default.addObserver(
            forName: .locationManagerDidUpdateLocation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocation {
                self?.currentLocation = location
            }
        }
    }
    
    func setupInitialState() {
        locationManager.requestLocationPermission()
        locationManager.startLocationUpdates()
        
        Task {
            await cacheManager.loadFromDisk()
        }
    }
    
    private func updateFromRouteService() {
        isGeneratingRoute = routeService.isGenerating
        errorMessage = routeService.errorMessage
        
        // Handle route generation completion
        if let newRoute = routeService.generatedRoute, newRoute != activeRoute {
            handleRouteGenerated(newRoute)
        }
    }
    
    // MARK: - Route Management
    
    func generateRoute(
        startingCity: String,
        numberOfPlaces: Int,
        endpointOption: EndpointOption,
        customEndpoint: String,
        routeLength: RouteLength,
        availablePOIs: [POI]?
    ) async {
        await routeService.generateRoute(
            startingCity: startingCity,
            numberOfPlaces: numberOfPlaces,
            endpointOption: endpointOption,
            customEndpoint: customEndpoint,
            routeLength: routeLength,
            availablePOIs: availablePOIs
        )
    }
    
    func generateRouteFromCurrentLocation(
        maximumStops: MaximumStops,
        endpointOption: EndpointOption,
        customEndpoint: String,
        maximumWalkingTime: MaximumWalkingTime,
        minimumPOIDistance: MinimumPOIDistance,
        availablePOIs: [POI]?
    ) async {
        guard let location = currentLocation else {
            errorMessage = "Standort nicht verfügbar. Bitte aktiviere die Standortberechtigung."
            return
        }
        
        await routeService.generateRoute(
            fromCurrentLocation: location,
            maximumStops: maximumStops,
            endpointOption: endpointOption,
            customEndpoint: customEndpoint,
            maximumWalkingTime: maximumWalkingTime,
            minimumPOIDistance: minimumPOIDistance,
            availablePOIs: availablePOIs
        )
    }
    
    func handleRouteGenerated(_ route: GeneratedRoute) {
        activeRoute = route
        adjustCameraToRoute(route)
        
        // Save to history if manager is available
        historyManager?.saveRoute(route, routeLength: .medium, endpointOption: .roundtrip)
        
        // Automatically show active route if feature enabled
        if FeatureFlags.activeRouteBottomSheetEnabled {
            presentedSheet = .activeRoute
        } else {
            presentedSheet = nil
        }
        
        SecureLogger.shared.logInfo("🗺️ Route generated and activated via Coordinator", category: .ui)
    }
    
    func endActiveRoute() {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeRoute = nil
            presentedSheet = nil
        }
        SecureLogger.shared.logInfo("🗺️ Active route ended via Coordinator", category: .ui)
    }
    
    private func adjustCameraToRoute(_ route: GeneratedRoute) {
        guard !route.waypoints.isEmpty else { return }
        
        let coordinates = route.waypoints.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.005, (maxLat - minLat) * 1.2),
            longitudeDelta: max(0.005, (maxLon - minLon) * 1.2)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    // MARK: - Sheet Management
    
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
        SecureLogger.shared.logInfo("🗺️ Sheet presented: \(destination)", category: .ui)
    }
    
    func dismissSheet() {
        presentedSheet = nil
        SecureLogger.shared.logInfo("🗺️ Sheet dismissed via Coordinator", category: .ui)
    }
    
    func showRoutePlanningSheet(mode: RoutePlanningMode? = nil) {
        presentSheet(.planning(mode: mode))
    }
    
    func showActiveRouteSheet() {
        if activeRoute != nil && FeatureFlags.activeRouteBottomSheetEnabled {
            presentSheet(.activeRoute)
        }
    }
    
    // MARK: - Quick Planning
    
    func triggerQuickPlanning(location: CLLocation) {
        quickPlanningLocation = location
        showingQuickPlanning = true
        SecureLogger.shared.logInfo("🗺️ Quick planning triggered via Coordinator", category: .ui)
    }
    
    func handleQuickPlanningCompletion() {
        showingQuickPlanning = false
        quickPlanningLocation = nil
    }
    
    // MARK: - Error Management
    
    func clearErrorMessage() {
        errorMessage = nil
        routeService.clearErrorMessage()
    }
    
    func handleError(_ error: Error, context: String) {
        let userFriendlyMessage = generateUserFriendlyErrorMessage(error, context: context)
        errorMessage = userFriendlyMessage
        
        SecureLogger.shared.logError("🚨 Error handled by Coordinator: \(error.localizedDescription) (context: \(context))", category: .ui)
    }
    
    private func generateUserFriendlyErrorMessage(_ error: Error, context: String) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        switch context {
        case "route_generation":
            if errorString.contains("internet") || errorString.contains("network") {
                return "Keine Internetverbindung verfügbar. Prüfe deine Netzwerkeinstellungen!"
            } else if errorString.contains("location") || errorString.contains("standort") {
                return "Standort konnte nicht ermittelt werden. Aktiviere die Standortberechtigung in den Einstellungen."
            } else {
                return "Route konnte nicht erstellt werden. Versuch es mit einer anderen Stadt!"
            }
        case "location_access":
            return "Standortzugriff erforderlich. Bitte erlaube den Zugriff in den Einstellungen."
        case "cache_operation":
            return "Zwischenspeicher-Fehler aufgetreten. Die App funktioniert weiterhin normal."
        default:
            return "Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es erneut!"
        }
    }
    
    // MARK: - Location Updates
    
    func updateLocation(_ location: CLLocation) {
        currentLocation = location
        
        // Update map region if no active route
        if activeRoute == nil {
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            withAnimation(.easeInOut(duration: 0.5)) {
                mapRegion = newRegion
            }
        }
    }
    
    // MARK: - Cache Management
    
    func getCacheStatistics() async -> CacheStatistics {
        return await cacheManager.getCacheStatistics()
    }
    
    func clearAllCaches() async {
        await cacheManager.clearAllCaches()
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SheetDestination

enum SheetDestination: Identifiable {
    case planning(mode: RoutePlanningMode? = nil)
    case activeRoute
    
    var id: String {
        switch self {
        case .planning: return "planning"
        case .activeRoute: return "activeRoute"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let routeServiceStateChanged = Notification.Name("routeServiceStateChanged")
    static let locationManagerDidUpdateLocation = Notification.Name("locationManagerDidUpdateLocation")
}

// MARK: - FeatureFlags Extension

extension FeatureFlags {
    /// Enable HomeCoordinator for centralized state management
    static let homeCoordinatorEnabled: Bool = true
    
    /// Enable dependency injection container
    static let dependencyInjectionEnabled: Bool = true
}
