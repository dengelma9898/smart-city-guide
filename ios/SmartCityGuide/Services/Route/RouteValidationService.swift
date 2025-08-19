//
//  RouteValidationService.swift
//  SmartCityGuide
//
//  Service for validating routes against time and distance constraints
//

import Foundation
import MapKit
import CoreLocation
import os.log

@MainActor
class RouteValidationService: ObservableObject {
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "RouteValidation")
    private let mapKitService: MapKitRouteService
    
    init(mapKitService: MapKitRouteService? = nil) {
        self.mapKitService = mapKitService ?? MapKitRouteService()
    }
    
    // MARK: - Walking Time Validation
    
    /// Validates walking time and reduces stops if necessary
    func validateAndReduceStopsForWalkingTime(
        waypoints: [RoutePoint],
        routes: [MKRoute],
        maximumWalkingTime: MaximumWalkingTime,
        endpointOption: EndpointOption,
        customEndpoint: String,
        routeGenerator: @escaping ([RoutePoint], Bool) async throws -> [MKRoute]
    ) async throws -> [RoutePoint] {
        
        // If no maximum walking time is specified, return all waypoints
        guard let maxTimeMinutes = maximumWalkingTime.minutes else {
            logger.info("🗺️ No maximum walking time limit - returning all \(waypoints.count) waypoints")
            return waypoints
        }
        
        let maxTimeSeconds = TimeInterval(maxTimeMinutes * 60)
        let currentWalkingTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
        
        logger.info("🗺️ Walking time validation: \(Int(currentWalkingTime/60))min / \(maxTimeMinutes)min limit")
        
        // If within limits, return as is
        if currentWalkingTime <= maxTimeSeconds {
            logger.info("🗺️ Walking time within limits - no reduction needed")
            return waypoints
        }
        
        // Need to reduce stops - remove intermediate waypoints until under limit
        logger.info("🗺️ Walking time exceeds limit - reducing stops")
        
        var reducedWaypoints = waypoints
        
        // Keep start and end points, reduce intermediate points
        let startPoint = waypoints.first!
        let endPoint = waypoints.last!
        var intermediatePOIs = Array(waypoints[1..<waypoints.count-1])
        
        // Remove intermediate points one by one until under time limit
        while intermediatePOIs.count > 0 {
            // Remove the POI that's furthest from the optimal route
            let indexToRemove = intermediatePOIs.count / 2 // Remove from middle first
            intermediatePOIs.remove(at: indexToRemove)
            
            // Rebuild waypoints
            reducedWaypoints = [startPoint] + intermediatePOIs
            
            // Add endpoint based on option
            switch endpointOption {
            case .roundtrip:
                reducedWaypoints.append(startPoint)
            case .lastPlace:
                // No additional endpoint
                break
            case .custom:
                if !customEndpoint.isEmpty {
                    reducedWaypoints.append(endPoint)
                }
            }
            
            // Check new walking time (no performance logging for intermediate tests)
            let testRoutes = try await routeGenerator(reducedWaypoints, false)
            let newWalkingTime = testRoutes.reduce(0) { $0 + $1.expectedTravelTime }
            
            logger.info("🗺️ Reduced to \(intermediatePOIs.count) stops - walking time: \(Int(newWalkingTime/60))min")
            
            if newWalkingTime <= maxTimeSeconds {
                logger.info("🗺️ Walking time now within limits")
                return reducedWaypoints
            }
        }
        
        // If we get here, even minimal route exceeds time limit
        logger.warning("🗺️ Cannot create route within time limit - returning minimal route")
        return [startPoint, endPoint]
    }
    
    // MARK: - Legacy Conversion
    
    /// Converts new MaximumWalkingTime to legacy RouteLength for backwards compatibility
    func convertToLegacyRouteLength(_ maximumWalkingTime: MaximumWalkingTime) -> RouteLength {
        switch maximumWalkingTime {
        case .thirtyMin, .fortyFiveMin:
            return .short
        case .sixtyMin, .ninetyMin:
            return .medium
        case .twoHours, .threeHours, .openEnd:
            return .long
        }
    }
}
