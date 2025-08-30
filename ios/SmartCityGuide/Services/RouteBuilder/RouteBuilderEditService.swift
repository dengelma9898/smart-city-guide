import Foundation
import MapKit

// Minimal model to support edit flows without the old RouteEditModels
struct EditableRouteSpot: Identifiable, Equatable {
  let id = UUID()
  let originalWaypoint: RoutePoint
  let waypointIndex: Int
  let alternativePOIs: [POI]
  let currentPOI: POI?
  let replacedPOIs: [POI]
  
  static func == (lhs: EditableRouteSpot, rhs: EditableRouteSpot) -> Bool {
    lhs.id == rhs.id
  }
}

/// Service for managing route editing operations (replace, insert, delete POIs)
@MainActor
class RouteBuilderEditService: ObservableObject {
  
  // MARK: - Published State
  
  @Published var replacedPOIsHistory: [Int: [POI]] = [:]
  
  // MARK: - Dependencies
  
  private let routeService: RouteService
  private let wikipediaService: RouteWikipediaService
  
  // MARK: - Initialization
  
  init(routeService: RouteService, wikipediaService: RouteWikipediaService) {
    self.routeService = routeService
    self.wikipediaService = wikipediaService
  }
  
  // MARK: - Public Interface
  
  /// Start editing a waypoint and create EditableRouteSpot
  func createEditableSpot(for index: Int, discoveredPOIs: [POI]) -> EditableRouteSpot? {
    guard let route = routeService.generatedRoute,
          index >= 0 && index < route.waypoints.count else { return nil }
    
    let waypoint = route.waypoints[index]
    
    // Create editable spot with alternatives from current cache
    let alternatives = findAlternativePOIsWithHistory(
      for: waypoint, 
      at: index, 
      from: discoveredPOIs
    )
    
    return EditableRouteSpot(
      originalWaypoint: waypoint,
      waypointIndex: index,
      alternativePOIs: alternatives,
      currentPOI: findCurrentPOI(for: waypoint, in: discoveredPOIs),
      replacedPOIs: replacedPOIsHistory[index] ?? []
    )
  }
  
  /// Handle spot change from route edit
  func handleSpotChange(
    _ newPOI: POI, 
    editableSpot: EditableRouteSpot?,
    discoveredPOIs: [POI],
    startingCity: String,
    onDismiss: () -> Void
  ) async -> GeneratedRoute? {
    
    // Capture index before clearing state
    let capturedIndex: Int? = editableSpot?.waypointIndex
    
    // Track the replaced POI in history
    if let e = editableSpot {
      let waypointIndex = e.waypointIndex
      if let currentPOI = findCurrentPOI(for: e.originalWaypoint, in: discoveredPOIs) {
        var history = replacedPOIsHistory[waypointIndex] ?? []
        if !history.contains(where: { $0.id == currentPOI.id }) {
          history.append(currentPOI)
          replacedPOIsHistory[waypointIndex] = history
        }
      }
    }
    
    // Close edit sheet immediately for responsive UX
    onDismiss()
    
    // Update UI to show loading
    routeService.isGenerating = true
    routeService.errorMessage = nil
    
    if let index = capturedIndex, let route = routeService.generatedRoute {
      // Recalculate in background and show global loading in parent
      return await generateUpdatedRoute(
        replacing: index,
        with: newPOI,
        in: route,
        discoveredPOIs: discoveredPOIs,
        startingCity: startingCity
      )
    }
    
    return nil
  }
  
