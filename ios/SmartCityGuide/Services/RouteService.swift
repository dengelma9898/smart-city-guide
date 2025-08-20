import Foundation
import MapKit
import CoreLocation
import os.log

// MARK: - Phase 3: Starting Location Type
enum StartingLocation {
  case city(String)
  case currentLocation(CLLocation)
}

@MainActor
class RouteService: ObservableObject {
  private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Route")
  
  @Published var isGenerating = false
  @Published var generatedRoute: GeneratedRoute?
  private var lastDiscoveredPOIs: [POI] = []
  @Published var errorMessage: String?
  
  private var historyManager: RouteHistoryManager?
  private let routeGenerationService: RouteGenerationService
  private let mapKitService: MapKitRouteService
  private let locationResolver: LocationResolverService
  private let poiDiscoveryService: POIDiscoveryService
  private let routeOptimizationService: RouteOptimizationService
  private let routeValidationService: RouteValidationService
  
  // Performance testing state - prevent infinite A/B testing loops
  private var hasRunPerformanceComparison = false
  
  init(
    historyManager: RouteHistoryManager? = nil,
    routeGenerationService: RouteGenerationService? = nil,
    mapKitService: MapKitRouteService? = nil,
    locationResolver: LocationResolverService? = nil,
    poiDiscoveryService: POIDiscoveryService? = nil,
    routeOptimizationService: RouteOptimizationService? = nil,
    routeValidationService: RouteValidationService? = nil
  ) {
    self.historyManager = historyManager
    self.routeGenerationService = routeGenerationService ?? RouteGenerationService()
    self.mapKitService = mapKitService ?? MapKitRouteService()
    self.locationResolver = locationResolver ?? LocationResolverService()
    self.poiDiscoveryService = poiDiscoveryService ?? POIDiscoveryService()
    self.routeOptimizationService = routeOptimizationService ?? RouteOptimizationService()
    self.routeValidationService = routeValidationService ?? RouteValidationService()
  }
  
  func setHistoryManager(_ manager: RouteHistoryManager) {
    self.historyManager = manager
  }
  
  // MARK: - New Route Generation (with enhanced filters)
  func generateRoute(
    startingCity: String,
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    availablePOIs: [POI]? = nil
  ) async {
    await generateRouteInternal(
      startingLocation: .city(startingCity),
      maximumStops: maximumStops,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      maximumWalkingTime: maximumWalkingTime,
      minimumPOIDistance: minimumPOIDistance,
      availablePOIs: availablePOIs
    )
  }
  
  // MARK: - Phase 3: Current Location Route Generation
  func generateRoute(
    fromCurrentLocation location: CLLocation,
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    availablePOIs: [POI]? = nil
  ) async {
    await generateRouteInternal(
      startingLocation: .currentLocation(location),
      maximumStops: maximumStops,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      maximumWalkingTime: maximumWalkingTime,
      minimumPOIDistance: minimumPOIDistance,
      availablePOIs: availablePOIs
    )
  }
  
  // MARK: - Error Handling
  
  /// Convert technical errors to user-friendly messages with transparent MapKit limitations
  private func handleRouteError(_ error: Error) -> String {
    let errorString = error.localizedDescription.lowercased()
    
    // Check for MapKit throttling errors
    if errorString.contains("throttled") || 
       errorString.contains("directions not available") ||
       errorString.contains("too many requests") ||
       (error as NSError).domain == "GEOErrorDomain" {
      return """
      🗺️ Kurze Pause nötig!
      
      Du warst sehr fleißig beim Planen! Unser Kartendienst braucht eine kleine Verschnaufpause (ca. 1 Minute), bevor wir weitere Routen berechnen können.
      
      💡 Das ist völlig normal bei intensiver Nutzung und zeigt, dass unsere App richtig schnell arbeitet!
      
      Versuch es gleich nochmal - dann klappt's wieder! ✨
      """
    }
    
    // Other route-related errors
    if errorString.contains("route") || errorString.contains("directions") {
      return "Routen-Berechnung nicht möglich. Prüfe deine Internetverbindung oder versuch es in einem anderen Bereich! 🗺️"
    }
    
    // POI/Location errors  
    if errorString.contains("not found") || errorString.contains("keine pois") {
      return "Keine interessanten Orte in diesem Bereich gefunden. Versuch es mit einer anderen Stadt! 🏙️"
    }
    
    // Network errors
    if errorString.contains("network") || errorString.contains("internet") {
      return "Internetverbindung unterbrochen. Prüfe dein WLAN oder deine mobile Daten! 📶"
    }
    
    // Fallback for any other errors
    return "Oops, da ist was schiefgelaufen! Versuch es nochmal - meistens klappt's beim zweiten Mal! 🔄"
  }
  
