import Foundation
import CoreLocation

@MainActor
class POICacheService: ObservableObject {
    static let shared = POICacheService()
    
    private var cache: [String: CachedPOIData] = [:]
    private let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {}
    
    // MARK: - Cache Management
    
    func getCachedPOIs(for cityName: String) -> [POI]? {
        let cacheKey = cityName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let cachedData = cache[cacheKey] else {
            print("POICacheService: No cached data for '\(cityName)'")
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cachedData.timestamp) > cacheExpirationTime {
            print("POICacheService: Cache expired for '\(cityName)'")
            cache.removeValue(forKey: cacheKey)
            return nil
        }
        
        print("POICacheService: Returning \(cachedData.pois.count) cached POIs for '\(cityName)'")
        return cachedData.pois
    }
    
    func cachePOIs(_ pois: [POI], for cityName: String) {
        let cacheKey = cityName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cachedData = CachedPOIData(
            pois: pois,
            timestamp: Date(),
            cityName: cityName
        )
        
        cache[cacheKey] = cachedData
        print("POICacheService: Cached \(pois.count) POIs for '\(cityName)'")
    }
    
    func clearCache() {
        cache.removeAll()
        print("POICacheService: Cache cleared")
    }
    
    func clearExpiredEntries() {
        let now = Date()
        let keysToRemove = cache.compactMap { key, value in
            now.timeIntervalSince(value.timestamp) > cacheExpirationTime ? key : nil
        }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        
        if !keysToRemove.isEmpty {
            print("POICacheService: Removed \(keysToRemove.count) expired cache entries")
        }
    }
    
    // MARK: - Cache Statistics
    
    var cacheSize: Int {
        cache.count
    }
    
    var totalCachedPOIs: Int {
        cache.values.reduce(0) { $0 + $1.pois.count }
    }
    
    func getCacheInfo() -> [String: Any] {
        return [
            "cities": cache.count,
            "totalPOIs": totalCachedPOIs,
            "cacheKeys": Array(cache.keys)
        ]
    }
}

// MARK: - Supporting Types

private struct CachedPOIData {
    let pois: [POI]
    let timestamp: Date
    let cityName: String
}

// MARK: - POI Selection and Filtering

extension POICacheService {
    
    /// Selects the best POIs for route generation
    func selectBestPOIs(
        from allPOIs: [POI],
        count: Int,
        routeLength: RouteLength,
        startCoordinate: CLLocationCoordinate2D,
        startingCity: String,
        categories: [PlaceCategory]? = nil
    ) -> [POI] {
        
        var filteredPOIs = allPOIs
        
        // 🏙️ STADT-FILTERUNG: Nur POIs aus der gleichen Stadt wie der Startpunkt
        let cityFilteredPOIs = filteredPOIs.filter { poi in
            let isInCity = poi.isInCity(startingCity)
            if !isInCity {
                print("POICacheService: 🚫 Filtering out POI '\(poi.name)' - not in '\(startingCity)' (POI city: '\(poi.address?.city ?? "unknown")')")
            }
            return isInCity
        }
        
        print("POICacheService: 🏙️ City filtering: \(allPOIs.count) → \(cityFilteredPOIs.count) POIs for '\(startingCity)'")
        filteredPOIs = cityFilteredPOIs
        
        // Filter by categories if specified
        if let categories = categories {
            filteredPOIs = filteredPOIs.filter { categories.contains($0.category) }
        }
        
        // Score and rank POIs
        let scoredPOIs = filteredPOIs.map { poi in
            ScoredPOI(
                poi: poi,
                score: calculatePOIScore(
                    poi: poi,
                    startCoordinate: startCoordinate,
                    routeLength: routeLength
                )
            )
        }
        
        // Sort by score (highest first) and take the best ones
        let bestPOIs = scoredPOIs
            .sorted { $0.score > $1.score }
            .prefix(count * 2) // Take more than needed for better selection
            .map { $0.poi }
        
        // Further filter for geographic distribution
        let selectedPOIs = selectGeographicallyDistributedPOIs(
            from: bestPOIs,
            count: count,
            startCoordinate: startCoordinate
        )
        
        print("POICacheService: Selected \(selectedPOIs.count) POIs from \(allPOIs.count) total")
        return selectedPOIs
    }
    
