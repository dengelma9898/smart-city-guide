import Foundation
import SwiftUI
import UIKit

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
    var lastMovementTime: Date
    let currentSpeed: Double // m/s
    var isStationary: Bool
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
        DispatchQueue.main.async {
            switch self {
            case .lightImpact:
                let feedback = UIImpactFeedbackGenerator(style: .light)
                feedback.impactOccurred()
                
            case .mediumImpact:
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred()
                
            case .waypointReached:
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                
            case .routeModified:
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.impactOccurred()
                
            case .routeCompleted:
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)
                // Double haptic for completion celebration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    feedback.notificationOccurred(.success)
                }
            }
        }
    }
}

// MARK: - Sheet Animations

extension Animation {
    static let sheetModeTransition = Animation.easeInOut(duration: 0.4)
}