  // MARK: - Internal Route Generation
  private func generateRouteInternal(
    startingLocation: StartingLocation,
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    availablePOIs: [POI]? = nil
  ) async {
    isGenerating = true
    errorMessage = nil
    generatedRoute = nil
    
    do {
      // Step 1: Find starting location
      let startLocationPoint: RoutePoint
      let startingCityName: String
      
      switch startingLocation {
      case .city(let cityName):
        startLocationPoint = try await locationResolver.findLocation(query: cityName)
        startingCityName = cityName
      case .currentLocation(let location):
        startLocationPoint = try await locationResolver.createRoutePointFromCurrentLocation(location)
        startingCityName = startLocationPoint.name // Will be resolved from reverse geocoding
      }
      
      let startLocation = startLocationPoint.coordinate

      // Log effective parameters once at start for diagnostics
      let stopsLog = String(maximumStops.intValue)
      let maxTimeLog = maximumWalkingTime.minutes.map { "\($0)min" } ?? "open-end"
      let minDistLog = minimumPOIDistance.meters.map { "\(Int($0))m" } ?? "none"
      logger.info("🧭 Route Params → start='\(startingCityName, privacy: .public)' stops=\(stopsLog, privacy: .public) maxTime=\(maxTimeLog, privacy: .public) minDist=\(minDistLog, privacy: .public) availPOIs=\(availablePOIs?.count ?? 0)")
      
      // Step 2: Generate route using POIs with new filters
      let waypoints: [RoutePoint]
      if let pois = availablePOIs, !pois.isEmpty {
        lastDiscoveredPOIs = pois
        waypoints = try await findOptimalRouteWithNewFilters(
          startLocation: startLocation,
          availablePOIs: pois,
          maximumStops: maximumStops,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          maximumWalkingTime: maximumWalkingTime,
          minimumPOIDistance: minimumPOIDistance,
          startingCity: startingCityName
        )
      } else {
        throw NSError(
          domain: "RouteService",
          code: 404,
          userInfo: [NSLocalizedDescriptionKey: "Keine POIs für diese Stadt verfügbar. Bitte versuchen Sie eine andere Stadt."]
        )
      }
      
      // Step 3: Generate routes between waypoints (for walking time validation, no performance logging)
      let routes = try await generateRoutesBetweenWaypoints(waypoints, logPerformance: false)
      
      // Step 4: Validate walking time and reduce stops if necessary
      let validatedWaypoints = try await routeValidationService.validateAndReduceStopsForWalkingTime(
        waypoints: waypoints,
        routes: routes,
        maximumWalkingTime: maximumWalkingTime,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeGenerator: { waypoints, logPerformance in
          try await self.generateRoutesBetweenWaypoints(waypoints, logPerformance: logPerformance)
        }
      )
      
      // Step 5: Generate final routes for validated waypoints (with performance logging)
      let finalRoutes = try await generateRoutesBetweenWaypoints(validatedWaypoints, logPerformance: true)
      
      // Step 6: Calculate totals
      let totalDistance = finalRoutes.reduce(0) { $0 + $1.distance }
      let totalWalkingTime = finalRoutes.reduce(0) { $0 + $1.expectedTravelTime }
      
      // Calculate visit time (30min to 1hr per stop, excluding start/end points)
      let numberOfStops = max(0, validatedWaypoints.count - 2)
      let minVisitTime = TimeInterval(numberOfStops * 30 * 60) // 30 min per stop
      let maxVisitTime = TimeInterval(numberOfStops * 60 * 60) // 60 min per stop
      let averageVisitTime = (minVisitTime + maxVisitTime) / 2
      
      let totalExperienceTime = totalWalkingTime + averageVisitTime
      
      let route = GeneratedRoute(
        waypoints: validatedWaypoints,
        routes: finalRoutes,
        totalDistance: totalDistance,
        totalTravelTime: totalWalkingTime,
        totalVisitTime: averageVisitTime,
        totalExperienceTime: totalExperienceTime
      )
      
      generatedRoute = route
      
      // Auto-save route to history (convert to legacy parameters for storage)
      historyManager?.saveRoute(
        route,
        routeLength: routeValidationService.convertToLegacyRouteLength(maximumWalkingTime),
        endpointOption: endpointOption
      )
      
    } catch {
      errorMessage = handleRouteError(error)
    }
    
    isGenerating = false
  }
  
