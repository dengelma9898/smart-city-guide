import Foundation
import MapKit
import CoreLocation

@MainActor
class RouteService: ObservableObject {
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
  
  func generateRoute(
    startingCity: String,
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    routeLength: RouteLength
  ) async {
    isGenerating = true
    errorMessage = nil
    generatedRoute = nil
    
    do {
      // Step 1: Find starting location
      let startLocation = try await findLocation(query: startingCity)
      
      // Step 2: Find interesting places based on endpoint option
      var waypoints: [RoutePoint]
      
      // Find optimal route combination that fits within distance limit
      waypoints = try await findOptimalRoute(
        startLocation: startLocation,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength
      )
      
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
      
      print("🔍 Teste Route: \(testRoute.count) Waypoints")
      print("   Luftlinie: \(Int(calculateTotalRouteDistance(testRoute)/1000))km")
      print("   Tatsächlich: \(Int(actualDistance/1000))km (Limit: \(Int(maxTotalDistance/1000))km)")
      
      // Check if this is better and within limits using ACTUAL distance
      if actualDistance <= maxTotalDistance && actualDistance < bestDistance {
        bestRoute = testRoute
        bestDistance = actualDistance
        print("   ✅ NEUE BESTE ROUTE: \(Int(actualDistance/1000))km")
      } else {
        print("   ❌ ZU LANG: \(Int(actualDistance/1000))km > \(Int(maxTotalDistance/1000))km")
      }
      
      // If we found a good short route, stop early
      if bestDistance <= maxTotalDistance * 0.8 {
        break
      }
    }
    
    // If no route found within distance limit, try with fewer stops
    if bestRoute.isEmpty && numberOfPlaces > 1 {
      print("⚠️ Keine Route mit \(numberOfPlaces) Stopps innerhalb \(Int(maxTotalDistance/1000))km gefunden")
      print("🔄 Versuche mit \(numberOfPlaces-1) Stopps...")
      
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
      
      // Small delay to avoid rate limiting
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
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
}