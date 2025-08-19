import Foundation
import MapKit
import CoreLocation
import os.log

/// Service for calculating routes between waypoints using MapKit
@MainActor
class MapKitRouteService: ObservableObject {
  
  // MARK: - Properties
  
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "MapKitRoute")
  
  // Performance testing state - prevent infinite A/B testing loops
  private var hasRunPerformanceComparison = false
  
  // MARK: - Public Interface
  
  /// Generate routes between all consecutive waypoints
  /// - Parameters:
  ///   - waypoints: Array of waypoints to connect
  ///   - logPerformance: Whether to log performance metrics
  /// - Returns: Array of MKRoute objects connecting the waypoints
  /// - Throws: Error if route calculation fails
  func generateRoutesBetweenWaypoints(_ waypoints: [RoutePoint], logPerformance: Bool = true) async throws -> [MKRoute] {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Choose implementation based on feature flag
    let routes: [MKRoute]
    if FeatureFlags.parallelRouteGenerationEnabled {
      routes = try await generateRoutesBetweenWaypointsParallel(waypoints)
    } else {
      routes = try await generateRoutesBetweenWaypointsSequential(waypoints)
    }
    
    // Log performance metrics if enabled AND requested
    if FeatureFlags.routePerformanceLoggingEnabled && logPerformance {
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      
      SecureLogger.shared.logRoutePerformance(
        waypoints: waypoints.count,
        duration: duration,
        parallel: FeatureFlags.parallelRouteGenerationEnabled,
        concurrentTasks: FeatureFlags.parallelRouteGenerationEnabled ? 3 : 1
      )
      
      // For development: Log both implementations for comparison (once per session)
      #if DEBUG
      if waypoints.count >= 4 && !hasRunPerformanceComparison {
        hasRunPerformanceComparison = true
        Task {
          await performRoutePerformanceComparison(waypoints: waypoints, parallelDuration: duration)
        }
      }
      #endif
    }
    
    return routes
  }
  
  /// Generate a single route between two coordinates
  /// - Parameters:
  ///   - start: Starting coordinate
  ///   - end: Destination coordinate
  /// - Returns: MKRoute object for the calculated route
  /// - Throws: Error if route calculation fails
  func generateSingleRoute(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D
  ) async throws -> MKRoute {
    
    // Check route cache first if enabled
    if FeatureFlags.routeCachingEnabled {
      if let cachedRoute = RouteCacheService.shared.getCachedRoute(from: start, to: end) {
        return cachedRoute
      }
    }
    
    // Cache miss - calculate route via MapKit
    let route = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKRoute, Error>) in
      let request = MKDirections.Request()
      request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
      request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
      request.transportType = .walking
      
      let directions = MKDirections(request: request)
      directions.calculate { response, error in
        if let error = error {
          self.logger.error("Route calculation failed: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        } else if let route = response?.routes.first {
          self.logger.debug("✅ Route calculated: \(route.distance)m, \(route.expectedTravelTime)s")
          continuation.resume(returning: route)
        } else {
          let error = NSError(
            domain: "MapKitRouteService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Keine Route gefunden"]
          )
          self.logger.warning("❌ No route found between coordinates")
          continuation.resume(throwing: error)
        }
      }
    }
    
    // Cache the successful result
    if FeatureFlags.routeCachingEnabled {
      RouteCacheService.shared.cacheRoute(route, from: start, to: end)
    }
    
    return route
  }
  
  /// Calculate the total distance for a set of waypoints
  /// - Parameter waypoints: Array of waypoints
  /// - Returns: Total distance in meters
  func calculateTotalRouteDistance(_ waypoints: [RoutePoint]) -> Double {
    guard waypoints.count >= 2 else { return 0.0 }
    
    var totalDistance = 0.0
    for i in 0..<waypoints.count-1 {
      let start = waypoints[i].coordinate
      let end = waypoints[i+1].coordinate
      let segmentDistance = distance(from: start, to: end)
      totalDistance += segmentDistance
    }
    
    return totalDistance
  }
  
  // MARK: - Private Implementation Methods
  
  /// Sequential route generation (original implementation)
  private func generateRoutesBetweenWaypointsSequential(_ waypoints: [RoutePoint]) async throws -> [MKRoute] {
    var routes: [MKRoute] = []
    
    for i in 0..<waypoints.count-1 {
      let startPoint = waypoints[i]
      let endPoint = waypoints[i+1]
      
      let route = try await generateSingleRoute(
        from: startPoint.coordinate,
        to: endPoint.coordinate
      )
      routes.append(route)
      
      // Small delay to avoid rate limiting (centralized)
      try await RateLimiter.awaitRouteCalculationTick()
    }
    
    return routes
  }
  
  /// Parallel route generation with controlled concurrency
  private func generateRoutesBetweenWaypointsParallel(_ waypoints: [RoutePoint]) async throws -> [MKRoute] {
    let semaphore = AsyncSemaphore(maxConcurrent: 3)
    var routes: [MKRoute?] = Array(repeating: nil, count: waypoints.count - 1)
    
    try await withThrowingTaskGroup(of: (Int, MKRoute).self) { group in
      for i in 0..<waypoints.count-1 {
        group.addTask {
          await semaphore.acquire()
          defer { Task { await semaphore.release() } }
          
          if Task.isCancelled { throw CancellationError() }
          
          // Rate limiting for task start (not completion)
          try await RateLimiter.awaitRouteCalculationTick()
          
          let route = try await self.generateSingleRoute(
            from: waypoints[i].coordinate,
            to: waypoints[i+1].coordinate
          )
          return (i, route)
        }
      }
      
      for try await (index, route) in group {
        routes[index] = route
      }
    }
    
    // Convert to non-optional array, maintaining order
    return routes.compactMap { $0 }
  }
  
  /// Development helper: Compare sequential vs parallel performance for A/B testing
  private func performRoutePerformanceComparison(waypoints: [RoutePoint], parallelDuration: TimeInterval) async {
    // Only run comparison if we used parallel mode
    guard FeatureFlags.parallelRouteGenerationEnabled else { return }
    
    do {
      // Test sequential performance
      let sequentialStartTime = CFAbsoluteTimeGetCurrent()
      _ = try await generateRoutesBetweenWaypointsSequential(waypoints)
      let sequentialDuration = CFAbsoluteTimeGetCurrent() - sequentialStartTime
      
      // Calculate improvement
      let improvement = ((sequentialDuration - parallelDuration) / sequentialDuration) * 100
      
      SecureLogger.shared.logRoutePerformanceComparison(
        waypoints: waypoints.count,
        sequentialDuration: sequentialDuration,
        parallelDuration: parallelDuration,
        improvement: improvement
      )
    } catch {
      SecureLogger.shared.logError("Failed to run performance comparison: \(error)", category: .performance)
    }
  }
  
  // MARK: - Helper Methods
  
  /// Calculate straight-line distance between two coordinates
  /// - Parameters:
  ///   - from: Starting coordinate
  ///   - to: Destination coordinate
  /// - Returns: Distance in meters
  private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  /// Validate that coordinates are valid for route calculation
  /// - Parameters:
  ///   - start: Starting coordinate
  ///   - end: Destination coordinate
  /// - Returns: True if both coordinates are valid
  func areCoordinatesValid(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Bool {
    return CLLocationCoordinate2DIsValid(start) && 
           CLLocationCoordinate2DIsValid(end) &&
           start.latitude != 0.0 && start.longitude != 0.0 &&
           end.latitude != 0.0 && end.longitude != 0.0
  }
}