  // MARK: - Legacy Route Generation (for backwards compatibility)
  func generateRoute(
    startingCity: String,
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    routeLength: RouteLength,
    availablePOIs: [POI]? = nil
  ) async {
    isGenerating = true
    errorMessage = nil
    generatedRoute = nil
    
    do {
      // Step 1: Find starting location
      let startLocationPoint = try await locationResolver.findLocation(query: startingCity)
      let startLocation = startLocationPoint.coordinate
      
      // Step 2: Generate route using POIs (no fallback)
      let waypoints: [RoutePoint]
      if let pois = availablePOIs, !pois.isEmpty {
        // Use provided POIs for route generation
        lastDiscoveredPOIs = pois
        waypoints = try await findOptimalRouteWithPOIs(
          startLocation: startLocation,
          availablePOIs: pois,
          numberOfPlaces: numberOfPlaces,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          routeLength: routeLength,
          startingCity: startingCity
        )
      } else {
        // No POIs available - throw error
        throw NSError(
          domain: "RouteService",
          code: 404,
          userInfo: [NSLocalizedDescriptionKey: "Keine POIs für diese Stadt verfügbar. Bitte versuchen Sie eine andere Stadt."]
        )
      }
      
      // Step 4: Generate routes between waypoints
      let routes = try await generateRoutesBetweenWaypoints(waypoints)
      
      // Step 5: Calculate totals
      let totalDistance = routes.reduce(0) { $0 + $1.distance }
      let totalWalkingTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
      
      // Calculate visit time (30min to 1hr per stop, excluding start/end points)
      let numberOfStops = max(0, waypoints.count - 2)
      let minVisitTime = TimeInterval(numberOfStops * 30 * 60) // 30 min per stop
      let maxVisitTime = TimeInterval(numberOfStops * 60 * 60) // 60 min per stop
      let averageVisitTime = (minVisitTime + maxVisitTime) / 2
      
      let totalExperienceTime = totalWalkingTime + averageVisitTime
      
      let route = GeneratedRoute(
        waypoints: waypoints,
        routes: routes,
        totalDistance: totalDistance,
        totalTravelTime: totalWalkingTime,
        totalVisitTime: averageVisitTime,
        totalExperienceTime: totalExperienceTime
      )
      
      generatedRoute = route
      
      // Auto-save route to history
      historyManager?.saveRoute(
        route,
        routeLength: routeLength,
        endpointOption: endpointOption
      )
      
    } catch {
      errorMessage = handleRouteError(error)
    }
    
    isGenerating = false
  }
  

  
  private func findOptimalRoute(
    startLocation: RoutePoint,
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    routeLength: RouteLength
  ) async throws -> [RoutePoint] {
    
    // Step 1: Get many potential places
    let potentialPlaces = try await poiDiscoveryService.findInterestingPlaces(
      near: startLocation.coordinate,
      count: numberOfPlaces * 5, // Get 5x more places for better selection
      maxDistance: routeLength.searchRadiusMeters,
      excluding: [startLocation]
    )
    
    // Always try with available places, even if fewer than requested
    // The distance checking will handle reduction if needed
    let actualCount = min(numberOfPlaces, potentialPlaces.count)
    
    guard actualCount > 0 else {
      throw NSError(
        domain: "RouteService", 
        code: 404,
        userInfo: [NSLocalizedDescriptionKey: "Keine interessanten Orte in der Nähe von \(startLocation.name) gefunden."]
      )
    }
    
    // Step 2: Try different combinations to find optimal route
    let bestCombination = try await findBestRouteCombination(
      startLocation: startLocation,
      potentialPlaces: potentialPlaces,
      numberOfPlaces: actualCount,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      maxTotalDistance: routeLength.maxTotalDistanceMeters
    )
    
    return bestCombination
  }
  
