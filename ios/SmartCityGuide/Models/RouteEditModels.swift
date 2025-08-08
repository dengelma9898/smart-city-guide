//
//  RouteEditModels.swift
//  SmartCityGuide
//
//  Created on $(date)
//  Route Edit Feature - Tinder-Style Implementation
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Route Edit Core Models

/// Represents a route spot that can be edited with alternative POIs
struct EditableRouteSpot {
    /// The original waypoint in the route
    let originalWaypoint: RoutePoint
    /// Position/index in the route waypoints array
    let waypointIndex: Int
    /// Available alternative POIs from cache (no distance restrictions)
    let alternativePOIs: [POI]
    /// Currently selected POI (if different from original)
    let currentPOI: POI?
    /// List of previously replaced POIs at this position
    let replacedPOIs: [POI]
    
    /// Initialize an editable route spot
    /// - Parameters:
    ///   - originalWaypoint: The original waypoint to be potentially replaced
    ///   - waypointIndex: Index position in the route waypoints array
    ///   - alternativePOIs: Filtered alternatives available for swapping
    ///   - currentPOI: Currently selected POI (optional)
    ///   - replacedPOIs: Previously replaced POIs at this position
    init(originalWaypoint: RoutePoint, waypointIndex: Int, alternativePOIs: [POI], currentPOI: POI? = nil, replacedPOIs: [POI] = []) {
        self.originalWaypoint = originalWaypoint
        self.waypointIndex = waypointIndex
        self.alternativePOIs = alternativePOIs
        self.currentPOI = currentPOI
        self.replacedPOIs = replacedPOIs
    }
}

/// Request structure for editing a specific route spot
struct SpotEditRequest {
    /// Index of the waypoint to be edited
    let targetSpotIndex: Int
    /// Current complete route
    let currentRoute: GeneratedRoute
    /// Available alternative POIs from cache
    let availableAlternatives: [POI]
    /// Maximum distance from original spot (default: 500m)
    let maxDistanceFromOriginal: Double
    
    /// Initialize a spot edit request
    /// - Parameters:
    ///   - targetSpotIndex: Index of waypoint to edit
    ///   - currentRoute: Current route containing all waypoints
    ///   - availableAlternatives: POIs available as alternatives
    ///   - maxDistanceFromOriginal: Maximum distance constraint (default: 500m)
    init(targetSpotIndex: Int, currentRoute: GeneratedRoute, availableAlternatives: [POI], maxDistanceFromOriginal: Double = 500.0) {
        self.targetSpotIndex = targetSpotIndex
        self.currentRoute = currentRoute
        self.availableAlternatives = availableAlternatives
        self.maxDistanceFromOriginal = maxDistanceFromOriginal
    }
}

/// Actions available during swipe interaction
enum SwipeAction: Equatable {
    /// User accepts the POI as replacement
    case accept(POI)
    /// User rejects the POI
    case reject(POI)
    /// User skips without decision
    case skip
    
    /// Manual Equatable implementation (POI uses id for equality)
    static func == (lhs: SwipeAction, rhs: SwipeAction) -> Bool {
        switch (lhs, rhs) {
        case (.accept(let poi1), .accept(let poi2)):
            return poi1.id == poi2.id
        case (.reject(let poi1), .reject(let poi2)):
            return poi1.id == poi2.id
        case (.skip, .skip):
            return true
        default:
            return false
        }
    }
    
    /// Get the associated POI if available
    var associatedPOI: POI? {
        switch self {
        case .accept(let poi), .reject(let poi):
            return poi
        case .skip:
            return nil
        }
    }
    
    /// Check if action is accept
    var isAccept: Bool {
        if case .accept = self { return true }
        return false
    }
    
    /// Check if action is reject
    var isReject: Bool {
        if case .reject = self { return true }
        return false
    }
}

// MARK: - Route Edit State Models

/// State for the route editing process
@MainActor
class RouteEditState: ObservableObject {
    /// Whether route recalculation is in progress
    @Published var isRecalculating: Bool = false
    
    /// Whether alternatives are being loaded
    @Published var isLoadingAlternatives: Bool = false
    
    /// Current error message, if any
    @Published var errorMessage: String?
    
    /// Number of alternatives processed so far
    @Published var processedAlternatives: Int = 0
    
    /// Total number of alternatives available
    @Published var totalAlternatives: Int = 0
    
    /// Whether the edit session has completed
    @Published var hasCompleted: Bool = false
    