  /// Insert a new POI into the current route
  func insertPOI(
    _ poi: POI, 
    at index: Int? = nil,
    discoveredPOIs: [POI],
    startingCity: String
  ) async -> Bool {
    guard let currentRoute = routeService.generatedRoute else { return false }
    
    // Verhindere Duplikate
    if isAlreadyInRoute(poi, route: currentRoute) {
      routeService.errorMessage = "Dieser Stopp ist bereits in deiner Route."
      return false
    }
    
    routeService.isGenerating = true
    routeService.errorMessage = nil
    
    do {
      var newWaypoints = currentRoute.waypoints
      let insertIndexDefault = max(1, newWaypoints.count - 1)
      let safeIndex: Int = {
        if let idx = index {
          return min(max(1, idx), max(1, newWaypoints.count - 1))
        } else {
          return insertIndexDefault
        }
      }()
      
      let newWaypoint = RoutePoint(from: poi)
      newWaypoints.insert(newWaypoint, at: safeIndex)
      
      let newRoutes = try await recalculateWalkingRoutes(for: newWaypoints)
      let newTotalDistance = newRoutes.reduce(0) { $0 + $1.distance }
      let newTotalTravelTime: TimeInterval = newRoutes.reduce(0) { $0 + $1.expectedTravelTime }
      let newTotalExperienceTime: TimeInterval = newTotalTravelTime + currentRoute.totalVisitTime
      
      let updatedRoute = GeneratedRoute(
        waypoints: newWaypoints,
        routes: newRoutes,
        totalDistance: newTotalDistance,
        totalTravelTime: newTotalTravelTime,
        totalVisitTime: currentRoute.totalVisitTime,
        totalExperienceTime: newTotalExperienceTime,
        endpointOption: currentRoute.endpointOption
      )
      
      routeService.generatedRoute = updatedRoute
      routeService.isGenerating = false
      
      // Enrichment erneut anstoßen
      await wikipediaService.enrichRoute(updatedRoute, from: discoveredPOIs, startingCity: startingCity)
      
      return true
      
    } catch {
      routeService.isGenerating = false
      routeService.errorMessage = "Hinzufügen fehlgeschlagen: \(error.localizedDescription)"
      return false
    }
  }
  
  /// Delete a POI from the current route
  func deletePOI(
    at index: Int,
    discoveredPOIs: [POI],
    startingCity: String,
    onDismiss: (() -> Void)? = nil
  ) async -> Bool {
    guard let currentRoute = routeService.generatedRoute else { return false }
    let count = currentRoute.waypoints.count
    // Erlaube nur Zwischenstopps (nicht Start = 0, nicht Ziel = count-1)
    guard count >= 3, index > 0, index < count - 1 else { return false }
    
    // Spezialfall: Nur noch 1 Zwischenstopp vorhanden und wird gelöscht → zurück zur Planung
    let intermediateCount = max(0, count - 2)
    let isDeletingLastIntermediate = (intermediateCount == 1)
    
    routeService.isGenerating = true
    routeService.errorMessage = nil
    
    do {
      var newWaypoints = currentRoute.waypoints
      newWaypoints.remove(at: index)
      
      let newRoutes = try await recalculateWalkingRoutes(for: newWaypoints)
      let newTotalDistance = newRoutes.reduce(0) { $0 + $1.distance }
      let newTotalTravelTime: TimeInterval = newRoutes.reduce(0) { $0 + $1.expectedTravelTime }
      let newTotalExperienceTime: TimeInterval = newTotalTravelTime + currentRoute.totalVisitTime
      
      let updatedRoute = GeneratedRoute(
        waypoints: newWaypoints,
        routes: newRoutes,
        totalDistance: newTotalDistance,
        totalTravelTime: newTotalTravelTime,
        totalVisitTime: currentRoute.totalVisitTime,
        totalExperienceTime: newTotalExperienceTime,
        endpointOption: currentRoute.endpointOption
      )
      
      if isDeletingLastIntermediate {
        // Navigiere zurück zur Planung (Sheet/Screen schließen)
        routeService.isGenerating = false
        onDismiss?()
      } else {
        routeService.generatedRoute = updatedRoute
        routeService.isGenerating = false
        
        // Wikipedia-Enrichment für aktualisierte Route
        await wikipediaService.enrichRoute(updatedRoute, from: discoveredPOIs, startingCity: startingCity)
      }
      
      return true
      
    } catch {
      routeService.isGenerating = false
      routeService.errorMessage = "Löschen fehlgeschlagen: \(error.localizedDescription)"
      return false
    }
  }
  
