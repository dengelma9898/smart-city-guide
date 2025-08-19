//
//  RouteOptimizationService.swift
//  SmartCityGuide
//
//  Service for optimizing route waypoint order using TSP algorithms
//

import Foundation
import CoreLocation
import os.log

@MainActor
class RouteOptimizationService: ObservableObject {
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "RouteOptimization")
    
    // MARK: - Route Optimization
    
    /// Optimizes waypoint order using nearest neighbor TSP approximation
    func optimizeWaypointOrder(_ waypoints: [RoutePoint]) -> [RoutePoint] {
        // Keep start and end points fixed
        guard waypoints.count > 3 else { return waypoints }
        
        let startPoint = waypoints.first!
        let endPoint = waypoints.last!
        let intermediatePOIs = Array(waypoints[1..<waypoints.count-1])
        
        // Simple nearest neighbor optimization for intermediate points
        var optimizedPOIs: [RoutePoint] = []
        var remainingPOIs = intermediatePOIs
        var currentLocation = startPoint.coordinate
        
        while !remainingPOIs.isEmpty {
            // Find nearest POI to current location
            let nearestIndex = remainingPOIs.enumerated().min { first, second in
                let distance1 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                    .distance(from: CLLocation(latitude: first.element.coordinate.latitude, longitude: first.element.coordinate.longitude))
                let distance2 = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                    .distance(from: CLLocation(latitude: second.element.coordinate.latitude, longitude: second.element.coordinate.longitude))
                return distance1 < distance2
            }?.offset ?? 0
            
            let nearestPOI = remainingPOIs.remove(at: nearestIndex)
            optimizedPOIs.append(nearestPOI)
            currentLocation = nearestPOI.coordinate
        }
        
        return [startPoint] + optimizedPOIs + [endPoint]
    }
    
    // MARK: - Visit Duration Estimation
    
    func getEstimatedVisitDuration(for category: PlaceCategory) -> TimeInterval {
        switch category {
        case .museum, .gallery:
            return 60 * 60 // 1 hour
        case .castle, .cathedral, .archaeologicalSite:
            return 45 * 60 // 45 minutes
        case .monument, .memorial, .viewpoint:
            return 20 * 60 // 20 minutes
        case .park, .garden:
            return 30 * 60 // 30 minutes
        case .artwork, .shrine:
            return 15 * 60 // 15 minutes
        case .attraction:
            return 30 * 60 // 30 minutes (default)
        case .artsCenter, .townhall:
            return 25 * 60 // 25 minutes
        case .placeOfWorship, .chapel, .monastery:
            return 20 * 60 // 20 minutes
        case .spring, .waterfall, .lake, .river, .canal:
            return 25 * 60 // 25 minutes
        case .nationalPark:
            return 90 * 60 // 1.5 hours
        case .ruins:
            return 30 * 60 // 30 minutes
        case .landmarkAttraction:
            return 25 * 60 // 25 minutes
        }
    }
    
    // MARK: - Route Distance Calculation
    
    func calculateTotalRouteDistance(_ waypoints: [RoutePoint]) -> Double {
        var totalDistance: Double = 0
        
        for i in 0..<waypoints.count-1 {
            let distance = CLLocation(latitude: waypoints[i].coordinate.latitude, longitude: waypoints[i].coordinate.longitude)
                .distance(from: CLLocation(latitude: waypoints[i+1].coordinate.latitude, longitude: waypoints[i+1].coordinate.longitude))
            totalDistance += distance
        }
        
        return totalDistance
    }
}
