import Foundation
import CoreLocation
import SwiftUI

// MARK: - Active Route UX Models

/// Enhanced bottom sheet presentation modes for active route
enum ActiveRouteSheetMode: CaseIterable {
    case compact       // 84pt - Essential info only, minimal distraction
    case navigation    // 50% - Navigation focus + next stop details
    case overview      // Large - Full route overview + modification tools
    case hidden        // 0pt - Full map immersion (future feature)
    
    var height: CGFloat {
        switch self {
        case .compact: return 84
        case .navigation: return UIScreen.main.bounds.height * 0.5
        case .overview: return UIScreen.main.bounds.height * 0.85
        case .hidden: return 0
        }
    }
    
    var detents: [PresentationDetent] {
        switch self {
        case .compact: return [.height(84)]
        case .navigation: return [.height(84), .fraction(0.5)]
        case .overview: return [.height(84), .fraction(0.5), .large]
        case .hidden: return []
        }
    }
    
    var animationDuration: TimeInterval {
        switch self {
        case .compact: return 0.3
        case .navigation: return 0.4
        case .overview: return 0.5
        case .hidden: return 0.2
        }
    }
}

/// Route progress tracking with intelligent context
struct RouteProgress {
    let currentWaypointIndex: Int
    let distanceCompleted: CLLocationDistance
    let timeElapsed: TimeInterval
    let estimatedTimeRemaining: TimeInterval
    let completionPercentage: Double
    let nextWaypointETA: Date
    let totalWaypointsVisited: Int
    let currentUserLocation: CLLocation?
    
    // Computed properties for UX
    var isNearNextWaypoint: Bool {
        guard let userLocation = currentUserLocation,
              let nextWaypoint = nextWaypoint else { return false }
        return userLocation.distance(from: CLLocation(
            latitude: nextWaypoint.coordinate.latitude,
            longitude: nextWaypoint.coordinate.longitude
        )) < 100 // Within 100 meters
    }
    
    var nextWaypoint: RoutePoint? {
        // Will be populated by the coordinator
        return nil
    }
    
    var progressRingData: ProgressRingData {
        return ProgressRingData(
            progress: completionPercentage,
            strokeColor: progressColor,
            ringWidth: 8.0
        )
    }
    
    private var progressColor: Color {
        switch completionPercentage {
        case 0..<0.3: return .blue
        case 0.3..<0.7: return .orange
        default: return .green
        }
    }
}

/// Visual data for progress ring animations
struct ProgressRingData {
    let progress: Double
    let strokeColor: Color
    let ringWidth: CGFloat
    let animationDuration: TimeInterval = 1.0
    
    var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: ringWidth, lineCap: .round)
    }
}

/// State of individual waypoints in route progress
enum WaypointProgressState {
    case upcoming     // Gray, not yet reached
    case current      // Blue, currently navigating to
    case visited      // Green, successfully visited
    case skipped      // Orange, skipped by user choice
    
    var color: Color {
        switch self {
        case .upcoming: return .secondary
        case .current: return .blue
        case .visited: return .green
        case .skipped: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming: return "circle"
        case .current: return "circle.fill"
        case .visited: return "checkmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        }
    }
}

/// User gesture recognition for route interactions
enum RouteGesture {
    case sheetSwipeUp
    case sheetSwipeDown
    case waypointLongPress(RoutePoint)
    case mapPinch(scale: CGFloat)
    case routeLineTap(segmentIndex: Int)
    case dragWaypoint(from: Int, to: Int)
    
    var hapticFeedback: RouteHaptics {
        switch self {
        case .sheetSwipeUp, .sheetSwipeDown: return .lightImpact
        case .waypointLongPress: return .mediumImpact
        case .mapPinch: return .selectionChanged
        case .routeLineTap: return .lightImpact
        case .dragWaypoint: return .heavyImpact
        }
    }
}

/// Haptic feedback patterns for route interactions
enum RouteHaptics {
    case waypointApproaching    // Gentle notification
    case waypointReached        // Achievement feedback
    case routeModified          // Confirmation feedback
    case routeCompleted         // Celebration pattern
    case navigationHint         // Directional guidance
    case lightImpact           // General interaction
    case mediumImpact          // Important interaction
    case heavyImpact           // Major action
    case selectionChanged      // UI state change
    