  /// Full re-optimization after adding multiple POIs
  func reoptimizeRouteWithAddedPOIs(
    selectedPOIs: [POI],
    startingCoordinates: CLLocationCoordinate2D?,
    endpointOption: EndpointOption,
    customEndpoint: String,
    customEndpointCoordinates: CLLocationCoordinate2D?,
    discoveredPOIs: [POI],
    startingCity: String
  ) async -> Bool {
    guard let currentRoute = routeService.generatedRoute else { return false }
    
    routeService.isGenerating = true
    routeService.errorMessage = nil
    
    do {
      // Bestehende Zwischenstopps der aktuellen Route als POIs abbilden
      let existingWaypoints = Array(currentRoute.waypoints.dropFirst().dropLast())
      var existingPOIs: [POI] = existingWaypoints.compactMap { waypoint in
        findCurrentPOI(for: waypoint, in: discoveredPOIs)
      }
      
      // Dedup mit bereits im Add-Flow gewählten POIs
      for poi in selectedPOIs {
        if !existingPOIs.contains(where: { $0.id == poi.id }) {
          existingPOIs.append(poi)
        }
      }
      
      // Start-Koordinate ermitteln
      let startCoord: CLLocationCoordinate2D = {
        if let coords = startingCoordinates { return coords }
        return currentRoute.waypoints.first?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
      }()
      
      // Vollständige Neu-Optimierung (TSP) mit allen ausgewählten POIs
      let updatedRoute = try await routeService.generateManualRoute(
        selectedPOIs: existingPOIs,
        startLocation: startCoord,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        customEndpointCoordinates: customEndpointCoordinates
      )
      
      await wikipediaService.enrichRoute(updatedRoute, from: discoveredPOIs, startingCity: startingCity)
      
      return true
      
    } catch {
      routeService.errorMessage = "Optimierung fehlgeschlagen: \(error.localizedDescription)"
      return false
    }
  }
  
  // MARK: - Helper Methods
  
  /// Find alternative POIs for a waypoint including replaced POIs from history
  private func findAlternativePOIsWithHistory(
    for waypoint: RoutePoint, 
    at waypointIndex: Int, 
    from cachedPOIs: [POI]
  ) -> [POI] {
    // Get previously replaced POIs for this position
    let replacedPOIs = replacedPOIsHistory[waypointIndex] ?? []
    
    // Combine cached POIs with replaced POIs (excluding current route POIs)
    let allPossiblePOIs = cachedPOIs + replacedPOIs
    
    guard let route = routeService.generatedRoute else { return [] }
    
    return allPossiblePOIs.filter { poi in
      // Only exclude POIs already in route - NO distance restriction
      return !isAlreadyInRoute(poi, route: route)
    }
    .sorted { poi1, poi2 in
      // Prioritize previously replaced POIs (show them first)
      let poi1WasReplaced = replacedPOIs.contains { $0.id == poi1.id }
      let poi2WasReplaced = replacedPOIs.contains { $0.id == poi2.id }
      
      if poi1WasReplaced && !poi2WasReplaced {
        return true
      } else if !poi1WasReplaced && poi2WasReplaced {
        return false
      }
      
      // Then sort by category match
      let categoryMatch1 = poi1.category == waypoint.category
      let categoryMatch2 = poi2.category == waypoint.category
      
      if categoryMatch1 && !categoryMatch2 {
        return true
      } else if !categoryMatch1 && categoryMatch2 {
        return false
      }
      
      // Finally sort by distance
      let distance1 = calculateDistance(from: poi1.coordinate, to: waypoint.coordinate)
      let distance2 = calculateDistance(from: poi2.coordinate, to: waypoint.coordinate)
      return distance1 < distance2
    }
    .prefix(30) // Increased limit for more alternatives
    .map { $0 }
  }
  