  private func findBestRouteCombination(
    startLocation: RoutePoint,
    potentialPlaces: [RoutePoint],
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maxTotalDistance: Double
  ) async throws -> [RoutePoint] {
    
    var bestRoute: [RoutePoint] = []
    var bestDistance: Double = Double.infinity
    
    // Try up to 10 different combinations
    let maxAttempts = min(10, potentialPlaces.count)
    
    for attempt in 0..<maxAttempts {
      // Select a different combination of places
      let selectedPlaces = selectPlacesForAttempt(
        from: potentialPlaces,
        count: numberOfPlaces,
        attempt: attempt
      )
      
      // Build route with endpoint logic
      let testRoute = try await buildRouteWithEndpoint(
        startLocation: startLocation,
        places: selectedPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint
      )
      
      // Calculate ACTUAL walking distance using real routes
      let testRoutes = try await generateRoutesBetweenWaypoints(testRoute)
      let actualDistance = testRoutes.reduce(0) { $0 + $1.distance }
      
      // Check if this is better and within limits using ACTUAL distance
      if actualDistance <= maxTotalDistance && actualDistance < bestDistance {
        bestRoute = testRoute
        bestDistance = actualDistance
      }
      
      // If we found a good short route, stop early
      if bestDistance <= maxTotalDistance * 0.8 {
        break
      }
    }
    
    // If no route found within distance limit, try with fewer stops
    if bestRoute.isEmpty && numberOfPlaces > 1 {
      
      // Retry with one fewer place
      return try await findBestRouteCombination(
        startLocation: startLocation,
        potentialPlaces: potentialPlaces,
        numberOfPlaces: numberOfPlaces - 1,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        maxTotalDistance: maxTotalDistance
      )
    }
    
    // If still no route found, throw error instead of exceeding distance limit
    guard !bestRoute.isEmpty else {
      throw NSError(
        domain: "RouteService",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "Keine Route innerhalb der gewünschten Entfernung von \(Int(maxTotalDistance/1000))km möglich. Versuchen Sie eine längere Routenoption oder weniger Zwischenstopps."]
      )
    }
    
