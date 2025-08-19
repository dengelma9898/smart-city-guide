import SwiftUI
import CoreLocation
import MapKit

/// Central app coordinator for unified state management and navigation flow
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Shared Services (Singletons)
    private let routeService = RouteService()
    private let locationService = LocationManagerService.shared
    private let geoapifyService = GeoapifyAPIService.shared
    private let wikipediaService = WikipediaService.shared
    private let profileSettings = ProfileSettingsManager.shared
    private let cacheManager = CacheManager.shared
    
    // MARK: - Published App State
    
    // Navigation State
    @Published var activeSheet: AppSheet?
    @Published var navigationPath = NavigationPath()
    
    // Route State
    @Published var activeRoute: GeneratedRoute?
    @Published var isGeneratingRoute = false
    @Published var routeError: String?
    
    // Location State
    @Published var currentLocation: CLLocation?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767), // Nuremberg
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // UI State
    @Published var isQuickPlanning = false
    @Published var quickPlanningMessage = "Wir basteln deine Route!"
    @Published var showingLocationPermissionAlert = false
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        initializeServices()
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
                self?.handleLocationUpdate(location)
            }
        }
        
        // Route service updates
        NotificationCenter.default.addObserver(
            forName: .routeServiceStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateFromRouteService()
        }
    }
    
    private func initializeServices() {
        Task {
            await locationService.requestLocationPermission()
            locationService.startLocationUpdates()
            await cacheManager.loadFromDisk()
        }
    }
    
    // MARK: - Service Access (Dependency Injection)
    
    func getRouteService() -> RouteService {
        return routeService
    }
    
    func getLocationService() -> LocationManagerService {
        return locationService
    }
    
    func getGeoapifyService() -> GeoapifyAPIService {
        return geoapifyService
    }
    
    func getWikipediaService() -> WikipediaService {
        return wikipediaService
    }
    
    func getProfileSettings() -> ProfileSettingsManager {
        return profileSettings
    }
    
    func getCacheManager() -> CacheManager {
        return cacheManager
    }
    
    // MARK: - Navigation Management
    
    func presentSheet(_ sheet: AppSheet) {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeSheet = sheet
        }
        SecureLogger.shared.logInfo("📱 Sheet presented: \(sheet)", category: .ui)
    }
    
    func dismissSheet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeSheet = nil
        }
        SecureLogger.shared.logInfo("📱 Sheet dismissed", category: .ui)
    }
    
    func pushView<T: Hashable>(_ destination: T) {
        navigationPath.append(destination)
        SecureLogger.shared.logInfo("📱 Navigation push: \(destination)", category: .ui)
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
        SecureLogger.shared.logInfo("📱 Navigation pop to root", category: .ui)
    }
    
    // MARK: - Route Management
    
    func startQuickPlanningAt(location: CLLocation) {
        isQuickPlanning = true
        quickPlanningMessage = "Wir entdecken coole Orte..."
        
        Task {
            do {
                let route = try await routeService.generateRouteNearLocation(location)
                await MainActor.run {
                    handleRouteGenerated(route)
                    isQuickPlanning = false
                }
            } catch {
                await MainActor.run {
                    routeError = error.localizedDescription
                    isQuickPlanning = false
                }
            }
        }
    }
    
    func handleRouteGenerated(_ route: GeneratedRoute) {
        withAnimation(.easeInOut(duration: 0.5)) {
            activeRoute = route
            
            // Auto-present active route if enabled
            if FeatureFlags.activeRouteBottomSheetEnabled {
                activeSheet = .activeRoute
            }
        }
        
        SecureLogger.shared.logInfo("🗺️ Route activated with \(route.waypoints.count) waypoints", category: .route)
    }
    
    func endActiveRoute() {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeRoute = nil
            if activeSheet == .activeRoute {
                activeSheet = nil
            }
        }
        SecureLogger.shared.logInfo("🗺️ Active route ended", category: .route)
    }
    
    // MARK: - Location Management
    
    private func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location
        
        // Update map region if needed
        let distance = location.distance(from: CLLocation(
            latitude: mapRegion.center.latitude,
            longitude: mapRegion.center.longitude
        ))
        
        if distance > 1000 { // Update if moved more than 1km
            withAnimation(.easeInOut(duration: 0.5)) {
                mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
    
    func centerMapOnUserLocation() {
        guard let location = currentLocation else {
            showingLocationPermissionAlert = true
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Error Management
    
    func clearError() {
        routeError = nil
    }
    
    // MARK: - Private Helpers
    
    private func updateFromRouteService() {
        isGeneratingRoute = routeService.isGenerating
        
        if let error = routeService.errorMessage {
            routeError = error
        }
        
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - App Sheet Destinations

enum AppSheet: String, Identifiable, CaseIterable {
    case routePlanning = "routePlanning"
    case activeRoute = "activeRoute"
    case profile = "profile"
    case help = "help"
    
    var id: String { rawValue }
}

// MARK: - App Navigation Destinations

enum AppDestination: Hashable {
    case profile
    case routeHistory
    case settings
    case help
    case routeBuilder(route: GeneratedRoute)
}
