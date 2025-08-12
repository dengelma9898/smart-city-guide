//
//  RouteEditService.swift
//  SmartCityGuide
//
//  Route Edit Feature - Business Logic Service
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

/// Service for handling route editing operations
@MainActor
final class RouteEditService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether a new route is being generated
    @Published var isGeneratingNewRoute: Bool = false
    
    /// Whether alternatives are being loaded  
    @Published var isLoadingAlternatives: Bool = false
    
    /// Current error message, if any
    @Published var errorMessage: String?
    
    /// Generated new route after POI replacement
    @Published var newRoute: GeneratedRoute?
    
    /// Current editing configuration
    @Published var configuration: RouteEditConfiguration = .default
    
    // MARK: - Dependencies
    
    private let routeService: RouteService
    private let poiCacheService: POICacheService
    private let wikipediaService: WikipediaService
    
    // MARK: - Initialization
    
    init(
        routeService: RouteService? = nil,
        poiCacheService: POICacheService? = nil,
        wikipediaService: WikipediaService? = nil
    ) {
        self.routeService = routeService ?? RouteService()
        self.poiCacheService = poiCacheService ?? POICacheService.shared
        self.wikipediaService = wikipediaService ?? WikipediaService.shared
    }
    
    // MARK: - Alternative POI Discovery
    
    /// Find alternative POIs for a specific waypoint
    /// - Parameters:
    ///   - waypoint: The waypoint to find alternatives for
    ///   - cachedPOIs: Available cached POIs
    ///   - currentRoute: Current route to avoid duplicates
    /// - Returns: Filtered and sorted alternative POIs
    func findAlternativePOIs(
        for waypoint: RoutePoint,
        from cachedPOIs: [POI],
        avoiding currentRoute: GeneratedRoute
    ) -> [POI] {
        
        // Get POI IDs already in route
        let routePOIIds = Set(currentRoute.waypoints.compactMap { waypoint in
            // Try to match by name and approximate location
            cachedPOIs.first { poi in
                poi.name.lowercased() == waypoint.name.lowercased() &&
                calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50 // 50m tolerance
            }?.id
        })
        
        // Filter alternatives based on criteria
        let alternatives = cachedPOIs.filter { poi in
            // 1. Not already in route
            guard !routePOIIds.contains(poi.id) else { return false }
            
            // 2. Distance constraint
            let distance = calculateDistance(from: poi.coordinate, to: waypoint.coordinate)
            guard distance <= configuration.maxDistanceFromOriginal else { return false }
            
            // 3. Category match (if preferred)
            if configuration.preferSameCategory {
                let categoryMatch = poi.category == waypoint.category
                let hasQualityData = poi.geoapifyWikiData?.hasWikipediaData == true
                
                // Accept if same category OR has quality data
                return categoryMatch || hasQualityData
            }
            
            return true
        }
        
        // Sort by preference
        return alternatives.sorted { poi1, poi2 in
            let distance1 = calculateDistance(from: poi1.coordinate, to: waypoint.coordinate)
            let distance2 = calculateDistance(from: poi2.coordinate, to: waypoint.coordinate)
            
            // 1. Category match takes priority
            let category1Match = poi1.category == waypoint.category
            let category2Match = poi2.category == waypoint.category
            
            if category1Match && !category2Match {
                return true
            } else if !category1Match && category2Match {
                return false
            }
            
            // 2. Quality data (Wikipedia) takes priority
            let quality1 = poi1.geoapifyWikiData?.hasWikipediaData == true
            let quality2 = poi2.geoapifyWikiData?.hasWikipediaData == true
            
            if quality1 && !quality2 {
                return true
            } else if !quality1 && quality2 {
                return false
            }
            
            // 3. Distance as tiebreaker (closer is better)
            return distance1 < distance2
        }
        .prefix(configuration.maxAlternatives)
        .map { $0 }
    }
    
    // MARK: - Swipe Card Creation
    
    /// Create swipe cards from POIs with enriched data
    /// - Parameters:
    ///   - pois: POIs to create cards from
    ///   - enrichedData: Dictionary of Wikipedia enriched data
    ///   - originalWaypoint: Original waypoint for distance calculation
    ///   - replacedPOIs: List of POIs that were previously replaced at this position
    /// - Returns: Array of configured swipe cards
    func createSwipeCards(
        from pois: [POI],
        enrichedData: [String: WikipediaEnrichedPOI],
        originalWaypoint: RoutePoint,
        replacedPOIs: [POI] = []
    ) -> [SwipeCard] {
        
        return pois.map { poi in
            let distance = calculateDistance(
                from: poi.coordinate,
                to: originalWaypoint.coordinate
            )
            
            // Check if this POI was previously replaced
            let wasReplaced = replacedPOIs.contains { $0.id == poi.id }
            
            return SwipeCard(
                poi: poi,
                enrichedData: enrichedData[poi.id],
                distanceFromOriginal: distance,
                category: poi.category,
                wasReplaced: wasReplaced
            )
        }
    }
    
    // MARK: - Route Generation
    
    /// Generate updated route by replacing a waypoint with a new POI
    /// - Parameters:
    ///   - waypointIndex: Index of waypoint to replace
    ///   - newPOI: New POI to insert
    ///   - originalRoute: Original route to modify
    func generateUpdatedRoute(
        replacing waypointIndex: Int,
        with newPOI: POI,
        in originalRoute: GeneratedRoute
    ) async {
        
        guard waypointIndex >= 0 && waypointIndex < originalRoute.waypoints.count else {
            setError("Ungültiger Waypoint-Index: \(waypointIndex)")
            return
        }
        
        isGeneratingNewRoute = true
        errorMessage = nil
        
        do {
            let newWaypoint = RoutePoint(from: newPOI)
            let originalWaypoint = originalRoute.waypoints[waypointIndex]
            
            // Calculate distance between original and new POI
            let distance = calculateDistance(from: originalWaypoint.coordinate, to: newWaypoint.coordinate)
            
            // Decision: Smart re-optimization for distant POIs
            let newWaypoints: [RoutePoint]
            if distance > configuration.reoptimizationThreshold {
                // POI is far away - find optimal position
                newWaypoints = try await findOptimalPosition(
                    for: newWaypoint,
                    in: originalRoute.waypoints,
                    replacingIndex: waypointIndex
                )
            } else {
                // POI is close - simple replacement
                var waypoints = originalRoute.waypoints
                waypoints[waypointIndex] = newWaypoint
                newWaypoints = waypoints
            }
            
            // Recalculate walking routes between all waypoints
            let newRoutes = try await recalculateWalkingRoutes(for: newWaypoints)
            
            // 3. Calculate new metrics (seconds)
            let newTotalDistance = newRoutes.reduce(0) { $0 + $1.distance }
            let newTotalTravelTime: TimeInterval = newRoutes.reduce(0) { $0 + $1.expectedTravelTime }
            
            // Keep original visit time, update experience time (seconds)
            let newTotalExperienceTime: TimeInterval = newTotalTravelTime + originalRoute.totalVisitTime
            
            // 4. Create updated route
            let updatedRoute = GeneratedRoute(
                waypoints: newWaypoints,
                routes: newRoutes,
                totalDistance: newTotalDistance,
                totalTravelTime: newTotalTravelTime,
                totalVisitTime: originalRoute.totalVisitTime,
                totalExperienceTime: newTotalExperienceTime
            )
            
            // 5. Store result
            self.newRoute = updatedRoute
            isGeneratingNewRoute = false
            
        } catch {
            setError("Route-Neuberechnung fehlgeschlagen: \(error.localizedDescription)")
        }
    }
    
    /// Recalculate walking routes between waypoints using MapKit
    private func recalculateWalkingRoutes(for waypoints: [RoutePoint]) async throws -> [MKRoute] {
        var routes: [MKRoute] = []
        
        for i in 0..<(waypoints.count - 1) {
            if Task.isCancelled { throw CancellationError() }
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
                    throw RouteEditError.routeGenerationFailed("Keine Route zwischen Wegpunkten gefunden")
                }
            } catch {
                throw RouteEditError.routeGenerationFailed("Routenberechnung fehlgeschlagen: \(error.localizedDescription)")
            }
            
            // Enhanced rate limiting for optimization scenarios (centralized)
            let multiplier: Double = isGeneratingNewRoute ? 2.0 : 1.0
            try await RateLimiter.awaitRouteCalculationTick(multiplier: multiplier)
        }
        
        return routes
    }
    
    /// Find optimal position for a new POI in the route by testing all positions
    /// Uses hybrid approach: air distance estimation + single MapKit verification
    /// - Parameters:
    ///   - newWaypoint: The new waypoint to insert
    ///   - originalWaypoints: Current waypoints in the route
    ///   - replacingIndex: Index of waypoint being replaced
    /// - Returns: Optimized waypoint array with new POI in best position
    private func findOptimalPosition(
        for newWaypoint: RoutePoint,
        in originalWaypoints: [RoutePoint],
        replacingIndex: Int
    ) async throws -> [RoutePoint] {
        
        // Extract intermediate waypoints (exclude start/end)
        let startPoint = originalWaypoints.first!
        let endPoint = originalWaypoints.last!
        var intermediateWaypoints = Array(originalWaypoints.dropFirst().dropLast())
        
        // Remove the original waypoint being replaced
        let adjustedReplacingIndex = replacingIndex - 1 // Adjust for start point
        if adjustedReplacingIndex >= 0 && adjustedReplacingIndex < intermediateWaypoints.count {
            intermediateWaypoints.remove(at: adjustedReplacingIndex)
        }
        
        // Add new waypoint to intermediates
        intermediateWaypoints.append(newWaypoint)
        
        // PHASE 1: Quick air distance estimation to find top candidates
        var candidates: [(route: [RoutePoint], estimatedDistance: Double)] = []
        
        for insertPosition in 0...intermediateWaypoints.count-1 {
            // Create test arrangement
            var testIntermediates = intermediateWaypoints
            let waypoint = testIntermediates.remove(at: testIntermediates.count - 1)
            testIntermediates.insert(waypoint, at: insertPosition)
            
            // Build full route
            var testRoute = [startPoint]
            testRoute.append(contentsOf: testIntermediates)
            testRoute.append(endPoint)
            
            // Estimate distance using air distance * realistic walking factor (1.3x)
            let estimatedDistance = estimateWalkingDistance(for: testRoute)
            candidates.append((route: testRoute, estimatedDistance: estimatedDistance))
        }
        
        // Sort by estimated distance and take top 2 candidates
        candidates.sort { $0.estimatedDistance < $1.estimatedDistance }
        let topCandidates = Array(candidates.prefix(2))
        
        // PHASE 2: MapKit verification for top candidates only
        var bestRoute: [RoutePoint] = []
        var bestActualDistance: Double = Double.infinity
        
        for candidate in topCandidates {
            do {
                // Calculate actual walking distance using MapKit (with rate limiting)
                let actualRoutes = try await recalculateWalkingRoutes(for: candidate.route)
                let actualDistance = actualRoutes.reduce(0) { $0 + $1.distance }
                
                if actualDistance < bestActualDistance {
                    bestActualDistance = actualDistance
                    bestRoute = candidate.route
                }
            } catch {
                // If route calculation fails for this candidate, skip it
                continue
            }
        }
        
        // Return best verified route, or fall back to simple replacement
        if !bestRoute.isEmpty {
            return bestRoute
        } else {
            // Fallback: simple replacement
            var fallbackRoute = originalWaypoints
            fallbackRoute[replacingIndex] = newWaypoint
            return fallbackRoute
        }
    }
    
    /// Estimate walking distance using air distance with realistic factor
    /// - Parameter waypoints: Route waypoints
    /// - Returns: Estimated walking distance in meters
    private func estimateWalkingDistance(for waypoints: [RoutePoint]) -> Double {
        guard waypoints.count >= 2 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<(waypoints.count - 1) {
            let startCoord = waypoints[i].coordinate
            let endCoord = waypoints[i + 1].coordinate
            let airDistance = calculateDistance(from: startCoord, to: endCoord)
            // Urban walking typically adds 20-40% to air distance
            totalDistance += airDistance * 1.3
        }
        return totalDistance
    }
    
    // MARK: - Load Enriched Alternatives
    
    /// Load alternative POIs with Wikipedia enrichment
    /// - Parameters:
    ///   - waypoint: Waypoint to find alternatives for
    ///   - currentRoute: Current route to avoid duplicates
    ///   - cityName: Name of the city for POI cache lookup
    /// - Returns: Tuple of alternative POIs and enriched data
    func loadEnrichedAlternatives(
        for waypoint: RoutePoint,
        avoiding currentRoute: GeneratedRoute,
        cityName: String
    ) async -> (pois: [POI], enrichedData: [String: WikipediaEnrichedPOI]) {
        
        isLoadingAlternatives = true
        errorMessage = nil
        
        // 1. Get cached POIs
        let cachedPOIs = poiCacheService.getCachedPOIs(for: cityName) ?? []
        
        // 2. Find suitable alternatives
        let alternatives = findAlternativePOIs(
            for: waypoint,
            from: cachedPOIs,
            avoiding: currentRoute
        )
        
        // 3. Enrich with Wikipedia data (background task)
        let enrichedData = await enrichAlternativesWithWikipedia(alternatives, cityName: cityName)
        
        isLoadingAlternatives = false
        
        return (pois: alternatives, enrichedData: enrichedData)
    }
    
    // MARK: - Wikipedia Enrichment
    
    /// Enrich alternatives with Wikipedia data
    /// - Parameters:
    ///   - pois: POIs to enrich
    ///   - cityName: Name of the city for Wikipedia context
    /// - Returns: Dictionary of enriched data by POI ID
    func enrichAlternativesWithWikipedia(_ pois: [POI], cityName: String) async -> [String: WikipediaEnrichedPOI] {
        
        var enrichedData: [String: WikipediaEnrichedPOI] = [:]
        
        // Process POIs in batches to avoid overwhelming the Wikipedia API
        let batchSize = 5
        let batches = stride(from: 0, to: pois.count, by: batchSize).map {
            Array(pois[$0..<min($0 + batchSize, pois.count)])
        }
        
        for batch in batches {
            await withTaskGroup(of: (String, WikipediaEnrichedPOI?).self) { group in
                
                for poi in batch {
                    group.addTask { [weak self] in
                        guard let self = self else { return (poi.id, nil) }
                        
                        do {
                            let enriched = try await self.wikipediaService.enrichPOI(poi, cityName: cityName)
                            return (poi.id, enriched)
                        } catch {
                            // Silently fail individual enrichments
                            return (poi.id, nil)
                        }
                    }
                }
                
                for await (poiId, enriched) in group {
                    if let enriched = enriched {
                        enrichedData[poiId] = enriched
                    }
                }
            }
            
            // Small delay between batches to be respectful to Wikipedia API
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        return enrichedData
    }
    
    // MARK: - Utility Methods
    
    /// Calculate distance between two coordinates
    /// - Parameters:
    ///   - from: Source coordinate
    ///   - to: Destination coordinate
    /// - Returns: Distance in meters
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    /// Set error state
    /// - Parameter message: Error message to display
    private func setError(_ message: String) {
        errorMessage = message
        isGeneratingNewRoute = false
        isLoadingAlternatives = false
    }
    
    /// Reset service state
    func reset() {
        isGeneratingNewRoute = false
        isLoadingAlternatives = false
        errorMessage = nil
        newRoute = nil
        configuration = .default
    }
}

