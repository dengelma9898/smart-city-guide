//
//  POIDiscoveryService.swift
//  SmartCityGuide
//
//  Service for discovering and selecting POIs for route generation
//

import Foundation
import MapKit
import CoreLocation
import os.log

@MainActor
class POIDiscoveryService: ObservableObject {
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "POIDiscovery")
    private let locationResolver: LocationResolverService
    
    init(locationResolver: LocationResolverService? = nil) {
        self.locationResolver = locationResolver ?? LocationResolverService()
    }
    
    // MARK: - POI Discovery
    
    func findInterestingPlaces(
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
    
    // MARK: - Geographic Distribution
    
    func applyGeographicDistribution(_ places: [RoutePoint], maxCount: Int) -> [RoutePoint] {
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
    
    // MARK: - Category-based Search
    
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
    
    // MARK: - Distance Filtering
    
    func applyMinimumDistanceFilter(
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
    
    // MARK: - Helper Methods
    
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
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        return locationResolver.distance(from: from, to: to)
    }
}
