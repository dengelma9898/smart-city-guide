import Foundation
import SwiftUI

// MARK: - Active Route Sheet Mode

enum ActiveRouteSheetMode: String, CaseIterable {
    case compact = "Kompakt"
    case navigation = "Navigation" 
    case overview = "Übersicht"
    case hidden = "Versteckt"
}

// MARK: - Route Progress

struct RouteProgress {
    let completedWaypoints: Int
    let currentWaypointIndex: Int
    let totalWaypoints: Int
    let elapsedTime: TimeInterval
    let remainingTime: TimeInterval
    
    var completionPercentage: Double {
        guard totalWaypoints > 0 else { return 0.0 }
        return Double(completedWaypoints) / Double(totalWaypoints)
    }
    
    var estimatedTimeRemaining: TimeInterval {
        return remainingTime
    }
    
    var totalWaypointsVisited: Int {
        return completedWaypoints
    }
}

// MARK: - User Navigation Context

struct UserNavigationContext {
    let isActivelyNavigating: Bool
    let lastMovementTime: Date
    let currentSpeed: Double // m/s
    let isStationary: Bool
    let timeOfDay: TimeOfDay
    let weatherCondition: WeatherCondition
}

enum TimeOfDay {
    case morning, afternoon, evening, night
}

enum WeatherCondition {
    case sunny, cloudy, rainy, snowy
}

// MARK: - Route Modification

enum RouteModification {
    case addWaypoint
    case removeWaypoint
    case reorderWaypoints
    case optimizeRoute
    case addNearbyPOI
    case addBreak
    case optimize
    case skipWaypoint(Int)
    case reorderWaypointsWithList([RoutePoint])
}

// MARK: - Waypoint Progress State

enum WaypointProgressState {
    case upcoming
    case current
    case visited
}

// MARK: - Route Haptics

enum RouteHaptics {
    case lightImpact
    case mediumImpact
    case waypointReached
    case routeModified
    case routeCompleted
    
    func trigger() {
        // Implementation would use UIKit haptics
        // For now, just a placeholder
        print("Haptic feedback: \(self)")
    }
}

// MARK: - Sheet Animations

extension Animation {
    static let sheetModeTransition = Animation.easeInOut(duration: 0.4)
}