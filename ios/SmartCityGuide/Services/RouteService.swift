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
  @Published var errorMessage: String?
  
  private var historyManager: RouteHistoryManager?
  
  init(historyManager: RouteHistoryManager? = nil) {
    self.historyManager = historyManager
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
        startLocationPoint = try await findLocation(query: cityName)
        startingCityName = cityName
      case .currentLocation(let location):
        startLocationPoint = try await createRoutePointFromCurrentLocation(location)
        startingCityName = startLocationPoint.name // Will be resolved from reverse geocoding
      }
      
      let startLocation = startLocationPoint.coordinate
      
      // Step 2: Generate route using POIs with new filters
      let waypoints: [RoutePoint]
      if let pois = availablePOIs, !pois.isEmpty {
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
      
      // Step 3: Generate routes between waypoints
      let routes = try await generateRoutesBetweenWaypoints(waypoints)
      
      // Step 4: Validate walking time and reduce stops if necessary
      let validatedWaypoints = try await validateAndReduceStopsForWalkingTime(
        waypoints: waypoints,
        routes: routes,
        maximumWalkingTime: maximumWalkingTime,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint
      )
      
      // Step 5: Generate final routes for validated waypoints
      let finalRoutes = try await generateRoutesBetweenWaypoints(validatedWaypoints)
      
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
        routeLength: convertToLegacyRouteLength(maximumWalkingTime),
        endpointOption: endpointOption
      )
      
    } catch {
      errorMessage = "Fehler beim Erstellen der Route: \(error.localizedDescription)"
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
      let startLocationPoint = try await findLocation(query: startingCity)
      let startLocation = startLocationPoint.coordinate
      
      // Step 2: Generate route using POIs (no fallback)
      let waypoints: [RoutePoint]
      if let pois = availablePOIs, !pois.isEmpty {
        // Use provided POIs for route generation
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
      errorMessage = "Fehler beim Erstellen der Route: \(error.localizedDescription)"
    }
    
    isGenerating = false
  }
  
  private func findLocation(query: String) async throws -> RoutePoint {
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = query
      request.resultTypes = [.address, .pointOfInterest]
      
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let firstResult = response?.mapItems.first {
          continuation.resume(returning: RoutePoint(from: firstResult))
        } else {
          continuation.resume(throwing: NSError(
            domain: "RouteService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Ort nicht gefunden: \(query)"]
          ))
        }
      }
    }
  }
  
  // MARK: - Phase 3: Current Location Integration
  private func createRoutePointFromCurrentLocation(_ location: CLLocation) async throws -> RoutePoint {
    return try await withCheckedThrowingContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error = error {
          self.logger.warning("Reverse geocoding failed: \(error.localizedDescription)")
          // Fallback: Create RoutePoint without reverse geocoding
          let routePoint = RoutePoint(
            name: "Mein Standort",
            coordinate: location.coordinate,
            address: "Aktuelle Position",
            category: .attraction // Default category for current location
          )
          continuation.resume(returning: routePoint)
        } else if let placemark = placemarks?.first {
          // Create RoutePoint with resolved location name
          let locationName = self.formatLocationName(from: placemark)
          let addressString = self.formatAddress(from: placemark)
          let routePoint = RoutePoint(
            name: locationName,
            coordinate: location.coordinate,
            address: addressString,
            category: .attraction
          )
          continuation.resume(returning: routePoint)
        } else {
          // Fallback: Create RoutePoint without resolved name
          let routePoint = RoutePoint(
            name: "Mein Standort",
            coordinate: location.coordinate,
            address: "Aktuelle Position",
            category: .attraction
          )
          continuation.resume(returning: routePoint)
        }
      }
    }
  }
  
  private func formatLocationName(from placemark: CLPlacemark) -> String {
    var components: [String] = []
    
    if let locality = placemark.locality {
      components.append(locality)
    }
    if let subLocality = placemark.subLocality {
      components.append(subLocality)
    }
    if let thoroughfare = placemark.thoroughfare {
      components.append(thoroughfare)
    }
    
    if components.isEmpty {
      return "Mein Standort"
    } else {
      return "Mein Standort (\(components.joined(separator: ", ")))"
    }
  }
  
  private func formatAddress(from placemark: CLPlacemark) -> String {
    var addressComponents: [String] = []
    
    if let thoroughfare = placemark.thoroughfare {
      if let subThoroughfare = placemark.subThoroughfare {
        addressComponents.append("\(thoroughfare) \(subThoroughfare)")
      } else {
        addressComponents.append(thoroughfare)
      }
    }
    
    if let locality = placemark.locality {
      addressComponents.append(locality)
    }
    
    if let postalCode = placemark.postalCode {
      addressComponents.append(postalCode)
    }
    
    if let country = placemark.country {
      addressComponents.append(country)
    }
    
    return addressComponents.isEmpty ? "Aktuelle Position" : addressComponents.joined(separator: ", ")
  }
  
  private func findOptimalRoute(
    startLocation: RoutePoint,
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    routeLength: RouteLength
  ) async throws -> [RoutePoint] {
    
    // Step 1: Get many potential places
    let potentialPlaces = try await findInterestingPlaces(
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
        let endLocation = try await findLocation(query: customEndpoint)
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
  
  private func findInterestingPlaces(
    near coordinate: CLLocationCoordinate2D,
    count: Int,
    maxDistance: Double,
    excluding excludedLocations: [RoutePoint] = []
  ) async throws -> [RoutePoint] {
    
    // Calculate how many places we need per category based on distribution
    let targetCounts = calculateCategoryTargets(totalCount: count)
    
    // Search for places in each category in parallel
    async let attractions = searchPlacesByCategory(.attraction, near: coordinate, maxDistance: maxDistance, count: targetCounts[.attraction] ?? 0)
    async let museums = searchPlacesByCategory(.museum, near: coordinate, maxDistance: maxDistance, count: targetCounts[.museum] ?? 0)
    async let parks = searchPlacesByCategory(.park, near: coordinate, maxDistance: maxDistance, count: targetCounts[.park] ?? 0)
    async let nationalParks = searchPlacesByCategory(.nationalPark, near: coordinate, maxDistance: maxDistance, count: targetCounts[.nationalPark] ?? 0)
    
    // Wait for all searches to complete
    let categoryResults = try await [attractions, museums, parks, nationalParks]
    var allPlaces: [RoutePoint] = []
    
    // Combine results from all categories
    for categoryPlaces in categoryResults {
      allPlaces.append(contentsOf: categoryPlaces)
    }
    
    // Filter out excluded locations and enforce distance limit
    let filteredPlaces = allPlaces.filter { place in
      // Check if not excluded
      let notExcluded = !excludedLocations.contains { excluded in
        self.distance(from: place.coordinate, to: excluded.coordinate) < 100 // 100m threshold
      }
      
      // Check distance from center
      let distanceFromCenter = self.distance(from: coordinate, to: place.coordinate)
      
      return notExcluded && distanceFromCenter <= maxDistance
    }
    
    // If we don't have enough places, fill with attractions as fallback
    var selectedPlaces = filteredPlaces
    if selectedPlaces.count < count {
      let fallbackPlaces = try await searchPlacesByCategory(.attraction, near: coordinate, maxDistance: maxDistance, count: count - selectedPlaces.count)
      selectedPlaces.append(contentsOf: fallbackPlaces.filter { fallback in
        !selectedPlaces.contains { existing in
          self.distance(from: fallback.coordinate, to: existing.coordinate) < 100
        }
      })
    }
    
    // Apply geographic distribution to avoid clustering
    let distributedPlaces = applyGeographicDistribution(selectedPlaces, maxCount: count)
    
    return distributedPlaces
  }
  
  private func calculateCategoryTargets(totalCount: Int) -> [PlaceCategory: Int] {
    var targets: [PlaceCategory: Int] = [:]
    var remainingCount = totalCount
    
    // Calculate targets based on distribution percentages
    for (category, percentage) in CategoryDistribution.target {
      let targetCount = Int(Double(totalCount) * percentage)
      targets[category] = targetCount
      remainingCount -= targetCount
    }
    
    // Distribute any remaining places to attractions
    if remainingCount > 0 {
      targets[.attraction] = (targets[.attraction] ?? 0) + remainingCount
    }
    
    return targets
  }
  
  private func searchPlacesByCategory(
    _ category: PlaceCategory,
    near coordinate: CLLocationCoordinate2D,
    maxDistance: Double,
    count: Int
  ) async throws -> [RoutePoint] {
    
    // Skip if no places needed for this category
    guard count > 0 else { return [] }
    
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKLocalSearch.Request()
      
      // Use category-specific search terms
      request.naturalLanguageQuery = category.searchTerms.joined(separator: " ")
      
      request.region = MKCoordinateRegion(
        center: coordinate,
        latitudinalMeters: maxDistance * 2,
        longitudinalMeters: maxDistance * 2
      )
      request.resultTypes = [.pointOfInterest]
      
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let mapItems = response?.mapItems {
          // Convert to RoutePoints and verify category classification
          let categoryPlaces = mapItems
            .map { RoutePoint(from: $0) }
            .filter { $0.category == category || category == .attraction } // Accept any for attractions as fallback
            .prefix(count * 2) // Get extra for better selection
          
          continuation.resume(returning: Array(categoryPlaces))
        } else {
          continuation.resume(returning: [])
        }
      }
    }
  }
  
  private func applyGeographicDistribution(_ places: [RoutePoint], maxCount: Int) -> [RoutePoint] {
    guard places.count > maxCount else {
      return places
    }
    
    var selectedPlaces: [RoutePoint] = []
    var remainingPlaces = places
    
    // Minimum distance between places (in meters) to avoid clustering
    let minDistanceBetweenPlaces: CLLocationDistance = 200
    
    // Select places with geographic distribution
    while selectedPlaces.count < maxCount && !remainingPlaces.isEmpty {
      if selectedPlaces.isEmpty {
        // Select first place randomly
        let randomIndex = Int.random(in: 0..<remainingPlaces.count)
        selectedPlaces.append(remainingPlaces.remove(at: randomIndex))
      } else {
        // Find the place that is furthest from all already selected places
        var bestPlace: RoutePoint?
        var bestMinDistance: CLLocationDistance = 0
        var bestIndex = 0
        
        for (index, candidate) in remainingPlaces.enumerated() {
          // Calculate minimum distance to any already selected place
          let minDistanceToSelected = selectedPlaces.map { selected in
            distance(from: candidate.coordinate, to: selected.coordinate)
          }.min() ?? 0
          
          // Prefer places that are farther away from existing selections
          if minDistanceToSelected > bestMinDistance {
            bestMinDistance = minDistanceToSelected
            bestPlace = candidate
            bestIndex = index
          }
        }
        
        // If we found a good candidate, add it
        if let place = bestPlace, bestMinDistance >= minDistanceBetweenPlaces {
          selectedPlaces.append(place)
          remainingPlaces.remove(at: bestIndex)
        } else {
          // If no place meets the distance criteria, just take the best available
          if let place = bestPlace {
            selectedPlaces.append(place)
            remainingPlaces.remove(at: bestIndex)
          } else {
            break
          }
        }
      }
    }
    
    return selectedPlaces
  }
  
  private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  private func generateRoutesBetweenWaypoints(_ waypoints: [RoutePoint]) async throws -> [MKRoute] {
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
  
  private func generateSingleRoute(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D
  ) async throws -> MKRoute {
    return try await withCheckedThrowingContinuation { continuation in
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
    if let maxStopsInt = maximumStops.intValue {
      effectiveMaxStops = maxStopsInt
    } else {
      // "Unbegrenzt" - use a reasonable upper limit
      effectiveMaxStops = min(20, availablePOIs.count)
    }
    
    // Step 2: Select best POIs for the route (using legacy logic for now)
    let selectedPOIs = POICacheService.shared.selectBestPOIs(
      from: availablePOIs,
      count: effectiveMaxStops,
      routeLength: convertToLegacyRouteLength(maximumWalkingTime),
      startCoordinate: startLocation,
      startingCity: startingCity
    )
    
    logger.info("🗺️ Selected \(selectedPOIs.count) POIs before distance filtering")
    
    // Step 3: Apply minimum POI distance filter
    let filteredPOIs = applyMinimumDistanceFilter(
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
          let endLocationPoint = try await findLocation(query: customEndpoint)
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
      waypoints = optimizeWaypointOrder(waypoints)
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
          let endLocationPoint = try await findLocation(query: customEndpoint)
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
      waypoints = optimizeWaypointOrder(waypoints)
    }
    
            logger.info("🗺️ Generated route with \(waypoints.count) waypoints")
    return waypoints
  }
  
  private func getEstimatedVisitDuration(for category: PlaceCategory) -> TimeInterval {
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
  
  private func optimizeWaypointOrder(_ waypoints: [RoutePoint]) -> [RoutePoint] {
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
    if waypoints.count > 3 { waypoints = optimizeWaypointOrder(waypoints) }

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
  
  // MARK: - New Filter Helper Functions
  
  /// Applies minimum distance filter between consecutive POIs
  private func applyMinimumDistanceFilter(
    pois: [POI],
    startLocation: CLLocationCoordinate2D,
    minimumDistance: MinimumPOIDistance
  ) -> [POI] {
    
    // If no minimum distance is specified, return all POIs
    guard let minDistanceMeters = minimumDistance.meters else {
      logger.info("🗺️ No minimum distance filter - returning all \(pois.count) POIs")
      return pois
    }
    
    logger.info("🗺️ Applying minimum distance filter: \(minimumDistance.rawValue)")
    
    var filteredPOIs: [POI] = []
    var previousLocation = startLocation
    
    // Sort POIs by distance from start to process in order
    let sortedPOIs = pois.sorted { poi1, poi2 in
      let distance1 = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
        .distance(from: CLLocation(latitude: poi1.coordinate.latitude, longitude: poi1.coordinate.longitude))
      let distance2 = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
        .distance(from: CLLocation(latitude: poi2.coordinate.latitude, longitude: poi2.coordinate.longitude))
      return distance1 < distance2
    }
    
    for poi in sortedPOIs {
      let distance = CLLocation(latitude: previousLocation.latitude, longitude: previousLocation.longitude)
        .distance(from: CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude))
      
      if distance >= minDistanceMeters {
        filteredPOIs.append(poi)
        previousLocation = poi.coordinate
        logger.debug("🗺️ Added POI: \(poi.name) (distance: \(Int(distance))m)")
      } else {
        logger.debug("🗺️ Skipped POI: \(poi.name) (distance: \(Int(distance))m < \(Int(minDistanceMeters))m)")
      }
    }
    
    logger.info("🗺️ Distance filtering result: \(filteredPOIs.count)/\(pois.count) POIs")
    return filteredPOIs
  }
  
  /// Validates walking time and reduces stops if necessary
  private func validateAndReduceStopsForWalkingTime(
    waypoints: [RoutePoint],
    routes: [MKRoute],
    maximumWalkingTime: MaximumWalkingTime,
    endpointOption: EndpointOption,
    customEndpoint: String
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
      
      // Check new walking time
      let testRoutes = try await generateRoutesBetweenWaypoints(reducedWaypoints)
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
  
  /// Converts new MaximumWalkingTime to legacy RouteLength for backwards compatibility
  private func convertToLegacyRouteLength(_ maximumWalkingTime: MaximumWalkingTime) -> RouteLength {
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