    private func calculatePOIScore(
        poi: POI,
        startCoordinate: CLLocationCoordinate2D,
        routeLength: RouteLength
    ) -> Double {
        var score: Double = 0.0
        
        // 1. Category importance (weight: 40%)
        score += getCategoryScore(poi.category) * 0.4
        
        // 2. Distance from start (weight: 30%)
        let distance = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            .distance(from: CLLocation(latitude: poi.latitude, longitude: poi.longitude))
        
        let maxDistance = getMaxDistanceForRouteLength(routeLength)
        let distanceScore = max(0.0, 1.0 - (distance / maxDistance))
        score += distanceScore * 0.3
        
        // 3. POI quality indicators (weight: 30%)
        score += getPOIQualityScore(poi) * 0.3
        
        return score
    }
    
    private func getCategoryScore(_ category: PlaceCategory) -> Double {
        // Priority scoring for different categories
        switch category {
        case .attraction, .castle, .monument, .cathedral:
            return 1.0
        case .museum, .gallery, .viewpoint:
            return 0.9
        case .memorial, .archaeologicalSite, .ruins:
            return 0.8
        case .park, .garden, .artsCenter:
            return 0.7
        case .townhall, .placeOfWorship:
            return 0.6
        case .artwork, .chapel, .monastery, .shrine:
            return 0.5
        case .waterfall, .spring, .lake:
            return 0.4
        case .nationalPark:
            return 0.9
        case .landmarkAttraction:
            return 1.0
        }
    }
    
    private func getMaxDistanceForRouteLength(_ routeLength: RouteLength) -> Double {
        switch routeLength {
        case .short:
            return 5000 // 5km
        case .medium:
            return 10000 // 10km
        case .long:
            return 20000 // 20km
        }
    }
    
    private func getPOIQualityScore(_ poi: POI) -> Double {
        var score: Double = 0.5 // Base score
        
        // Bonus for having a proper name (not just category)
        if !poi.name.isEmpty && poi.name != poi.category.rawValue {
            score += 0.3
        }
        
        // Bonus for having description
        if let description = poi.description, !description.isEmpty {
            score += 0.2
        }
        
        // Bonus for certain tags that indicate quality
        if poi.tags["tourism"] != nil || poi.tags["heritage"] != nil {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    private func selectGeographicallyDistributedPOIs(
        from pois: [POI],
        count: Int,
        startCoordinate: CLLocationCoordinate2D
    ) -> [POI] {
        
        guard pois.count > count else { return pois }
        
        var selectedPOIs: [POI] = []
        var remainingPOIs = pois
        
        while selectedPOIs.count < count && !remainingPOIs.isEmpty {
            if selectedPOIs.isEmpty {
                // Select the first POI (highest scored)
                selectedPOIs.append(remainingPOIs.removeFirst())
            } else {
                // Select POI that is furthest from already selected POIs
                let nextPOI = remainingPOIs.max { poi1, poi2 in
                    let minDistance1 = selectedPOIs.map { selected in
                        CLLocation(latitude: poi1.latitude, longitude: poi1.longitude)
                            .distance(from: CLLocation(latitude: selected.latitude, longitude: selected.longitude))
                    }.min() ?? 0
                    
                    let minDistance2 = selectedPOIs.map { selected in
                        CLLocation(latitude: poi2.latitude, longitude: poi2.longitude)
                            .distance(from: CLLocation(latitude: selected.latitude, longitude: selected.longitude))
                    }.min() ?? 0
                    
                    return minDistance1 < minDistance2
                }
                
                if let nextPOI = nextPOI {
                    selectedPOIs.append(nextPOI)
                    remainingPOIs.removeAll { $0.id == nextPOI.id }
                }
            }
        }
        
        return selectedPOIs
    }
}

// MARK: - Supporting Types

private struct ScoredPOI {
    let poi: POI
    let score: Double
}