    func trigger() {
        let impactGenerator: UIImpactFeedbackGenerator
        let notificationGenerator = UINotificationFeedbackGenerator()
        let selectionGenerator = UISelectionFeedbackGenerator()
        
        switch self {
        case .waypointApproaching:
            impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
            
        case .waypointReached:
            notificationGenerator.notificationOccurred(.success)
            
        case .routeModified:
            impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
        case .routeCompleted:
            // Create celebration pattern
            let lightImpact = UIImpactFeedbackGenerator(style: .light)
            let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
            
            heavyImpact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                lightImpact.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                lightImpact.impactOccurred()
            }
            
        case .navigationHint:
            impactGenerator = UIImpactFeedbackGenerator(style: .rigid)
            impactGenerator.impactOccurred()
            
        case .lightImpact:
            impactGenerator = UIImpactFeedbackGenerator(style: .light)
            impactGenerator.impactOccurred()
            
        case .mediumImpact:
            impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
        case .heavyImpact:
            impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactGenerator.impactOccurred()
            
        case .selectionChanged:
            selectionGenerator.selectionChanged()
        }
    }
}

/// Context-aware content for active route sheet
struct ActiveRouteContent {
    let mode: ActiveRouteSheetMode
    let route: GeneratedRoute
    let progress: RouteProgress?
    let nextWaypoint: RoutePoint?
    let estimatedArrival: Date?
    let distanceToNext: CLLocationDistance?
    let completedWaypoints: [RoutePoint]
    let modificationsAvailable: Bool
    let userContext: UserNavigationContext
    
    // Content visibility based on mode and context
    var showsFullDetails: Bool {
        mode == .overview || mode == .navigation
    }
    
    var showsModificationTools: Bool {
        mode == .overview && modificationsAvailable
    }
    
    var showsNavigationHints: Bool {
        mode == .navigation && userContext.isActivelyNavigating
    }
    
    var primaryActionTitle: String {
        if let nextWaypoint = nextWaypoint {
            let distance = distanceToNext ?? 0
            if distance < 50 {
                return "Angekommen bei \(nextWaypoint.name)"
            } else if distance < 200 {
                return "Fast da! \(Int(distance))m zu \(nextWaypoint.name)"
            } else {
                return "Weiter zu \(nextWaypoint.name)"
            }
        }
        return "Tour beenden"
    }
}

/// User context for intelligent navigation assistance
struct UserNavigationContext {
    let isActivelyNavigating: Bool
    let lastMovementTime: Date
    let currentSpeed: CLLocationSpeed // m/s
    let isStationary: Bool
    let timeOfDay: TimeOfDay
    let weatherCondition: WeatherCondition?
    
    var suggestedSheetMode: ActiveRouteSheetMode {
        if isStationary {
            return .overview // User stopped, show modification options
        } else if isActivelyNavigating {
            return .navigation // User walking, show navigation focus
        } else {
            return .compact // User exploring, minimal distraction
        }
    }
    
    var shouldShowSuggestions: Bool {
        isStationary && Date().timeIntervalSince(lastMovementTime) > 30
    }
}

enum TimeOfDay {
    case morning    // 6-12
    case afternoon  // 12-18
    case evening    // 18-22
    case night      // 22-6
    
    var isRestTime: Bool {
        self == .evening || self == .night
    }
    
    var suggestedBreakType: String? {
        switch self {
        case .morning: return "Kaffee"
        case .afternoon: return "Mittagessen"
        case .evening: return "Abendessen"
        case .night: return nil
        }
    }
}

enum WeatherCondition {
    case sunny
    case cloudy
    case rainy
    case stormy
    case snow
    
    var affectsWalking: Bool {
        self == .rainy || self == .stormy || self == .snow
    }
    
    var suggestIndoorAlternatives: Bool {
        affectsWalking
    }
}

// MARK: - Animation Helpers

extension Animation {
    static let sheetModeTransition = Animation.spring(duration: 0.4, bounce: 0.2)
    static let progressUpdate = Animation.easeInOut(duration: 1.2)
    static let waypointReached = Animation.spring(duration: 0.8, bounce: 0.3)
    static let routeModification = Animation.easeInOut(duration: 0.6)
    static let celebrationBounce = Animation.spring(duration: 2.0, bounce: 0.4)
}