    return bestRoute
  }
  
  private func selectPlacesForAttempt(
    from places: [RoutePoint],
    count: Int,
    attempt: Int
  ) -> [RoutePoint] {
    let startIndex = attempt * 2 % max(1, places.count - count)
    let endIndex = min(startIndex + count, places.count)
    return Array(places[startIndex..<endIndex])
  }
  
  private func buildRouteWithEndpoint(
    startLocation: RoutePoint,
    places: [RoutePoint],
    endpointOption: EndpointOption,
    customEndpoint: String
  ) async throws -> [RoutePoint] {
    
    switch endpointOption {
    case .roundtrip:
      return [startLocation] + places + [startLocation]
      
    case .custom:
      if !customEndpoint.isEmpty {
        let endLocation = try await locationResolver.findLocation(query: customEndpoint)
        return [startLocation] + places + [endLocation]
      } else {
        return [startLocation] + places
      }
      
    case .lastPlace:
      return [startLocation] + places
    }
  }
  
  private func calculateTotalRouteDistance(_ waypoints: [RoutePoint]) -> Double {
    var totalDistance: Double = 0
    
    for i in 0..<waypoints.count-1 {
      let distance = distance(
        from: waypoints[i].coordinate,
        to: waypoints[i+1].coordinate
      )
      totalDistance += distance
    }
    
    return totalDistance
  }
  

  

  

  

  
  private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    return locationResolver.distance(from: from, to: to)
  }
  
  private func generateRoutesBetweenWaypoints(_ waypoints: [RoutePoint], logPerformance: Bool = true) async throws -> [MKRoute] {
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
  
  private func generateSingleRoute(
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
          continuation.resume(throwing: error)
        } else if let route = response?.routes.first {
          continuation.resume(returning: route)
        } else {
          continuation.resume(throwing: NSError(
            domain: "RouteService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Keine Route gefunden"]
          ))
        }
      }
    }
    
    // Cache the successful result
    if FeatureFlags.routeCachingEnabled {
      RouteCacheService.shared.cacheRoute(route, from: start, to: end)
    }
    
    return route
  }
  
  // MARK: - POI-based Route Generation
  
  // MARK: - New Enhanced Route Generation with Filters
  private func findOptimalRouteWithNewFilters(
    startLocation: CLLocationCoordinate2D,
    availablePOIs: [POI],
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    startingCity: String
  ) async throws -> [RoutePoint] {
    
    logger.info("🗺️ Generating route with \(availablePOIs.count) available POIs, max stops: \(maximumStops.rawValue), min distance: \(minimumPOIDistance.rawValue)")
    
    // Step 1: Determine effective maximum stops
    let effectiveMaxStops: Int
    effectiveMaxStops = maximumStops.intValue
    
    // Step 2: Select best POIs for the route (using legacy logic for now)
    let selectedPOIs = POICacheService.shared.selectBestPOIs(
      from: availablePOIs,
      count: effectiveMaxStops,
      routeLength: routeValidationService.convertToLegacyRouteLength(maximumWalkingTime),
      startCoordinate: startLocation,
      startingCity: startingCity
    )
    
    logger.info("🗺️ Selected \(selectedPOIs.count) POIs before distance filtering")
    
    // Step 3: Apply minimum POI distance filter
    let filteredPOIs = poiDiscoveryService.applyMinimumDistanceFilter(
      pois: selectedPOIs,
      startLocation: startLocation,
      minimumDistance: minimumPOIDistance
    )
    
    logger.info("🗺️ \(filteredPOIs.count) POIs remain after distance filtering")
    
    // Step 4: Convert POIs to RoutePoints
    var waypoints: [RoutePoint] = []
    
    // Add starting point
    let startPoint = RoutePoint(
      name: "Start",
      coordinate: startLocation,
      address: "Startpunkt",
      category: .attraction
    )
    waypoints.append(startPoint)
    
    // Add POI waypoints with full contact information
    for poi in filteredPOIs {
      let routePoint = RoutePoint(from: poi)
      waypoints.append(routePoint)
    }
    
    // Step 5: Handle endpoint option
    switch endpointOption {
    case .roundtrip:
      let endPoint = RoutePoint(
        name: "Zurück zum Start",
        coordinate: startLocation,
        address: "Startpunkt",
        category: .attraction
      )
      waypoints.append(endPoint)
      
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
          waypoints.append(endPoint)
        } catch {
          logger.warning("🗺️ Failed to find custom endpoint, falling back to open end")
        }
      }
    }
    
    // Step 6: Optimize the order of waypoints for shortest route
    if waypoints.count > 3 { // Only optimize if we have multiple intermediate points
      waypoints = routeOptimizationService.optimizeWaypointOrder(waypoints)
    }
    
    logger.info("🗺️ Generated route with \(waypoints.count) waypoints")
    return waypoints
  }
  
  // MARK: - Legacy POI Route Generation (for backwards compatibility)
  private func findOptimalRouteWithPOIs(
    startLocation: CLLocationCoordinate2D,
    availablePOIs: [POI],
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    routeLength: RouteLength,
    startingCity: String
  ) async throws -> [RoutePoint] {
    
            logger.info("🗺️ Generating route with \(availablePOIs.count) available POIs")
    
    // Step 1: Select best POIs for the route
    let selectedPOIs = POICacheService.shared.selectBestPOIs(
      from: availablePOIs,
      count: numberOfPlaces,
      routeLength: routeLength,
      startCoordinate: startLocation,
      startingCity: startingCity
    )
    
            logger.info("🗺️ Selected \(selectedPOIs.count) POIs for route")
    
    // Step 2: Convert POIs to RoutePoints
    var waypoints: [RoutePoint] = []
    
    // Add starting point
    let startPoint = RoutePoint(
      name: "Start",
      coordinate: startLocation,
      address: "Startpunkt",
      category: .attraction
    )
    waypoints.append(startPoint)
    
    // Add POI waypoints with full contact information
    for poi in selectedPOIs {
      let routePoint = RoutePoint(from: poi) // ✨ Verwende POI-Initializer für Kontakt-/Öffnungszeiten-Daten
      waypoints.append(routePoint)
    }
    
    // Step 3: Handle endpoint option
    switch endpointOption {
    case .roundtrip:
      // Add starting point as endpoint for roundtrip
      let endPoint = RoutePoint(
        name: "Zurück zum Start",
        coordinate: startLocation,
        address: "Startpunkt",
        category: .attraction
      )
      waypoints.append(endPoint)
      
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
          waypoints.append(endPoint)
        } catch {
          logger.warning("🗺️ Failed to find custom endpoint, falling back to open end")
        }
      }
    }
    
    // Step 4: Optimize the order of waypoints for shortest route
    if waypoints.count > 3 { // Only optimize if we have multiple intermediate points
      waypoints = routeOptimizationService.optimizeWaypointOrder(waypoints)
    }
    
            logger.info("🗺️ Generated route with \(waypoints.count) waypoints")
    return waypoints
  }
  

  


  // MARK: - Manual Route API
  /// Generate route from manually selected POIs (TSP-style ordering with start/end fixed)
  func generateManualRoute(
    selectedPOIs: [POI],
    startLocation: CLLocationCoordinate2D,
    endpointOption: EndpointOption,
    customEndpoint: String = "",
    customEndpointCoordinates: CLLocationCoordinate2D? = nil
  ) async throws -> GeneratedRoute {
    isGenerating = true
    errorMessage = nil
    defer { isGenerating = false }

    // Build initial waypoints
    var waypoints: [RoutePoint] = []
    let start = RoutePoint(name: "Start", coordinate: startLocation, address: "Startpunkt", category: .attraction)
    waypoints.append(start)
    for poi in selectedPOIs { waypoints.append(RoutePoint(from: poi)) }
    let end: RoutePoint
    switch endpointOption {
    case .roundtrip:
      end = start
    case .lastPlace:
      end = waypoints.last ?? start
    case .custom:
      let coord = customEndpointCoordinates ?? startLocation
      end = RoutePoint(name: customEndpoint.isEmpty ? "Ziel" : customEndpoint, coordinate: coord, address: customEndpoint, category: .attraction)
    }
    if end.coordinate.latitude != start.coordinate.latitude || end.coordinate.longitude != start.coordinate.longitude {
      waypoints.append(end)
    } else {
      waypoints.append(start)
    }

    // Optimize order (start/end fixed)
    if waypoints.count > 3 { waypoints = routeOptimizationService.optimizeWaypointOrder(waypoints) }

    // Calculate routes
    let routes = try await generateRoutesBetweenWaypoints(waypoints)
    let totalDistance = routes.reduce(0) { $0 + $1.distance }
    let totalTravelTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
    let stops = max(0, waypoints.count - 2)
    let totalVisitTime = TimeInterval(stops * 45 * 60)
    let totalExperienceTime = totalTravelTime + totalVisitTime

    let route = GeneratedRoute(
      waypoints: waypoints,
      routes: routes,
      totalDistance: totalDistance,
      totalTravelTime: totalTravelTime,
      totalVisitTime: totalVisitTime,
      totalExperienceTime: totalExperienceTime
    )

    // Persist with default meta (best-effort). Use medium + endpointOption as current conventions
    let defaultLength: RouteLength = .medium
    historyManager?.saveRoute(route, routeLength: defaultLength, endpointOption: endpointOption)
    generatedRoute = route
    return route
  }
  
  // MARK: - Delegation to Specialized Services
  
  // All specialized functionality has been extracted to dedicated services:
  // - POIDiscoveryService: POI finding, filtering, geographic distribution
  // - RouteOptimizationService: TSP optimization, visit duration estimation  
  // - RouteValidationService: Walking time validation, legacy conversion
  
  // MARK: - Wikipedia Integration Support
  
  func getDiscoveredPOIs() async -> [POI]? {
    return lastDiscoveredPOIs.isEmpty ? nil : lastDiscoveredPOIs
  }
}