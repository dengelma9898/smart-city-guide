import SwiftUI

/// Centralized environment system for dependency injection across the app
struct AppEnvironment {
    
    // MARK: - Environment Keys
    
    private struct AppCoordinatorKey: EnvironmentKey {
        static let defaultValue: AppCoordinator? = nil
    }
    
    private struct RouteServiceKey: EnvironmentKey {
        static let defaultValue: RouteService? = nil
    }
    
    private struct LocationServiceKey: EnvironmentKey {
        static let defaultValue: LocationManagerService? = nil
    }
    
    private struct GeoapifyServiceKey: EnvironmentKey {
        static let defaultValue: GeoapifyAPIService? = nil
    }
    
    private struct WikipediaServiceKey: EnvironmentKey {
        static let defaultValue: WikipediaService? = nil
    }
    
    private struct ProfileSettingsKey: EnvironmentKey {
        static let defaultValue: ProfileSettingsManager? = nil
    }
    
    private struct CacheManagerKey: EnvironmentKey {
        static let defaultValue: CacheManager? = nil
    }
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    
    var appCoordinator: AppCoordinator? {
        get { self[AppEnvironment.AppCoordinatorKey.self] }
        set { self[AppEnvironment.AppCoordinatorKey.self] = newValue }
    }
    
    var routeService: RouteService? {
        get { self[AppEnvironment.RouteServiceKey.self] }
        set { self[AppEnvironment.RouteServiceKey.self] = newValue }
    }
    
    var locationService: LocationManagerService? {
        get { self[AppEnvironment.LocationServiceKey.self] }
        set { self[AppEnvironment.LocationServiceKey.self] = newValue }
    }
    
    var geoapifyService: GeoapifyAPIService? {
        get { self[AppEnvironment.GeoapifyServiceKey.self] }
        set { self[AppEnvironment.GeoapifyServiceKey.self] = newValue }
    }
    
    var wikipediaService: WikipediaService? {
        get { self[AppEnvironment.WikipediaServiceKey.self] }
        set { self[AppEnvironment.WikipediaServiceKey.self] = newValue }
    }
    
    var profileSettings: ProfileSettingsManager? {
        get { self[AppEnvironment.ProfileSettingsKey.self] }
        set { self[AppEnvironment.ProfileSettingsKey.self] = newValue }
    }
    
    var cacheManager: CacheManager? {
        get { self[AppEnvironment.CacheManagerKey.self] }
        set { self[AppEnvironment.CacheManagerKey.self] = newValue }
    }
}

// MARK: - Environment Injection Modifiers

extension View {
    
    /// Inject the AppCoordinator and all its services into the environment
    func withAppEnvironment(_ coordinator: AppCoordinator) -> some View {
        self
            .environmentObject(coordinator)
            .environment(\.appCoordinator, coordinator)
            .environment(\.routeService, coordinator.getRouteService())
            .environment(\.locationService, coordinator.getLocationService())
            .environment(\.geoapifyService, coordinator.getGeoapifyService())
            .environment(\.wikipediaService, coordinator.getWikipediaService())
            .environment(\.profileSettings, coordinator.getProfileSettings())
            .environment(\.cacheManager, coordinator.getCacheManager())
    }
    
    /// Legacy support for individual service injection
    func withServices(
        route: RouteService? = nil,
        location: LocationManagerService? = nil,
        geoapify: GeoapifyAPIService? = nil,
        wikipedia: WikipediaService? = nil,
        profile: ProfileSettingsManager? = nil,
        cache: CacheManager? = nil
    ) -> some View {
        self
            .environment(\.routeService, route)
            .environment(\.locationService, location)
            .environment(\.geoapifyService, geoapify)
            .environment(\.wikipediaService, wikipedia)
            .environment(\.profileSettings, profile)
            .environment(\.cacheManager, cache)
    }
}

// MARK: - Service Access Helpers

extension View {
    
    /// Safe access to route service with fallback
    func withRouteService<Content: View>(
        @ViewBuilder content: @escaping (RouteService) -> Content
    ) -> some View {
        Group {
            if let service = Environment(\.routeService).wrappedValue {
                content(service)
            } else {
                // Fallback: Create local service (for migration period)
                content(RouteService())
            }
        }
    }
    
    /// Safe access to location service with fallback
    func withLocationService<Content: View>(
        @ViewBuilder content: @escaping (LocationManagerService) -> Content
    ) -> some View {
        Group {
            if let service = Environment(\.locationService).wrappedValue {
                content(service)
            } else {
                // Fallback: Use shared instance
                content(LocationManagerService.shared)
            }
        }
    }
    
    /// Safe access to geoapify service with fallback
    func withGeoapifyService<Content: View>(
        @ViewBuilder content: @escaping (GeoapifyAPIService) -> Content
    ) -> some View {
        Group {
            if let service = Environment(\.geoapifyService).wrappedValue {
                content(service)
            } else {
                // Fallback: Use shared instance
                content(GeoapifyAPIService.shared)
            }
        }
    }
}