// MARK: - RouteEditError

enum RouteEditError: LocalizedError {
    case routeGenerationFailed(String)
    case noAlternativesFound
    case invalidWaypoint
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .routeGenerationFailed(let reason):
            return "Route-Generierung fehlgeschlagen: \(reason)"
        case .noAlternativesFound:
            return "Keine Alternativen für diesen Stopp gefunden"
        case .invalidWaypoint:
            return "Ungültiger Waypoint ausgewählt"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        }
    }
}



// MARK: - Route Request Helper

/// Temporary route request structure for RouteService integration
private struct RouteRequest {
    let startLocation: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let intermediateWaypoints: [RoutePoint]
    let maxDistance: Double
    let maxStops: Int
}

// MARK: - RouteService Extension

extension RouteService {
    /// Generate route with predefined waypoints (for route editing)
    /// - Parameter waypoints: Ordered waypoints for the route
    /// - Returns: Generated route with walking directions
    func generateRouteWithWaypoints(_ waypoints: [RoutePoint]) async throws -> GeneratedRoute? {
        // This would integrate with the existing RouteService.generateRoute method
        // For now, we'll create a placeholder that maintains the structure
        
        // TODO: Integrate with actual RouteService.generateRoute logic
        // This should use the existing TSP optimization and walking directions calculation
        
        guard waypoints.count >= 2 else {
            throw RouteEditError.invalidWaypoint
        }
        
        // For now, return nil to indicate that this needs integration with RouteService
        // In the actual implementation, this would:
        // 1. Calculate walking directions between waypoints
        // 2. Apply TSP optimization if needed
        // 3. Generate proper route timing and metadata
        
        return nil
    }
}