  /// Check if POI is already in the current route
  private func isAlreadyInRoute(_ poi: POI, route: GeneratedRoute) -> Bool {
    return route.waypoints.contains { waypoint in
      poi.name.lowercased() == waypoint.name.lowercased() &&
      calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50 // 50m tolerance
    }
  }
  
  /// Find current POI for a waypoint (if it exists in cache)
  private func findCurrentPOI(for waypoint: RoutePoint, in discoveredPOIs: [POI]) -> POI? {
    return discoveredPOIs.first { poi in
      poi.name.lowercased() == waypoint.name.lowercased() &&
      calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50
    }
  }
  
  /// Calculate distance between coordinates
  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  /// Generate updated route with new POI
  private func generateUpdatedRoute(
    replacing waypointIndex: Int,
    with newPOI: POI,
    in originalRoute: GeneratedRoute,
    discoveredPOIs: [POI],
    startingCity: String
  ) async -> GeneratedRoute? {
    
    do {
      // Update the route by replacing the waypoint
      var newWaypoints = originalRoute.waypoints
      let newWaypoint = RoutePoint(from: newPOI)
      newWaypoints[waypointIndex] = newWaypoint
      
      // Recalculate walking routes between waypoints
      let newRoutes = try await recalculateWalkingRoutes(for: newWaypoints)
      
      // Calculate new metrics (keep units consistent: seconds)
      let newTotalDistance = newRoutes.reduce(0) { $0 + $1.distance }
      let newTotalTravelTime: TimeInterval = newRoutes.reduce(0) { $0 + $1.expectedTravelTime }
      
      // Keep original visit time, update experience time
      let newTotalExperienceTime: TimeInterval = newTotalTravelTime + originalRoute.totalVisitTime
      
      let updatedRoute = GeneratedRoute(
        waypoints: newWaypoints,
        routes: newRoutes,
        totalDistance: newTotalDistance,
        totalTravelTime: newTotalTravelTime,
        totalVisitTime: originalRoute.totalVisitTime,
        totalExperienceTime: newTotalExperienceTime,
        endpointOption: originalRoute.endpointOption
      )
      
      routeService.generatedRoute = updatedRoute
      routeService.isGenerating = false
      
      // Re-enrich the updated route with Wikipedia data
      Task {
        await wikipediaService.enrichRoute(updatedRoute, from: discoveredPOIs, startingCity: startingCity)
      }
      
      return updatedRoute
      
    } catch {
      routeService.isGenerating = false
      routeService.errorMessage = "Route-Update fehlgeschlagen: \(error.localizedDescription)"
      return nil
    }
  }
  
  /// Recalculate walking routes between waypoints
  private func recalculateWalkingRoutes(for waypoints: [RoutePoint]) async throws -> [MKRoute] {
    var routes: [MKRoute] = []
    
    for i in 0..<(waypoints.count - 1) {
      let startPoint = waypoints[i]
      let endPoint = waypoints[i + 1]
      
      let request = MKDirections.Request()
      request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint.coordinate))
      request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endPoint.coordinate))
      request.transportType = .walking
      
      let directions = MKDirections(request: request)
      
      do {
        let response = try await directions.calculate()
        if let route = response.routes.first {
          routes.append(route)
        } else {
          throw NSError(
            domain: "RouteUpdate",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Keine Route zwischen Wegpunkten gefunden"]
          )
        }
      } catch {
        throw NSError(
          domain: "RouteUpdate", 
          code: 500,
          userInfo: [NSLocalizedDescriptionKey: "Routenberechnung fehlgeschlagen: \(error.localizedDescription)"]
        )
      }
      
      // Rate limiting to be respectful to Apple's servers
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    return routes
  }
}