    /// The final selected POI (if any)
    @Published var selectedPOI: POI?
    
    /// Reset state for new edit session
    func reset() {
        isRecalculating = false
        isLoadingAlternatives = false
        errorMessage = nil
        processedAlternatives = 0
        totalAlternatives = 0
        hasCompleted = false
        selectedPOI = nil
    }
    
    /// Set error state
    /// - Parameter message: Error message to display
    func setError(_ message: String) {
        errorMessage = message
        isRecalculating = false
        isLoadingAlternatives = false
    }
    
    /// Update progress
    /// - Parameters:
    ///   - processed: Number of alternatives processed
    ///   - total: Total number of alternatives
    func updateProgress(processed: Int, total: Int) {
        processedAlternatives = processed
        totalAlternatives = total
    }
    
    /// Mark edit session as completed
    /// - Parameter selectedPOI: The POI chosen by user (optional)
    func complete(with selectedPOI: POI? = nil) {
        self.selectedPOI = selectedPOI
        hasCompleted = true
        isRecalculating = false
        isLoadingAlternatives = false
    }
}

// MARK: - Route Edit Result Models

/// Result of a route edit operation
enum RouteEditResult {
    /// Edit was successful with new route
    case success(GeneratedRoute)
    /// Edit was cancelled by user
    case cancelled
    /// Edit failed with error
    case failed(Error)
    /// No changes made (user went through all alternatives without selecting)
    case noChanges
}

/// Configuration for route edit behavior
struct RouteEditConfiguration {
    /// Maximum distance from original spot for alternatives (meters)
    let maxDistanceFromOriginal: Double
    
    /// Maximum number of alternatives to show
    let maxAlternatives: Int
    
    /// Whether to prefer same category alternatives
    let preferSameCategory: Bool
    
    /// Whether to require Wikipedia data for alternatives
    let requireWikipediaData: Bool
    
    /// Distance threshold for triggering route re-optimization (meters)
    let reoptimizationThreshold: Double
    
    /// Default configuration
    static let `default` = RouteEditConfiguration(
        maxDistanceFromOriginal: 500.0, // 500m radius
        maxAlternatives: 20,             // Max 20 cards
        preferSameCategory: true,        // Same category preferred
        requireWikipediaData: false,     // Wikipedia nice-to-have but not required
        reoptimizationThreshold: 1500.0 // 1.5km - re-optimize for distant POIs
    )
    
    /// Strict configuration for better quality alternatives
    static let strict = RouteEditConfiguration(
        maxDistanceFromOriginal: 300.0,  // Smaller radius
        maxAlternatives: 10,             // Fewer alternatives
        preferSameCategory: true,        // Same category required
        requireWikipediaData: true,      // Wikipedia required
        reoptimizationThreshold: 1000.0 // 1km - more aggressive re-optimization
    )
}

// MARK: - Distance Calculation Helpers

extension EditableRouteSpot {
    /// Calculate distance from alternative POI to original waypoint
    /// - Parameter poi: Alternative POI
    /// - Returns: Distance in meters
    func distanceToOriginal(from poi: POI) -> Double {
        let fromLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        let toLocation = CLLocation(latitude: originalWaypoint.coordinate.latitude, longitude: originalWaypoint.coordinate.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Check if POI is within acceptable distance from original
    /// - Parameters:
    ///   - poi: Alternative POI
    ///   - maxDistance: Maximum allowed distance
    /// - Returns: True if within range
    func isWithinRange(_ poi: POI, maxDistance: Double) -> Bool {
        return distanceToOriginal(from: poi) <= maxDistance
    }
}

extension SpotEditRequest {
    /// Get the waypoint being edited
    var targetWaypoint: RoutePoint? {
        guard targetSpotIndex >= 0 && targetSpotIndex < currentRoute.waypoints.count else {
            return nil
        }
        return currentRoute.waypoints[targetSpotIndex]
    }
    
    /// Filter alternatives based on request constraints
    /// - Returns: Filtered array of alternative POIs
    func filteredAlternatives() -> [POI] {
        guard let targetWaypoint = targetWaypoint else { return [] }
        
        return availableAlternatives.filter { poi in
            // Distance constraint
            let fromLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
            let toLocation = CLLocation(latitude: targetWaypoint.coordinate.latitude, longitude: targetWaypoint.coordinate.longitude)
            let distance = fromLocation.distance(from: toLocation)
            return distance <= maxDistanceFromOriginal
        }
    }
}