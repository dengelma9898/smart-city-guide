import Foundation

enum FeatureFlags {
    static let quickRoutePlanningEnabled: Bool = true
    static let activeRouteBottomSheetEnabled: Bool = true
    
    // Phase 2: Parallel Route Performance Optimization
    static let parallelRouteGenerationEnabled: Bool = false // Temporarily disabled due to MapKit throttling
    static let routePerformanceLoggingEnabled: Bool = true
    
    // MapKit Rate Limiting Configuration
    static let mapKitSafeMode: Bool = true // Use conservative rate limits to avoid throttling
}


