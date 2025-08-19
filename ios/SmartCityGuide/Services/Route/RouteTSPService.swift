import Foundation
import CoreLocation
import os.log

/// Service for optimizing the order of waypoints using Travelling Salesman Problem (TSP) algorithms
@MainActor
class RouteTSPService: ObservableObject {
  
  // MARK: - Properties
  
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "RouteTSP")
  
  // MARK: - Public Interface
  
  /// Optimize the order of waypoints to minimize total travel distance
  /// - Parameter waypoints: Array of waypoints to optimize (start and end points remain fixed)
  /// - Returns: Optimized array of waypoints
  func optimizeWaypointOrder(_ waypoints: [RoutePoint]) -> [RoutePoint] {
    // Keep start and end points fixed
    guard waypoints.count > 3 else { 
      logger.debug("🧭 Skipping optimization: only \(waypoints.count) waypoints")
      return waypoints 
    }
    
    let startPoint = waypoints.first!
    let endPoint = waypoints.last!
    let intermediatePOIs = Array(waypoints[1..<waypoints.count-1])
    
    logger.info("🧭 Optimizing route order for \(intermediatePOIs.count) intermediate waypoints")
    
    // Use nearest neighbor algorithm for intermediate points
    let optimizedPOIs = nearestNeighborOptimization(
      intermediatePOIs: intermediatePOIs,
      startLocation: startPoint.coordinate
    )
    
    let result = [startPoint] + optimizedPOIs + [endPoint]
    
    // Log optimization result
    let originalDistance = calculateTotalDistance(waypoints)
    let optimizedDistance = calculateTotalDistance(result)
    let improvement = ((originalDistance - optimizedDistance) / originalDistance) * 100
    
    logger.info("🧭 Route optimization complete: \(String(format: "%.1f", improvement))% improvement (\(String(format: "%.0f", originalDistance))m → \(String(format: "%.0f", optimizedDistance))m)")
    
    return result
  }
  
  /// Optimize waypoints for manual route generation with flexible start/end handling
  /// - Parameters:
  ///   - selectedPOIs: The POIs to include in the route
  ///   - startLocation: Starting coordinate
  ///   - endpointOption: How to handle the route endpoint
  ///   - customEndpoint: Custom endpoint name (if applicable)
  ///   - customEndpointCoordinates: Custom endpoint coordinates (if applicable)
  /// - Returns: Optimized array of RoutePoints
  func optimizeManualRoute(
    selectedPOIs: [POI],
    startLocation: CLLocationCoordinate2D,
    endpointOption: EndpointOption,
    customEndpoint: String = "",
    customEndpointCoordinates: CLLocationCoordinate2D? = nil
  ) -> [RoutePoint] {
    
    logger.info("🧭 Optimizing manual route with \(selectedPOIs.count) POIs")
    
    // Build initial waypoints
    var waypoints: [RoutePoint] = []
    let start = RoutePoint(name: "Start", coordinate: startLocation, address: "Startpunkt", category: .attraction)
    waypoints.append(start)
    
    // Add POI waypoints
    for poi in selectedPOIs { 
      waypoints.append(RoutePoint(from: poi)) 
    }
    
    // Determine endpoint
    let end: RoutePoint
    switch endpointOption {
    case .roundtrip:
      end = start
    case .lastPlace:
      end = waypoints.last ?? start
    case .custom:
      let coord = customEndpointCoordinates ?? startLocation
      end = RoutePoint(
        name: customEndpoint.isEmpty ? "Ziel" : customEndpoint, 
        coordinate: coord, 
        address: customEndpoint, 
        category: .attraction
      )
    }
    
    // Only add end if it's different from start
    if !coordinatesAreEqual(end.coordinate, start.coordinate) {
      waypoints.append(end)
    } else {
      waypoints.append(start) // Ensure roundtrip
    }
    
    // Optimize order if we have multiple intermediate points
    if waypoints.count > 3 { 
      waypoints = optimizeWaypointOrder(waypoints) 
    }
    
    logger.info("🧭 Manual route optimized: \(waypoints.count) waypoints")
    return waypoints
  }
  
  // MARK: - Algorithm Implementations
  
  /// Nearest Neighbor algorithm for TSP optimization
  /// This is a greedy algorithm that always chooses the nearest unvisited point
  /// - Parameters:
  ///   - intermediatePOIs: POIs to optimize (excluding start/end)
  ///   - startLocation: Starting coordinate for the optimization
  /// - Returns: Optimized array of intermediate POIs
  private func nearestNeighborOptimization(
    intermediatePOIs: [RoutePoint],
    startLocation: CLLocationCoordinate2D
  ) -> [RoutePoint] {
    
    var optimizedPOIs: [RoutePoint] = []
    var remainingPOIs = intermediatePOIs
    var currentLocation = startLocation
    
    while !remainingPOIs.isEmpty {
      // Find nearest POI to current location
      let nearestIndex = findNearestPOIIndex(
        to: currentLocation,
        from: remainingPOIs
      )
      
      let nearestPOI = remainingPOIs.remove(at: nearestIndex)
      optimizedPOIs.append(nearestPOI)
      currentLocation = nearestPOI.coordinate
      
      logger.debug("🧭 Selected nearest POI: \(nearestPOI.name) (\(remainingPOIs.count) remaining)")
    }
    
    return optimizedPOIs
  }
  
  /// Find the index of the nearest POI to a given location
  /// - Parameters:
  ///   - location: Target location
  ///   - pois: Array of POIs to search
  /// - Returns: Index of the nearest POI
  private func findNearestPOIIndex(
    to location: CLLocationCoordinate2D,
    from pois: [RoutePoint]
  ) -> Int {
    
    return pois.enumerated().min { first, second in
      let distance1 = calculateDistance(from: location, to: first.element.coordinate)
      let distance2 = calculateDistance(from: location, to: second.element.coordinate)
      return distance1 < distance2
    }?.offset ?? 0
  }
  
  // MARK: - Helper Methods
  
  /// Calculate the total distance for a route
  /// - Parameter waypoints: Array of waypoints
  /// - Returns: Total distance in meters
  private func calculateTotalDistance(_ waypoints: [RoutePoint]) -> Double {
    guard waypoints.count >= 2 else { return 0.0 }
    
    var totalDistance = 0.0
    for i in 0..<waypoints.count-1 {
      let distance = calculateDistance(
        from: waypoints[i].coordinate,
        to: waypoints[i+1].coordinate
      )
      totalDistance += distance
    }
    
    return totalDistance
  }
  
  /// Calculate straight-line distance between two coordinates
  /// - Parameters:
  ///   - from: Starting coordinate
  ///   - to: Destination coordinate
  /// - Returns: Distance in meters
  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  /// Check if two coordinates are approximately equal (within tolerance)
  /// - Parameters:
  ///   - coord1: First coordinate
  ///   - coord2: Second coordinate
  /// - Returns: True if coordinates are approximately equal
  private func coordinatesAreEqual(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Bool {
    let tolerance = 0.0001 // ~11m at equator
    return abs(coord1.latitude - coord2.latitude) < tolerance &&
           abs(coord1.longitude - coord2.longitude) < tolerance
  }
  
  // MARK: - Advanced Algorithms (Future Extension Points)
  
  /// Placeholder for more sophisticated TSP algorithms
  /// Could implement 2-opt, genetic algorithm, or other optimization methods
  /// - Parameter waypoints: Waypoints to optimize
  /// - Returns: Optimized waypoints
  private func advancedTSPOptimization(_ waypoints: [RoutePoint]) -> [RoutePoint] {
    // Future implementation:
    // - 2-opt local search
    // - Simulated annealing
    // - Genetic algorithm
    // - Christofides algorithm
    
    logger.debug("🧭 Advanced TSP optimization not yet implemented, using nearest neighbor")
    return optimizeWaypointOrder(waypoints)
  }
  
  /// Calculate optimization quality metrics
  /// - Parameters:
  ///   - original: Original waypoint order
  ///   - optimized: Optimized waypoint order
  /// - Returns: Quality metrics (improvement percentage, etc.)
  func calculateOptimizationMetrics(
    original: [RoutePoint],
    optimized: [RoutePoint]
  ) -> (improvementPercentage: Double, originalDistance: Double, optimizedDistance: Double) {
    
    let originalDistance = calculateTotalDistance(original)
    let optimizedDistance = calculateTotalDistance(optimized)
    let improvement = originalDistance > 0 ? ((originalDistance - optimizedDistance) / originalDistance) * 100 : 0
    
    return (improvementPercentage: improvement, originalDistance: originalDistance, optimizedDistance: optimizedDistance)
  }
}
