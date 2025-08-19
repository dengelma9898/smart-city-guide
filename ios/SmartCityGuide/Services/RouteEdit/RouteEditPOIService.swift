import Foundation
import CoreLocation
import os.log

/// Service for managing POI finding and filtering in route editing
@MainActor
class RouteEditPOIService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "RouteEditPOI")
    
    // MARK: - Public Interface
    
    /// Find all available POI alternatives for a route edit
    /// - Parameters:
    ///   - allDiscoveredPOIs: All POIs discovered for the city
    ///   - editableSpot: The spot being edited
    ///   - originalRoute: The original route
    /// - Returns: Filtered and sorted array of alternative POIs
    func findAllAvailablePOIs(
        allDiscoveredPOIs: [POI],
        editableSpot: EditableRouteSpot,
        originalRoute: GeneratedRoute
    ) -> [POI] {
        
        logger.info("🔍 Finding alternatives for spot: \(editableSpot.originalWaypoint.name)")
        
        // Get previously replaced POIs for this position
        let replacedPOIs = editableSpot.replacedPOIs
        
        // Combine all discovered POIs with replaced POIs
        let allPossiblePOIs = allDiscoveredPOIs + replacedPOIs
        
        let filteredPOIs = allPossiblePOIs.filter { poi in
            // Only exclude POIs already in route - NO distance restriction
            return !isAlreadyInRoute(poi, originalRoute: originalRoute)
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
            let categoryMatch1 = poi1.category == editableSpot.originalWaypoint.category
            let categoryMatch2 = poi2.category == editableSpot.originalWaypoint.category
            
            if categoryMatch1 && !categoryMatch2 {
                return true
            } else if !categoryMatch1 && categoryMatch2 {
                return false
            }
            
            // Finally sort by distance
            let distance1 = calculateDistance(from: poi1.coordinate, to: editableSpot.originalWaypoint.coordinate)
            let distance2 = calculateDistance(from: poi2.coordinate, to: editableSpot.originalWaypoint.coordinate)
            return distance1 < distance2
        }
        .prefix(50) // Increased limit for maximum alternatives
        .map { $0 }
        
        logger.info("🔍 Found \(filteredPOIs.count) alternative POIs (from \(allPossiblePOIs.count) total)")
        return filteredPOIs
    }
    
    /// Check if POI is already in the current route
    /// - Parameters:
    ///   - poi: POI to check
    ///   - originalRoute: The route to check against
    /// - Returns: True if POI is already in the route
    func isAlreadyInRoute(_ poi: POI, originalRoute: GeneratedRoute) -> Bool {
        return originalRoute.waypoints.contains { waypoint in
            poi.name.lowercased() == waypoint.name.lowercased() &&
            calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50 // 50m tolerance
        }
    }
    
    /// Create swipe cards from POIs with enriched data
    /// - Parameters:
    ///   - pois: POIs to create cards from
    ///   - enrichedData: Wikipedia enrichment data
    ///   - originalWaypoint: The original waypoint being replaced
    ///   - replacedPOIs: Previously replaced POIs for context
    /// - Returns: Array of swipe cards
    func createSwipeCards(
        from pois: [POI],
        enrichedData: [String: WikipediaEnrichedPOI],
        originalWaypoint: RoutePoint,
        replacedPOIs: [POI]
    ) -> [SwipeCard] {
        
        logger.info("🃏 Creating \(pois.count) swipe cards")
        
        return pois.map { poi in
            SwipeCard(
                poi: poi,
                enrichedData: enrichedData[poi.name],
                distanceFromOriginal: calculateDistance(from: poi.coordinate, to: originalWaypoint.coordinate),
                category: poi.category,
                wasReplaced: replacedPOIs.contains { $0.id == poi.id }
            )
        }
    }
    
    /// Enrich POIs with Wikipedia data in the background
    /// - Parameters:
    ///   - pois: POIs to enrich
    ///   - cityName: City name for context
    /// - Returns: Dictionary of enriched POI data
    func enrichAlternativesWithWikipedia(
        _ pois: [POI],
        cityName: String
    ) async -> [String: WikipediaEnrichedPOI] {
        
        guard !pois.isEmpty else {
            logger.debug("🔍 No POIs to enrich")
            return [:]
        }
        
        logger.info("📖 Enriching \(pois.count) POI alternatives with Wikipedia data")
        
        let wikipediaService = WikipediaService.shared
        var enrichedData: [String: WikipediaEnrichedPOI] = [:]
        
        // Enrich POIs in batches to avoid overwhelming the API
        let batchSize = 5
        let batches = pois.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            logger.debug("📖 Processing batch \(index + 1)/\(batches.count)")
            
            await withTaskGroup(of: (String, WikipediaEnrichedPOI?).self) { group in
                for poi in batch {
                    group.addTask {
                        do {
                            let enriched = try await wikipediaService.enrichPOI(poi, cityName: cityName)
                            return (poi.name, enriched)
                        } catch {
                            return (poi.name, nil)
                        }
                    }
                }
                
                for await (poiName, enriched) in group {
                    if let enriched = enriched {
                        enrichedData[poiName] = enriched
                    }
                }
            }
            
            // Small delay between batches to be API-friendly
            if index < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        logger.info("📖 Wikipedia enrichment complete: \(enrichedData.count)/\(pois.count) POIs enriched")
        return enrichedData
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
