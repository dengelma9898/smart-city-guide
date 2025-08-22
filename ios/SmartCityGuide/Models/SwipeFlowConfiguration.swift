//
//  SwipeFlowConfiguration.swift
//  SmartCityGuide
//
//  Created on 2025-08-22
//  Flow-specific configuration for Unified Swipe Interface
//

import Foundation

// MARK: - Swipe Flow Configuration

/// Configuration enum defining behavior for different POI selection flows
enum SwipeFlowConfiguration {
    /// Manual route planning flow - continuous POI selection with confirmation
    case manual
    
    /// Add POI to existing route flow - same as manual but with route context
    case addPOI
    
    /// Edit/replace POI in active route flow - immediate selection with filtering
    case editPOI(excludedPOIs: [POI])
    
    // MARK: - Configuration Properties
    
    /// Whether to show the selection counter in the UI
    var showSelectionCounter: Bool {
        switch self {
        case .manual, .addPOI:
            return true
        case .editPOI:
            return false
        }
    }
    
    /// Whether to show the confirm button
    var showConfirmButton: Bool {
        switch self {
        case .manual, .addPOI:
            return true
        case .editPOI:
            return false
        }
    }
    
    /// Whether to automatically confirm selection (close view immediately)
    var autoConfirmSelection: Bool {
        switch self {
        case .manual, .addPOI:
            return false
        case .editPOI:
            return true
        }
    }
    
    /// Whether to allow continuous swiping through multiple POIs
    var allowContinuousSwipe: Bool {
        switch self {
        case .manual, .addPOI, .editPOI:
            return true
        }
    }
    
    /// Behavior when the view is aborted/cancelled
    var onAbortBehavior: AbortBehavior {
        switch self {
        case .manual, .addPOI:
            return .clearSelections
        case .editPOI:
            return .keepSelections
        }
    }
    
    /// POIs to exclude from the card stack (e.g., current route POIs)
    var excludedPOIs: [POI] {
        switch self {
        case .manual, .addPOI:
            return []
        case .editPOI(let excludedPOIs):
            return excludedPOIs
        }
    }
    
    // MARK: - Flow Identification
    
    /// Whether this is a manual-style flow (manual or addPOI)
    var isManualFlow: Bool {
        switch self {
        case .manual, .addPOI:
            return true
        case .editPOI:
            return false
        }
    }
    
    /// Whether this is an edit flow
    var isEditFlow: Bool {
        switch self {
        case .editPOI:
            return true
        case .manual, .addPOI:
            return false
        }
    }
    
    // MARK: - POI Filtering
    
    /// Filter POIs based on the flow configuration
    /// - Parameter allPOIs: All available POIs
    /// - Returns: Filtered POIs according to flow rules
    func filterPOIs(_ allPOIs: [POI]) -> [POI] {
        guard !excludedPOIs.isEmpty else {
            return allPOIs
        }
        
        let excludedIDs = Set(excludedPOIs.map { $0.id })
        return allPOIs.filter { poi in
            !excludedIDs.contains(poi.id)
        }
    }
    
    // MARK: - Action Configuration
    
    /// Maximum number of POIs that can be selected in this flow
    var maxSelectionsAllowed: Int {
        switch self {
        case .manual, .addPOI:
            return Int.max // No limit for manual flows
        case .editPOI:
            return 1 // Only one replacement allowed
        }
    }
    
    /// Whether to show toast messages for actions
    var showToastMessages: Bool {
        return isManualFlow
    }
    
    /// Duration to wait before closing view after selection (in seconds)
    var autoCloseDelay: TimeInterval {
        switch self {
        case .manual, .addPOI:
            return 0 // Don't auto-close
        case .editPOI:
            return 0.3 // Brief delay for edit flow
        }
    }
}

// MARK: - Abort Behavior

/// Defines what happens when the swipe view is cancelled/aborted
enum AbortBehavior {
    /// Clear all selections made in this session
    case clearSelections
    
    /// Keep selections (for flows where partial progress should be preserved)
    case keepSelections
}

// MARK: - Configuration Factory Methods

extension SwipeFlowConfiguration {
    
    /// Create configuration for manual route planning
    /// - Returns: Manual flow configuration
    static func createManualFlow() -> SwipeFlowConfiguration {
        return .manual
    }
    
    /// Create configuration for adding POIs to existing route
    /// - Returns: Add POI flow configuration
    static func createAddPOIFlow() -> SwipeFlowConfiguration {
        return .addPOI
    }
    
    /// Create configuration for editing/replacing POI in active route
    /// - Parameters:
    ///   - currentRouteWaypoints: POIs currently in the route to exclude
    ///   - poiToReplace: The specific POI being replaced
    /// - Returns: Edit POI flow configuration
    static func createEditPOIFlow(
        currentRouteWaypoints: [RoutePoint],
        poiToReplace: RoutePoint
    ) -> SwipeFlowConfiguration {
        // Convert RoutePoints to POIs for exclusion
        var excludedPOIs: [POI] = []
        
        // Add current route waypoints (converted to POI format for comparison)
        for waypoint in currentRouteWaypoints {
            let excludedPOI = POI(
                id: waypoint.poiId ?? UUID().uuidString,
                name: waypoint.name,
                latitude: waypoint.coordinate.latitude,
                longitude: waypoint.coordinate.longitude,
                category: waypoint.category,
                description: "",
                tags: [:],
                sourceType: "route",
                sourceId: 0,
                address: POIAddress(
                    street: "",
                    houseNumber: "",
                    city: waypoint.address,
                    postcode: "",
                    country: ""
                ),
                contact: nil,
                accessibility: nil,
                pricing: nil,
                operatingHours: nil,
                website: nil,
                geoapifyWikiData: nil
            )
            excludedPOIs.append(excludedPOI)
        }
        
        return .editPOI(excludedPOIs: excludedPOIs)
    }
}

// MARK: - Debug Support

extension SwipeFlowConfiguration: CustomStringConvertible {
    var description: String {
        switch self {
        case .manual:
            return "SwipeFlowConfiguration.manual"
        case .addPOI:
            return "SwipeFlowConfiguration.addPOI"
        case .editPOI(let excludedPOIs):
            return "SwipeFlowConfiguration.editPOI(excludedPOIs: \(excludedPOIs.count))"
        }
    }
}
