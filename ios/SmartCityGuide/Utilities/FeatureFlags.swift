import Foundation

enum FeatureFlags {
    static let quickRoutePlanningEnabled: Bool = true
    static let activeRouteBottomSheetEnabled: Bool = true
    
    // Phase 2: Parallel Route Performance Optimization
    static let parallelRouteGenerationEnabled: Bool = true
    static let routePerformanceLoggingEnabled: Bool = true
    

    
    // Phase 5: UX Active Route Enhancements (DISABLED - too complex)
    static let enhancedActiveRouteSheetEnabled: Bool = false
    static let routeModificationEnabled: Bool = false
    static let smartNavigationHintsEnabled: Bool = false
    static let hapticFeedbackEnabled: Bool = false
}


