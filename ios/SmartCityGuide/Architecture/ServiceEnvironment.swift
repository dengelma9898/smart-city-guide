import SwiftUI
import Foundation

// MARK: - Service Environment Keys

/// Environment key for accessing the app coordinator
struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: BasicHomeCoordinator? = nil
}

/// Environment key for accessing route service
struct RouteServiceKey: EnvironmentKey {
    static let defaultValue: RouteService? = nil
}

/// Environment key for accessing location service
struct LocationServiceKey: EnvironmentKey {
    static let defaultValue: LocationManagerService? = nil
}

/// Environment key for accessing geoapify service
struct GeoapifyServiceKey: EnvironmentKey {
    static let defaultValue: GeoapifyAPIService? = nil
}

/// Environment key for accessing cache manager
struct CacheManagerKey: EnvironmentKey {
    static let defaultValue: CacheManager? = nil
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    
    /// Access the app coordinator from the environment
    var appCoordinator: BasicHomeCoordinator? {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
    
    /// Access the route service from the environment
    var routeService: RouteService? {
        get { self[RouteServiceKey.self] }
        set { self[RouteServiceKey.self] = newValue }
    }
    
    /// Access the location service from the environment
    var locationService: LocationManagerService? {
        get { self[LocationServiceKey.self] }
        set { self[LocationServiceKey.self] = newValue }
    }
    
    /// Access the geoapify service from the environment
    var geoapifyService: GeoapifyAPIService? {
        get { self[GeoapifyServiceKey.self] }
        set { self[GeoapifyServiceKey.self] = newValue }
    }
    
    /// Access the cache manager from the environment
    var cacheManager: CacheManager? {
        get { self[CacheManagerKey.self] }
        set { self[CacheManagerKey.self] = newValue }
    }
}

// MARK: - Service Provider Modifier

/// View modifier that provides all services to the environment
struct ServiceEnvironmentModifier: ViewModifier {
    let coordinator: BasicHomeCoordinator
    
    func body(content: Content) -> some View {
        content
            .environment(\.appCoordinator, coordinator)
            .environment(\.routeService, coordinator.getRouteService())
            .environment(\.locationService, coordinator.getLocationService())
            .environment(\.geoapifyService, coordinator.getGeoapifyService())
            .environment(\.cacheManager, coordinator.getCacheManager())
    }
}

// MARK: - Convenience Extension

extension View {
    /// Provides all services to the view hierarchy via environment
    func withServiceEnvironment(_ coordinator: BasicHomeCoordinator) -> some View {
        modifier(ServiceEnvironmentModifier(coordinator: coordinator))
    }
}
