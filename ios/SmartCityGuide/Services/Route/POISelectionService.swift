import Foundation
import CoreLocation
import os.log

/// Service for intelligent POI selection and filtering based on various criteria
@MainActor
class POISelectionService: ObservableObject {
  
  // MARK: - Properties
  
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "POISelection")
  
  // MARK: - Public Interface
  
  /// Apply minimum distance filter to POIs to ensure geographic distribution
  /// - Parameters:
  ///   - pois: Array of POIs to filter
  ///   - startLocation: Starting coordinate
  ///   - minimumDistance: Minimum distance between POIs
  /// - Returns: Filtered array of POIs with proper spacing
  func applyMinimumDistanceFilter(
    pois: [POI],
    startLocation: CLLocationCoordinate2D,
    minimumDistance: MinimumPOIDistance
  ) -> [POI] {
    
    guard let minMeters = minimumDistance.meters else {
      logger.debug("🎯 No minimum distance filter applied")
      return pois
    }
    
    logger.info("🎯 Applying minimum distance filter: \(Int(minMeters))m between POIs")
    
    var filteredPOIs: [POI] = []
    
    for poi in pois {
      let tooClose = filteredPOIs.contains { existingPOI in
        let distance = calculateDistance(
          from: poi.coordinate,
          to: existingPOI.coordinate
        )
        return distance < minMeters
      }
      
      // Also check distance from start location
      let tooCloseToStart = calculateDistance(
        from: poi.coordinate,
        to: startLocation
      ) < minMeters
      
      if !tooClose && !tooCloseToStart {
        filteredPOIs.append(poi)
      } else {
        logger.debug("🎯 Filtered out POI '\(poi.name)' - too close to existing POI or start")
      }
    }
    
    let filteredCount = pois.count - filteredPOIs.count
    if filteredCount > 0 {
      logger.info("🎯 Distance filtering removed \(filteredCount) POIs, \(filteredPOIs.count) remaining")
    }
    
    return filteredPOIs
  }
  
  /// Validate and reduce stops to meet walking time constraints
  /// - Parameters:
  ///   - waypoints: Current waypoints
  ///   - maximumWalkingTime: Time constraint
  ///   - startingCity: City name for context
  /// - Returns: Validated and potentially reduced waypoints
  func validateAndReduceStopsForWalkingTime(
    waypoints: [RoutePoint],
    maximumWalkingTime: MaximumWalkingTime,
    startingCity: String
  ) -> [RoutePoint] {
    
    guard let maxMinutes = maximumWalkingTime.minutes else {
      logger.debug("🎯 No walking time constraint specified")
      return waypoints
    }
    
    logger.info("🎯 Validating route against \(maxMinutes)min walking time limit")
    
    // Estimate walking time based on straight-line distances
    let estimatedWalkingTime = estimateWalkingTime(for: waypoints)
    let estimatedMinutes = Int(estimatedWalkingTime / 60)
    
    if estimatedMinutes <= maxMinutes {
      logger.info("🎯 Route within time limit: \(estimatedMinutes)min ≤ \(maxMinutes)min")
      return waypoints
    }
    
    logger.warning("🎯 Route exceeds time limit: \(estimatedMinutes)min > \(maxMinutes)min, reducing stops")
    
    // Reduce stops by removing intermediate waypoints
    return reduceWaypointsToMeetTimeConstraint(
      waypoints: waypoints,
      maxMinutes: maxMinutes,
      currentEstimate: estimatedMinutes
    )
  }
  
  /// Calculate category-based targets for POI selection
  /// - Parameter totalCount: Total number of POIs to select
  /// - Returns: Dictionary mapping categories to target counts
  func calculateCategoryTargets(totalCount: Int) -> [PlaceCategory: Int] {
    let baseTargets: [PlaceCategory: Double] = [
      .attraction: 0.4,       // 40% - Main attractions
      .museum: 0.25,          // 25% - Cultural sites
      .park: 0.20,            // 20% - Green spaces
      .nationalPark: 0.15     // 15% - Natural areas
    ]
    
    var targets: [PlaceCategory: Int] = [:]
    var allocated = 0
    
    // Calculate targets proportionally
    for (category, percentage) in baseTargets {
      let target = max(1, Int(Double(totalCount) * percentage))
      targets[category] = target
      allocated += target
    }
    
    // Adjust for any rounding differences
    let difference = totalCount - allocated
    if difference != 0 {
      // Add/subtract from the largest category (attractions)
      targets[.attraction] = (targets[.attraction] ?? 1) + difference
    }
    
    logger.info("🎯 Category targets for \(totalCount) POIs: \(targets)")
    return targets
  }
  
  /// Apply geographic distribution to ensure POIs are spread out
  /// - Parameters:
  ///   - places: Array of places to distribute
  ///   - maxCount: Maximum number of places to return
  /// - Returns: Geographically distributed places
  func applyGeographicDistribution(_ places: [RoutePoint], maxCount: Int) -> [RoutePoint] {
    guard places.count > maxCount else { 
      logger.debug("🎯 No geographic distribution needed: \(places.count) ≤ \(maxCount)")
      return places 
    }
    
    logger.info("🎯 Applying geographic distribution: \(places.count) → \(maxCount) places")
    
    var selectedPlaces: [RoutePoint] = []
    var remainingPlaces = places
    
    // Start with the first place
    if let firstPlace = remainingPlaces.first {
      selectedPlaces.append(firstPlace)
      remainingPlaces.removeFirst()
    }
    
    // Iteratively select places that maximize minimum distance to already selected places
    while selectedPlaces.count < maxCount && !remainingPlaces.isEmpty {
      let nextPlace = findPlaceWithMaximumMinimumDistance(
        candidates: remainingPlaces,
        selectedPlaces: selectedPlaces
      )
      
      selectedPlaces.append(nextPlace)
      remainingPlaces.removeAll { $0.name == nextPlace.name }
      
      logger.debug("🎯 Selected place for distribution: \(nextPlace.name)")
    }
    
    logger.info("🎯 Geographic distribution complete: selected \(selectedPlaces.count) places")
    return selectedPlaces
  }
  
  /// Get estimated visit duration for a place category
  /// - Parameter category: The place category
  /// - Returns: Estimated visit duration in seconds
  func getEstimatedVisitDuration(for category: PlaceCategory) -> TimeInterval {
    switch category {
    case .attraction:
      return 45 * 60 // 45 minutes
    case .museum:
      return 90 * 60 // 1.5 hours
    case .park:
      return 30 * 60 // 30 minutes
    case .nationalPark:
      return 120 * 60 // 2 hours
    case .ruins:
      return 30 * 60 // 30 minutes
    case .castle:
      return 60 * 60 // 1 hour
    case .cathedral, .chapel, .placeOfWorship:
      return 20 * 60 // 20 minutes
    case .gallery, .artsCenter:
      return 45 * 60 // 45 minutes
    case .monument, .memorial:
      return 15 * 60 // 15 minutes
    case .viewpoint:
      return 10 * 60 // 10 minutes
    case .garden:
      return 45 * 60 // 45 minutes
    case .archaeologicalSite:
      return 30 * 60 // 30 minutes
    default:
      return 30 * 60 // 30 minutes default
    }
  }
  
  // MARK: - Private Helper Methods
  
  /// Estimate total walking time for a route based on straight-line distances
  /// - Parameter waypoints: Route waypoints
  /// - Returns: Estimated walking time in seconds
  private func estimateWalkingTime(for waypoints: [RoutePoint]) -> TimeInterval {
    guard waypoints.count >= 2 else { return 0 }
    
    var totalDistance = 0.0
    for i in 0..<waypoints.count-1 {
      let distance = calculateDistance(
        from: waypoints[i].coordinate,
        to: waypoints[i+1].coordinate
      )
      totalDistance += distance
    }
    
    // Assume average walking speed of 4.5 km/h (1.25 m/s)
    // Add 20% buffer for actual walking paths vs straight-line distance
    let walkingSpeed = 1.25 // m/s
    let pathBuffer = 1.2
    
    return (totalDistance * pathBuffer) / walkingSpeed
  }
  
  /// Reduce waypoints to meet time constraint by removing intermediate stops
  /// - Parameters:
  ///   - waypoints: Current waypoints
  ///   - maxMinutes: Maximum allowed minutes
  ///   - currentEstimate: Current estimated minutes
  /// - Returns: Reduced waypoints
  private func reduceWaypointsToMeetTimeConstraint(
    waypoints: [RoutePoint],
    maxMinutes: Int,
    currentEstimate: Int
  ) -> [RoutePoint] {
    
    guard waypoints.count > 3 else { return waypoints }
    
    // Keep start and end, reduce intermediate waypoints
    let start = waypoints.first!
    let end = waypoints.last!
    var intermediates = Array(waypoints[1..<waypoints.count-1])
    
    // Remove waypoints until we meet the time constraint
    while !intermediates.isEmpty {
      let testWaypoints = [start] + intermediates + [end]
      let testTime = Int(estimateWalkingTime(for: testWaypoints) / 60)
      
      if testTime <= maxMinutes {
        logger.info("🎯 Reduced to \(testWaypoints.count) waypoints to meet \(maxMinutes)min constraint")
        return testWaypoints
      }
      
      // Remove the waypoint that has the least impact on overall route distance
      let indexToRemove = findLeastImpactfulWaypoint(intermediates, start: start, end: end)
      let removed = intermediates.remove(at: indexToRemove)
      logger.debug("🎯 Removed waypoint '\(removed.name)' to reduce walking time")
    }
    
    // Fallback: just start and end
    logger.warning("🎯 Reduced to minimum route: start → end")
    return [start, end]
  }
  
  /// Find the waypoint whose removal has the least impact on total route distance
  /// - Parameters:
  ///   - intermediates: Intermediate waypoints
  ///   - start: Start waypoint
  ///   - end: End waypoint
  /// - Returns: Index of waypoint to remove
  private func findLeastImpactfulWaypoint(
    _ intermediates: [RoutePoint],
    start: RoutePoint,
    end: RoutePoint
  ) -> Int {
    
    let currentRoute = [start] + intermediates + [end]
    let currentDistance = calculateTotalDistance(currentRoute)
    
    var minImpact = Double.infinity
    var bestIndex = 0
    
    for i in 0..<intermediates.count {
      var testIntermediates = intermediates
      testIntermediates.remove(at: i)
      
      let testRoute = [start] + testIntermediates + [end]
      let testDistance = calculateTotalDistance(testRoute)
      let impact = abs(currentDistance - testDistance)
      
      if impact < minImpact {
        minImpact = impact
        bestIndex = i
      }
    }
    
    return bestIndex
  }
  
  /// Find the place that maximizes the minimum distance to already selected places
  /// - Parameters:
  ///   - candidates: Candidate places
  ///   - selectedPlaces: Already selected places
  /// - Returns: Best place for geographic distribution
  private func findPlaceWithMaximumMinimumDistance(
    candidates: [RoutePoint],
    selectedPlaces: [RoutePoint]
  ) -> RoutePoint {
    
    var bestPlace = candidates.first!
    var maxMinDistance = 0.0
    
    for candidate in candidates {
      // Find minimum distance to any selected place
      let minDistance = selectedPlaces.map { selected in
        calculateDistance(from: candidate.coordinate, to: selected.coordinate)
      }.min() ?? 0.0
      
      if minDistance > maxMinDistance {
        maxMinDistance = minDistance
        bestPlace = candidate
      }
    }
    
    return bestPlace
  }
  
  /// Calculate total distance for a route
  /// - Parameter waypoints: Route waypoints
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
}