// MARK: - Convenience Extensions

extension RouteEditService {
    /// Shared instance for global access
    static let shared = RouteEditService()
    
    /// Create editable route spot from current route and waypoint index
    /// - Parameters:
    ///   - currentRoute: Current generated route
    ///   - waypointIndex: Index of waypoint to edit
    ///   - cityName: Name of the city for POI cache lookup
    /// - Returns: Editable route spot or nil if invalid
    func createEditableSpot(
        from currentRoute: GeneratedRoute,
        at waypointIndex: Int,
        cityName: String
    ) async -> EditableRouteSpot? {
        
        guard waypointIndex >= 0 && waypointIndex < currentRoute.waypoints.count else {
            return nil
        }
        
        let waypoint = currentRoute.waypoints[waypointIndex]
        
        // Load alternatives
        let (alternatives, _) = await loadEnrichedAlternatives(
            for: waypoint,
            avoiding: currentRoute,
            cityName: cityName
        )
        
        // Find current POI if it exists in cache
        let cachedPOIs = poiCacheService.getCachedPOIs(for: cityName) ?? []
        let currentPOI = cachedPOIs.first { poi in
            poi.name.lowercased() == waypoint.name.lowercased() &&
            calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50
        }
        
        return EditableRouteSpot(
            originalWaypoint: waypoint,
            waypointIndex: waypointIndex,
            alternativePOIs: alternatives,
            currentPOI: currentPOI
        )
    }
}