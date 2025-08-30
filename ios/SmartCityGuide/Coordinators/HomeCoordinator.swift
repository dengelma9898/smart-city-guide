import Foundation
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Route Optimization Errors
enum RouteOptimizationError: LocalizedError {
    case noActiveRoute
    case insufficientWaypoints
    case tspOptimizationFailed
    case networkError(Error)
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .noActiveRoute:
            return "Keine aktive Route gefunden"
        case .insufficientWaypoints:
            return "Nicht genügend Wegpunkte für Optimierung"
        case .tspOptimizationFailed:
            return "Route-Optimierung fehlgeschlagen"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Zu viele Optimierungsanfragen. Bitte warten Sie einen Moment."
        }
    }
}

/// Central coordinator for app-level state management and navigation
@MainActor
class HomeCoordinator: ObservableObject {
    
    // MARK: - Dependencies (Injected)
    internal let routeService: any RouteServiceProtocol
    private let historyManager: (any RouteHistoryManagerProtocol)?
    private let cacheManager: any CacheManagerProtocol
    private let locationManager: any LocationManagerProtocol
    internal let wikipediaService: RouteWikipediaService
    
    // MARK: - Published State
    @Published var activeRoute: GeneratedRoute?
    @Published var presentedSheet: SheetDestination?
    @Published var isGeneratingRoute = false
    @Published var errorMessage: String?
    @Published var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
    
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
        locationManager: any LocationManagerProtocol,
        wikipediaService: RouteWikipediaService? = nil
    ) {
        self.routeService = routeService
        self.historyManager = historyManager
        self.cacheManager = cacheManager
        self.locationManager = locationManager
        self.wikipediaService = wikipediaService ?? RouteWikipediaService()
        
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
        
        // Start Wikipedia enrichment in background
        startWikipediaEnrichment(for: route)
        
        // Save to history if manager is available
        historyManager?.saveRoute(route, routeLength: .medium, endpointOption: .roundtrip)
        
        // Transition: close planning sheet first so the map shows the route,
        // then present the single Active Route sheet after a brief delay
        presentedSheet = nil
        if FeatureFlags.activeRouteBottomSheetEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.presentedSheet = .activeRoute
            }
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
    
    // MARK: - Quick Planning State (Enhanced)
    @Published var quickPlanningMessage = "Wir basteln deine Route!"
    @Published var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
    
    // MARK: - POI Management State
    @Published var cachedPOIsForAlternatives: [POI] = []
    
    // MARK: - Route Success State
    @Published var showRouteSuccessView = false
    @Published var routeSuccessStats: RouteCompletionStats?
    
    // Note: POI modifications are applied immediately with route regeneration
    
    // MARK: - Service Access (Centralized)
    internal let routeService = RouteService()
    private let locationManager = LocationManagerService.shared
    private let geoapifyService = GeoapifyAPIService.shared
    private let tspService = RouteTSPService()
    private let cacheManager = CacheManager.shared
    internal let wikipediaService = RouteWikipediaService()
    
    // MARK: - Initialization
    init() {
        setupObservers()
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
    
    // MARK: - POI Management Methods
    
    /// Get cached POI alternatives for route editing
    func getCachedPOIAlternatives() -> [POI] {
        return cachedPOIsForAlternatives
    }
    
    /// Update cached POIs when route is generated
    func updateCachedPOIsForAlternatives(_ pois: [POI]) {
        cachedPOIsForAlternatives = pois
        SecureLogger.shared.logInfo("🗃️ HomeCoordinator: Updated cached POIs for alternatives - \(pois.count) POIs available", category: .ui)
    }
    
    /// Get POI alternatives for a specific location, excluding current route POIs
    func getPOIAlternatives(for originalPOI: RoutePoint, excludingRouteWaypoints: [RoutePoint]) -> [POI] {
        let routePOIIds = Set(excludingRouteWaypoints.compactMap { $0.poiId })
        
        // Filter cached POIs to exclude current route POIs and the original POI
        let availableAlternatives = cachedPOIsForAlternatives.filter { poi in
            // Exclude if it's already in the route
            if routePOIIds.contains(poi.id) {
                return false
            }
            
            // Exclude if it's the original POI (by name/location similarity)
            let distance = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
                .distance(from: CLLocation(latitude: originalPOI.coordinate.latitude, longitude: originalPOI.coordinate.longitude))
            
            return distance > 50 // Exclude if within 50 meters of original
        }
        
        // Sort by proximity to original location (maintain geographic coherence)
        let sortedAlternatives = availableAlternatives.sorted { poi1, poi2 in
            let distance1 = CLLocation(latitude: poi1.latitude, longitude: poi1.longitude)
                .distance(from: CLLocation(latitude: originalPOI.coordinate.latitude, longitude: originalPOI.coordinate.longitude))
            let distance2 = CLLocation(latitude: poi2.latitude, longitude: poi2.longitude)
                .distance(from: CLLocation(latitude: originalPOI.coordinate.latitude, longitude: originalPOI.coordinate.longitude))
            return distance1 < distance2
        }
        
        // Return top 15 alternatives for swipe card interface (increased from 5)
        let limitedAlternatives = Array(sortedAlternatives.prefix(15))
        
        SecureLogger.shared.logInfo("🔄 HomeCoordinator: Found \(limitedAlternatives.count) POI alternatives for '\(originalPOI.name)'", category: .ui)
        
        return limitedAlternatives
    }
    
    /// Delete a POI from the active route and immediately regenerate route
    func deletePOI(waypoint: RoutePoint, at index: Int) async -> Bool {
        guard let currentRoute = activeRoute else {
            SecureLogger.shared.logError("❌ HomeCoordinator: No active route for POI deletion", category: .ui)
            return false
        }
        
        // Validate deletion is safe
        let currentIntermediateWaypoints = currentRoute.waypoints.filter { wp in
            wp != currentRoute.waypoints.first && wp != currentRoute.waypoints.last
        }
        
        if currentIntermediateWaypoints.count <= 1 {
            SecureLogger.shared.logWarning("⚠️ HomeCoordinator: Cannot delete POI - would leave no intermediate stops", category: .ui)
            return false
        }
        
        // Immediately remove POI from active route
        var newWaypoints = currentRoute.waypoints
        newWaypoints.removeAll { wp in wp == waypoint }
        
        SecureLogger.shared.logInfo("🗑️ HomeCoordinator: POI '\(waypoint.name)' deleted, regenerating route...", category: .ui)
        
        // Immediately regenerate route with new waypoints
        do {
            let routeGenerationService = RouteGenerationService()
            
            // Optimize waypoint order first
            let optimizedWaypoints = tspService.optimizeWaypointOrder(newWaypoints)
            
            // Generate complete new route (preserve original endpoint option)
            let originalEndpointOption = activeRoute?.endpointOption ?? .roundtrip
            let newRoute = try await routeGenerationService.generateCompleteRoute(from: optimizedWaypoints, endpointOption: originalEndpointOption)
            
            // Update active route with regenerated route
            activeRoute = newRoute
            
            SecureLogger.shared.logInfo("✅ HomeCoordinator: Route regenerated after POI deletion", category: .ui)
            
            return true
            
        } catch {
            SecureLogger.shared.logError("❌ HomeCoordinator: Route regeneration failed after deletion: \(error.localizedDescription)", category: .ui)
            
            // Fallback: Keep the modified route without regeneration
            let fallbackRoute = GeneratedRoute(
                waypoints: newWaypoints,
                routes: currentRoute.routes,
                totalDistance: currentRoute.totalDistance,
                totalTravelTime: currentRoute.totalTravelTime,
                totalVisitTime: currentRoute.totalVisitTime,
                totalExperienceTime: currentRoute.totalExperienceTime,
                endpointOption: currentRoute.endpointOption
            )
            activeRoute = fallbackRoute
            
            return true
        }
    }
    
    /// Replace a POI in the active route and immediately regenerate route
    func replacePOI(original: RoutePoint, with alternative: POI) async -> Bool {
        guard let currentRoute = activeRoute else {
            SecureLogger.shared.logError("❌ HomeCoordinator: No active route for POI replacement", category: .ui)
            return false
        }
        
        // Find and replace the POI in waypoints
        var newWaypoints = currentRoute.waypoints
        if let index = newWaypoints.firstIndex(of: original) {
            let replacementWaypoint = RoutePoint(from: alternative)
            newWaypoints[index] = replacementWaypoint
            
            SecureLogger.shared.logInfo("🔄 HomeCoordinator: POI '\(original.name)' replaced with '\(alternative.name)', regenerating route...", category: .ui)
            
            // Immediately regenerate route with replaced waypoint
            do {
                let routeGenerationService = RouteGenerationService()
                
                // Optimize waypoint order first
                let optimizedWaypoints = tspService.optimizeWaypointOrder(newWaypoints)
                
                // Generate complete new route (preserve original endpoint option)
                let originalEndpointOption = activeRoute?.endpointOption ?? .roundtrip
                let newRoute = try await routeGenerationService.generateCompleteRoute(from: optimizedWaypoints, endpointOption: originalEndpointOption)
                
                // Update active route with regenerated route
                activeRoute = newRoute
                
                SecureLogger.shared.logInfo("✅ HomeCoordinator: Route regenerated after POI replacement", category: .ui)
                
                return true
                
            } catch {
                SecureLogger.shared.logError("❌ HomeCoordinator: Route regeneration failed after replacement: \(error.localizedDescription)", category: .ui)
                
                // Fallback: Keep the modified route without regeneration
                let fallbackRoute = GeneratedRoute(
                    waypoints: newWaypoints,
                    routes: currentRoute.routes,
                    totalDistance: currentRoute.totalDistance,
                    totalTravelTime: currentRoute.totalTravelTime,
                    totalVisitTime: currentRoute.totalVisitTime,
                    totalExperienceTime: currentRoute.totalExperienceTime,
                    endpointOption: currentRoute.endpointOption
                )
                activeRoute = fallbackRoute
                
                return true
            }
        } else {
            SecureLogger.shared.logError("❌ HomeCoordinator: Could not find original POI for replacement", category: .ui)
            return false
        }
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
        
        // Route completion notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteCompletion),
            name: .routeCompletionSuccess,
            object: nil
        )
    }
    
    private func initializeServices() {
        Task { @MainActor in
            // Permission requests now handled in intro flow
            // Only start location updates if already authorized
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
        
        // Start Wikipedia enrichment in background
        startWikipediaEnrichment(for: route)
        
        // Start proximity monitoring for POI notifications
        Task {
            await ProximityService.shared.startProximityMonitoring(for: route)
        }
        
        // Transition: close planning sheet first so the map shows the route,
        // then present the single Active Route sheet after a brief delay
        presentedSheet = nil
        if FeatureFlags.activeRouteBottomSheetEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.presentedSheet = .activeRoute
            }
        }
        
        SecureLogger.shared.logInfo("🗺️ Route generated and activated via BasicCoordinator", category: .ui)
    }
    
    func endActiveRoute() {
        // Stop proximity monitoring
        ProximityService.shared.stopProximityMonitoring()
        
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
    
    func startCustomPlanningAt(
        location: CLLocation,
        maximumStops: MaximumStops,
        endpointOption: EndpointOption,
        customEndpoint: String,
        maximumWalkingTime: MaximumWalkingTime,
        minimumPOIDistance: MinimumPOIDistance
    ) async {
        isGeneratingRoute = true
        self.quickPlanningMessage = "Entdecke coole Orte…"
        
        do {
            SecureLogger.shared.logInfo("🔍 HomeCoordinator: Fetching POIs for custom planning at \(location.coordinate)", category: .ui)
            
            // Fetch POIs using the coordinator's geoapify service
            let pois = try await geoapifyService.fetchPOIs(
                at: location.coordinate,
                cityName: "Mein Standort",
                categories: PlaceCategory.geoapifyEssentialCategories,
                radiusMeters: 5000
            )
            
            SecureLogger.shared.logInfo("✅ HomeCoordinator: Found \(pois.count) POIs for custom planning", category: .ui)
            
            self.quickPlanningMessage = "Optimiere deine Route…"
            
            // Use the centralized route service with custom parameters
            await routeService.generateRoute(
                fromCurrentLocation: location,
                maximumStops: maximumStops,
                endpointOption: endpointOption,
                customEndpoint: customEndpoint,
                maximumWalkingTime: maximumWalkingTime,
                minimumPOIDistance: minimumPOIDistance,
                availablePOIs: pois
            )
            
            // Explicitly handle the route result
            await MainActor.run {
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                if let generatedRoute = routeService.generatedRoute {
                    SecureLogger.shared.logInfo("🎉 HomeCoordinator: Custom route generated successfully with \(generatedRoute.waypoints.count) waypoints", category: .ui)
                    
                    // Store cached POIs for later alternatives
                    updateCachedPOIsForAlternatives(pois)
                    
                    handleRouteGenerated(generatedRoute)
                } else {
                    SecureLogger.shared.logWarning("⚠️ HomeCoordinator: Custom route generation completed but no route available", category: .ui)
                    errorMessage = routeService.errorMessage ?? "Route generation failed"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                SecureLogger.shared.logWarning("❌ HomeCoordinator Custom Planning failed: \(error.localizedDescription)", category: .ui)
            }
        }
    }
    
    func startCityPlanningFor(
        city: String,
        maximumStops: MaximumStops,
        endpointOption: EndpointOption,
        customEndpoint: String,
        maximumWalkingTime: MaximumWalkingTime,
        minimumPOIDistance: MinimumPOIDistance
    ) async {
        isGeneratingRoute = true
        self.quickPlanningMessage = "Suche POIs in \(city)…"
        
        do {
            SecureLogger.shared.logInfo("🔍 HomeCoordinator: Starting city planning for \(city)", category: .ui)
            
            self.quickPlanningMessage = "Optimiere deine Route…"
            
            // Convert route length from walking time  
            let routeLength: RouteLength = {
                switch maximumWalkingTime {
                case .thirtyMin: return .short
                case .fortyFiveMin: return .short
                case .sixtyMin: return .medium
                case .ninetyMin: return .long
                case .twoHours: return .long
                case .threeHours: return .long
                case .openEnd: return .long
                @unknown default: return .medium
                }
            }()
            
            // Fetch POIs for the city first to cache them for alternatives
            let cityPOIs = try await geoapifyService.fetchPOIs(
                for: city,
                categories: PlaceCategory.geoapifyEssentialCategories
            )
            
            SecureLogger.shared.logInfo("✅ HomeCoordinator: Found \(cityPOIs.count) POIs for city planning in \(city)", category: .ui)
            
            // Use the centralized route service for city-based planning
            await routeService.generateRoute(
                startingCity: city,
                numberOfPlaces: maximumStops.intValue,
                endpointOption: endpointOption,
                customEndpoint: customEndpoint,
                routeLength: routeLength,
                availablePOIs: cityPOIs
            )
            
            // Explicitly handle the route result
            await MainActor.run {
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                if let generatedRoute = routeService.generatedRoute {
                    SecureLogger.shared.logInfo("🎉 HomeCoordinator: City route generated successfully with \(generatedRoute.waypoints.count) waypoints", category: .ui)
                    
                    // Store cached POIs for later alternatives
                    updateCachedPOIsForAlternatives(cityPOIs)
                    
                    handleRouteGenerated(generatedRoute)
                } else {
                    SecureLogger.shared.logWarning("⚠️ HomeCoordinator: City route generation completed but no route available", category: .ui)
                    errorMessage = routeService.errorMessage ?? "Route generation failed"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                SecureLogger.shared.logWarning("❌ HomeCoordinator City Planning failed: \(error.localizedDescription)", category: .ui)
            }
        }
    }
    
    func startManualRouteFlow(route: GeneratedRoute) async {
        await MainActor.run {
            isGeneratingRoute = true
            self.quickPlanningMessage = "Route wird optimiert…"
        }
        
        // Brief delay to show the loading animation
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        await MainActor.run {
            isGeneratingRoute = false
            self.quickPlanningMessage = "Wir basteln deine Route!"
            SecureLogger.shared.logInfo("🎉 HomeCoordinator: Manual route activated with \(route.waypoints.count) waypoints", category: .ui)
            handleRouteGenerated(route)
        }
    }

    // MARK: - Manual Planning from Selection (Unified overlay on map)
    func startManualPlanningFromSelection(
        selectedPOIs: [POI],
        startCoordinate: CLLocationCoordinate2D,
        endpointOption: EndpointOption,
        customEndpoint: String,
        customEndpointCoordinates: CLLocationCoordinate2D?,
        discoveredPOIs: [POI],
        startingCity: String
    ) async {
        await MainActor.run {
            isGeneratingRoute = true
            self.quickPlanningMessage = "Erstelle deine Route…"
        }
        do {
            // Generate manual route using centralized route service
            let route = try await routeService.generateManualRoute(
                selectedPOIs: selectedPOIs,
                startLocation: startCoordinate,
                endpointOption: endpointOption,
                customEndpoint: customEndpoint,
                customEndpointCoordinates: customEndpointCoordinates
            )

            // Enrich and cache POIs for alternatives
            await wikipediaService.enrichRoute(route, from: discoveredPOIs, startingCity: startingCity)
            updateCachedPOIsForAlternatives(discoveredPOIs)

            await MainActor.run {
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                handleRouteGenerated(route)
            }
        } catch {
            await MainActor.run {
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                errorMessage = error.localizedDescription
                SecureLogger.shared.logWarning("❌ Manual planning failed: \(error.localizedDescription)", category: .ui)
            }
        }
    }
    
    func startQuickPlanningAt(location: CLLocation) async {
        isGeneratingRoute = true
        self.quickPlanningMessage = "Entdecke coole Orte…"
        
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
            
            self.quickPlanningMessage = "Optimiere deine Route…"
            
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
            
            // Explicitly handle the route result
            await MainActor.run {
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                if let generatedRoute = routeService.generatedRoute {
                    SecureLogger.shared.logInfo("🎉 HomeCoordinator: Route generated successfully with \(generatedRoute.waypoints.count) waypoints", category: .ui)
                    
                    // Store cached POIs for later alternatives
                    updateCachedPOIsForAlternatives(pois)
                    
                    handleRouteGenerated(generatedRoute)
                } else {
                    SecureLogger.shared.logWarning("⚠️ HomeCoordinator: Route generation completed but no route available", category: .ui)
                    errorMessage = routeService.errorMessage ?? "Route generation failed"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGeneratingRoute = false
                self.quickPlanningMessage = "Wir basteln deine Route!"
                SecureLogger.shared.logWarning("❌ HomeCoordinator Quick Planning failed: \(error.localizedDescription)", category: .ui)
            }
        }
    }
    
    @objc private func handleRouteCompletion(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statsData = userInfo["routeStats"] as? Data,
              let stats = try? JSONDecoder().decode(RouteCompletionStats.self, from: statsData) else {
            SecureLogger.shared.logError("❌ Failed to decode route completion stats", category: .ui)
            return
        }
        
        SecureLogger.shared.logInfo("🎉 Route completion received: \(stats.routeName)", category: .ui)
        showRouteCompletionSuccess(stats: stats)
    }
    
    // MARK: - Route Success Management
    
    /// Shows the route success view with completion statistics
    func showRouteCompletionSuccess(stats: RouteCompletionStats) {
        routeSuccessStats = stats
        showRouteSuccessView = true
        
        // Dismiss any active sheets for clean navigation
        dismissActiveSheets()
        
        // NOTE: Don't end active route immediately - RouteSuccessView needs access to it!
        // Active route will be ended when the success view is dismissed
        
        SecureLogger.shared.logInfo("🎉 Showing route completion success view for: \(stats.routeName)", category: .ui)
    }
    
    /// Dismisses the route success view and returns to map
    func dismissRouteSuccessView() {
        showRouteSuccessView = false
        routeSuccessStats = nil
        
        // Now end the active route to clean up map state
        endActiveRoute()
        
        // Focus on map after success view dismissal (route will be nil now)
        focusOnActiveRoute()
    }
    
    /// Dismisses any active sheets for clean navigation
    private func dismissActiveSheets() {
        presentedSheet = nil
    }
    
    /// Focuses the map on the active route (if any)
    private func focusOnActiveRoute() {
        guard let route = activeRoute else { return }
        
        // TODO: Implement map focus logic - will be added in Task 5
        // For now, just log that we would focus on the route
        SecureLogger.shared.logInfo("📍 Would focus map on route with \(route.waypoints.count) waypoints", category: .ui)
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
    static let poiNotificationSettingChanged = Notification.Name("poiNotificationSettingChanged")
    static let routeCompletionSuccess = Notification.Name("routeCompletionSuccess")
}

// MARK: - FeatureFlags Extension

extension FeatureFlags {
    /// Enable HomeCoordinator for centralized state management
    static let homeCoordinatorEnabled: Bool = true
    
    /// Enable dependency injection container
    static let dependencyInjectionEnabled: Bool = true
}
