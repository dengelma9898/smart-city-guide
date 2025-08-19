import Foundation
import SwiftUI
import CoreLocation
import MapKit

/// Central coordinator for app-level state management and navigation
@MainActor
class HomeCoordinator: ObservableObject {
    
    // MARK: - Dependencies (Injected)
    private let routeService: any RouteServiceProtocol
    private let historyManager: (any RouteHistoryManagerProtocol)?
    private let cacheManager: any CacheManagerProtocol
    private let locationManager: any LocationManagerProtocol
    
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
        routeService: any RouteServiceProtocol,
        historyManager: (any RouteHistoryManagerProtocol)? = nil,
        cacheManager: any CacheManagerProtocol,
        locationManager: any LocationManagerProtocol
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
            Task { @MainActor in
                self?.updateFromRouteService()
            }
        }
        
        // Observe location updates
        NotificationCenter.default.addObserver(
            forName: .locationManagerDidUpdateLocation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocation {
                Task { @MainActor in
                    self?.currentLocation = location
                }
            }
        }
    }
    
    func setupInitialState() {
        Task {
            await locationManager.requestLocationPermission()
            locationManager.startLocationUpdates()
            await cacheManager.loadFromDisk()
        }
    }
    
    private func updateFromRouteService() {
        isGeneratingRoute = routeService.isGenerating
        errorMessage = routeService.errorMessage
        
        // Handle route generation completion
        if let newRoute = routeService.generatedRoute {
            // Simple check: if activeRoute is nil or different waypoint count, handle as new route
            let shouldUpdate = activeRoute == nil || 
                             activeRoute!.waypoints.count != newRoute.waypoints.count ||
                             activeRoute!.totalDistance != newRoute.totalDistance
            
            if shouldUpdate {
                handleRouteGenerated(newRoute)
            }
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

// MARK: - Basic Home Coordinator (Simplified)

/// Enhanced coordinator with incremental state management improvements
@MainActor
class BasicHomeCoordinator: ObservableObject {
    
    // MARK: - Published State
    @Published var activeRoute: GeneratedRoute?
    @Published var presentedSheet: SheetDestination?
    @Published var isGeneratingRoute = false
    @Published var errorMessage: String?
    
    // MARK: - Navigation State (Enhanced)
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Location State (Enhanced)
    @Published var currentLocation: CLLocation?
    @Published var showingLocationPermissionAlert = false
    
    // MARK: - Service Access (Centralized)
    private let routeService = RouteService()
    private let locationManager = LocationManagerService.shared
    private let geoapifyService = GeoapifyAPIService.shared
    private let cacheManager = CacheManager.shared
    
    init() {
        setupObservers()
        initializeServices()
    }
    
    // MARK: - Service Access Methods
    
    func getRouteService() -> RouteService {
        return routeService
    }
    
    func getLocationService() -> LocationManagerService {
        return locationManager
    }
    
    func getGeoapifyService() -> GeoapifyAPIService {
        return geoapifyService
    }
    
    func getCacheManager() -> CacheManager {
        return cacheManager
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Location updates
        NotificationCenter.default.addObserver(
            forName: .locationManagerDidUpdateLocation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocation {
                Task { @MainActor in
                    self?.currentLocation = location
                }
            }
        }
        
        // Route service updates
        NotificationCenter.default.addObserver(
            forName: .routeServiceStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFromRouteService()
            }
        }
    }
    
    private func initializeServices() {
        Task { @MainActor in
            // Check authorization status first
            if locationManager.authorizationStatus == .notDetermined {
                await locationManager.requestLocationPermission()
            }
            
            // Start location updates if authorized
            if locationManager.isLocationAuthorized {
                locationManager.startLocationUpdates()
            }
            
            await cacheManager.loadFromDisk()
        }
    }
    
    private func updateFromRouteService() {
        isGeneratingRoute = routeService.isGenerating
        errorMessage = routeService.errorMessage
        
        if let newRoute = routeService.generatedRoute {
            // Only update if it's actually a different route
            let shouldUpdate = activeRoute == nil || 
                             activeRoute!.waypoints.count != newRoute.waypoints.count ||
                             activeRoute!.totalDistance != newRoute.totalDistance
            
            if shouldUpdate {
                handleRouteGenerated(newRoute)
            }
        }
    }
    
    // MARK: - Route Management
    
    func handleRouteGenerated(_ route: GeneratedRoute) {
        activeRoute = route
        
        // Automatically show active route if feature enabled
        if FeatureFlags.activeRouteBottomSheetEnabled {
            presentedSheet = .activeRoute
        } else {
            presentedSheet = nil
        }
        
        SecureLogger.shared.logInfo("🗺️ Route generated and activated via BasicCoordinator", category: .ui)
    }
    
    func endActiveRoute() {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeRoute = nil
            presentedSheet = nil
        }
        SecureLogger.shared.logInfo("🗺️ Active route ended via BasicCoordinator", category: .ui)
    }
    
    // MARK: - Sheet Management (Enhanced)
    
    func presentSheet(_ destination: SheetDestination) {
        withAnimation(.easeInOut(duration: 0.3)) {
            presentedSheet = destination
        }
        SecureLogger.shared.logInfo("🗺️ Sheet presented: \(destination)", category: .ui)
    }
    
    func dismissSheet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            presentedSheet = nil
        }
        SecureLogger.shared.logInfo("🗺️ Sheet dismissed via BasicCoordinator", category: .ui)
    }
    
    // MARK: - Navigation Management (Enhanced)
    
    func pushView<T: Hashable>(_ destination: T) {
        navigationPath.append(destination)
        SecureLogger.shared.logInfo("📱 Navigation push: \(destination)", category: .ui)
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
        SecureLogger.shared.logInfo("📱 Navigation pop to root", category: .ui)
    }
    
    // MARK: - Location Management (Enhanced)
    
    func centerMapOnUserLocation() {
        guard currentLocation != nil else {
            showingLocationPermissionAlert = true
            return
        }
        // Map centering will be handled by ContentMapService via binding
        SecureLogger.shared.logInfo("🗺️ Map centered on user location", category: .ui)
    }
    
    // MARK: - Quick Planning (Enhanced)
    
    func startQuickPlanningAt(location: CLLocation) async {
        isGeneratingRoute = true
        
        do {
            SecureLogger.shared.logInfo("🔍 HomeCoordinator: Fetching POIs for quick planning at \(location.coordinate)", category: .ui)
            
            // Fetch POIs using the coordinator's geoapify service
            let pois = try await geoapifyService.fetchPOIs(
                at: location.coordinate,
                cityName: "Mein Standort",
                categories: PlaceCategory.geoapifyEssentialCategories,
                radiusMeters: 2000
            )
            
            SecureLogger.shared.logInfo("✅ HomeCoordinator: Found \(pois.count) POIs for quick planning", category: .ui)
            
            // Use the centralized route service with POIs
            await routeService.generateRoute(
                fromCurrentLocation: location,
                maximumStops: .eight,
                endpointOption: .roundtrip,
                customEndpoint: "",
                maximumWalkingTime: .openEnd,
                minimumPOIDistance: .noMinimum,
                availablePOIs: pois
            )
            // Result will be handled by updateFromRouteService()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGeneratingRoute = false
                SecureLogger.shared.logWarning("❌ HomeCoordinator Quick Planning failed: \(error.localizedDescription)", category: .ui)
            }
        }
    }
    
    // MARK: - Error Management (Enhanced)
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
