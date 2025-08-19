import Foundation
import CoreLocation
import os.log

/// High-level service for orchestrating route generation using specialized services
@MainActor
class RouteGenerationService: ObservableObject {
  
  // MARK: - Properties
  
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "RouteGeneration")
  
  // MARK: - Dependencies
  
  private let locationResolver: LocationResolverService
  private let mapKitService: MapKitRouteService
  private let tspService: RouteTSPService
  private let poiSelectionService: POISelectionService
  
  // MARK: - Initialization
  
  init(
    locationResolver: LocationResolverService? = nil,
    mapKitService: MapKitRouteService? = nil,
    tspService: RouteTSPService? = nil,
    poiSelectionService: POISelectionService? = nil
  ) {
    self.locationResolver = locationResolver ?? LocationResolverService()
    self.mapKitService = mapKitService ?? MapKitRouteService()
    self.tspService = tspService ?? RouteTSPService()
    self.poiSelectionService = poiSelectionService ?? POISelectionService()
  }
  
  // MARK: - Public Route Generation Interface
  
  /// Generate route with enhanced filters and optimization
  /// - Parameters:
  ///   - startingLocation: Starting location (city or current location)
  ///   - maximumStops: Maximum number of stops
  ///   - endpointOption: How to handle route endpoint
  ///   - customEndpoint: Custom endpoint name (if applicable)
  ///   - maximumWalkingTime: Maximum walking time constraint
  ///   - minimumPOIDistance: Minimum distance between POIs
  ///   - availablePOIs: Pre-filtered POIs to use
  ///   - startingCity: City name for context
  /// - Returns: Optimized route with all waypoints and connections
  /// - Throws: Error if route generation fails
  func generateOptimalRouteWithFilters(
    startingLocation: StartingLocation,
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    availablePOIs: [POI],
    startingCity: String
  ) async throws -> [RoutePoint] {
    
    // Step 1: Resolve starting location
    let startLocationPoint: RoutePoint
    switch startingLocation {
    case .city(let cityName):
      startLocationPoint = try await locationResolver.findLocation(query: cityName)
    case .currentLocation(let location):
      startLocationPoint = try await locationResolver.createRoutePointFromCurrentLocation(location)
    }
    
    let startCoordinate = startLocationPoint.coordinate
    
    logger.info("🗺️ Generating route from '\(startLocationPoint.name)' with \(availablePOIs.count) POIs")
    
    // Step 2: Select and filter POIs
    let effectiveMaxStops = maximumStops.intValue
    
    // Use POI cache service for initial selection
    let selectedPOIs = POICacheService.shared.selectBestPOIs(
      from: availablePOIs,
      count: effectiveMaxStops,
      routeLength: convertToLegacyRouteLength(maximumWalkingTime),
      startCoordinate: startCoordinate,
      startingCity: startingCity
    )
    
    logger.info("🗺️ Selected \(selectedPOIs.count) POIs before filtering")
    
    // Step 3: Apply minimum POI distance filter
    let filteredPOIs = poiSelectionService.applyMinimumDistanceFilter(
      pois: selectedPOIs,
      startLocation: startCoordinate,
      minimumDistance: minimumPOIDistance
    )
    
    logger.info("🗺️ \(filteredPOIs.count) POIs remain after distance filtering")
    
    // Step 4: Build initial waypoints
    var waypoints = [startLocationPoint]
    
    // Add POI waypoints
    for poi in filteredPOIs {
      waypoints.append(RoutePoint(from: poi))
    }
    
    // Step 5: Handle endpoint
    waypoints = try await addEndpointToWaypoints(
      waypoints: waypoints,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      startCoordinate: startCoordinate
    )
    
    // Step 6: Optimize waypoint order using TSP
    if waypoints.count > 3 {
      waypoints = tspService.optimizeWaypointOrder(waypoints)
    }
    
    // Step 7: Validate against walking time constraints
    waypoints = poiSelectionService.validateAndReduceStopsForWalkingTime(
      waypoints: waypoints,
      maximumWalkingTime: maximumWalkingTime,
      startingCity: startingCity
    )
    
    logger.info("🗺️ Generated route with \(waypoints.count) waypoints")
    return waypoints
  }
  
  /// Generate route from manually selected POIs with TSP optimization
  /// - Parameters:
  ///   - selectedPOIs: Manually selected POIs
  ///   - startLocation: Starting coordinate
  ///   - endpointOption: How to handle route endpoint
  ///   - customEndpoint: Custom endpoint name
  ///   - customEndpointCoordinates: Custom endpoint coordinates
  /// - Returns: Complete GeneratedRoute object
  /// - Throws: Error if route generation fails
  func generateManualRoute(
    selectedPOIs: [POI],
    startLocation: CLLocationCoordinate2D,
    endpointOption: EndpointOption,
    customEndpoint: String = "",
    customEndpointCoordinates: CLLocationCoordinate2D? = nil
  ) async throws -> GeneratedRoute {
    
    logger.info("🗺️ Generating manual route with \(selectedPOIs.count) selected POIs")
    
    // Step 1: Optimize waypoint order using TSP service
    let waypoints = tspService.optimizeManualRoute(
      selectedPOIs: selectedPOIs,
      startLocation: startLocation,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      customEndpointCoordinates: customEndpointCoordinates
    )
    
    // Step 2: Calculate routes between waypoints
    let routes = try await mapKitService.generateRoutesBetweenWaypoints(waypoints)
    
    // Step 3: Calculate totals
    let totalDistance = routes.reduce(0) { $0 + $1.distance }
    let totalTravelTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
    
    // Step 4: Calculate visit time
    let stops = max(0, waypoints.count - 2)
    let totalVisitTime = TimeInterval(stops * 45 * 60) // 45 min per stop
    let totalExperienceTime = totalTravelTime + totalVisitTime
    
    // Step 5: Create final route
    let route = GeneratedRoute(
      waypoints: waypoints,
      routes: routes,
      totalDistance: totalDistance,
      totalTravelTime: totalTravelTime,
      totalVisitTime: totalVisitTime,
      totalExperienceTime: totalExperienceTime
    )
    
    logger.info("🗺️ Manual route generated: \(waypoints.count) waypoints, \(String(format: "%.1f", totalDistance/1000))km, \(Int(totalTravelTime/60))min walking")
    
    return route
  }
  
  /// Generate complete route with MapKit connections
  /// - Parameter waypoints: Optimized waypoints
  /// - Returns: Complete GeneratedRoute object
  /// - Throws: Error if route calculation fails
  func generateCompleteRoute(from waypoints: [RoutePoint]) async throws -> GeneratedRoute {
    
    logger.info("🗺️ Generating complete route with MapKit for \(waypoints.count) waypoints")
    
    // Step 1: Generate routes between waypoints
    let routes = try await mapKitService.generateRoutesBetweenWaypoints(waypoints)
    
    // Step 2: Calculate metrics
    let totalDistance = routes.reduce(0) { $0 + $1.distance }
    let totalWalkingTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
    
    // Step 3: Calculate visit time based on categories
    let numberOfStops = max(0, waypoints.count - 2)
    var totalVisitTime: TimeInterval = 0
    
    // Use category-specific visit durations
    for i in 1..<waypoints.count-1 { // Skip start/end
      let visitDuration = poiSelectionService.getEstimatedVisitDuration(for: waypoints[i].category)
      totalVisitTime += visitDuration
    }
    
    // Fallback to average if no category-specific time calculated
    if totalVisitTime == 0 && numberOfStops > 0 {
      totalVisitTime = TimeInterval(numberOfStops * 45 * 60) // 45 min per stop
    }
    
    let totalExperienceTime = totalWalkingTime + totalVisitTime
    
    // Step 4: Create final route
    let route = GeneratedRoute(
      waypoints: waypoints,
      routes: routes,
      totalDistance: totalDistance,
      totalTravelTime: totalWalkingTime,
      totalVisitTime: totalVisitTime,
      totalExperienceTime: totalExperienceTime
    )
    
    logger.info("🗺️ Complete route generated: \(String(format: "%.1f", totalDistance/1000))km, \(Int(totalWalkingTime/60))min walking, \(Int(totalVisitTime/60))min visiting")
    
    return route
  }
  
  // MARK: - Helper Methods
  
  /// Add appropriate endpoint to waypoints based on endpoint option
  /// - Parameters:
  ///   - waypoints: Current waypoints
  ///   - endpointOption: Endpoint handling option
  ///   - customEndpoint: Custom endpoint name
  ///   - startCoordinate: Starting coordinate for roundtrip
  /// - Returns: Waypoints with endpoint added
  /// - Throws: Error if custom endpoint lookup fails
  private func addEndpointToWaypoints(
    waypoints: [RoutePoint],
    endpointOption: EndpointOption,
    customEndpoint: String,
    startCoordinate: CLLocationCoordinate2D
  ) async throws -> [RoutePoint] {
    
    var result = waypoints
    
    switch endpointOption {
    case .roundtrip:
      let endPoint = RoutePoint(
        name: "Zurück zum Start",
        coordinate: startCoordinate,
        address: "Startpunkt",
        category: .attraction
      )
      result.append(endPoint)
      
    case .lastPlace:
      // Route ends at last POI - no additional endpoint needed
      break
      
    case .custom:
      if !customEndpoint.isEmpty {
        do {
          let endLocationPoint = try await locationResolver.findLocation(query: customEndpoint)
          let endPoint = RoutePoint(
            name: customEndpoint,
            coordinate: endLocationPoint.coordinate,
            address: customEndpoint,
            category: .attraction
          )
          result.append(endPoint)
        } catch {
          logger.warning("🗺️ Failed to find custom endpoint '\(customEndpoint)', falling back to open end: \(error.localizedDescription)")
        }
      }
    }
    
    return result
  }
  
  /// Convert MaximumWalkingTime to legacy RouteLength for compatibility
  /// - Parameter maximumWalkingTime: New walking time constraint
  /// - Returns: Equivalent legacy RouteLength
  private func convertToLegacyRouteLength(_ maximumWalkingTime: MaximumWalkingTime) -> RouteLength {
    guard let minutes = maximumWalkingTime.minutes else {
      return .medium // Default for unlimited
    }
    
    switch minutes {
    case 0..<45:
      return .short
    case 45..<120:
      return .medium
    default:
      return .long
    }
  }
}
