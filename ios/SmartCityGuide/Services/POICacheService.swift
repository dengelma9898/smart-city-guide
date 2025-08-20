import Foundation
import CoreLocation
import os.log

@MainActor
class POICacheService: ObservableObject {
    static let shared = POICacheService()
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Cache")
    
    private var cache: [String: CachedPOIData] = [:]
    private let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {}
    
    // MARK: - Cache Management
    
    /// Get cached POIs for city name only (legacy method)
    func getCachedPOIs(for cityName: String) -> [POI]? {
        let cacheKey = generateCacheKey(cityName: cityName)
        return getCachedPOIsInternal(cacheKey: cacheKey, identifier: cityName)
    }
    
    /// Get cached POIs for specific location and radius (enhanced method)
    func getCachedPOIs(for cityName: String, location: CLLocation, radius: Double) -> [POI]? {
        let cacheKey = generateCacheKey(cityName: cityName, location: location, radius: radius)
        let identifier = "\(cityName)@\(location.coordinate.latitude),\(location.coordinate.longitude)@\(Int(radius))m"
        return getCachedPOIsInternal(cacheKey: cacheKey, identifier: identifier)
    }
    
    /// Cache POIs for city name only (legacy method)
    func cachePOIs(_ pois: [POI], for cityName: String) {
        let cacheKey = generateCacheKey(cityName: cityName)
        cachePOIsInternal(pois, cacheKey: cacheKey, cityName: cityName, location: nil, radius: nil)
    }
    
    /// Cache POIs for specific location and radius (enhanced method)
    func cachePOIs(_ pois: [POI], for cityName: String, location: CLLocation, radius: Double) {
        let cacheKey = generateCacheKey(cityName: cityName, location: location, radius: radius)
        cachePOIsInternal(pois, cacheKey: cacheKey, cityName: cityName, location: location, radius: radius)
    }
    
    // MARK: - Private Cache Implementation
    
    private func getCachedPOIsInternal(cacheKey: String, identifier: String) -> [POI]? {
        guard let cachedData = cache[cacheKey] else {
            logger.info("💾 ❌ Cache miss for '\(identifier)'")
            return nil
        }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cachedData.timestamp) > cacheExpirationTime {
            logger.info("💾 ⏰ Cache expired for '\(identifier)'")
            cache.removeValue(forKey: cacheKey)
            return nil
        }
        
        logger.info("💾 ✅ Cache hit for '\(identifier)': \(cachedData.pois.count) POIs")
        return cachedData.pois
    }
    
    private func cachePOIsInternal(_ pois: [POI], cacheKey: String, cityName: String, location: CLLocation?, radius: Double?) {
        let cachedData = CachedPOIData(
            pois: pois,
            timestamp: Date(),
            cityName: cityName,
            location: location,
            radius: radius
        )
        
        cache[cacheKey] = cachedData
        
        if let location = location, let radius = radius {
            let identifier = "\(cityName)@\(location.coordinate.latitude),\(location.coordinate.longitude)@\(Int(radius))m"
            logger.info("💾 💾 Cache store: \(pois.count) POIs for '\(identifier)'")
        } else {
            logger.info("💾 💾 Cache store: \(pois.count) POIs for '\(cityName)'")
        }
    }
    
    // MARK: - Cache Key Generation
    
    private func generateCacheKey(cityName: String) -> String {
        return cityName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateCacheKey(cityName: String, location: CLLocation, radius: Double) -> String {
        let baseCityKey = cityName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let lat = String(format: "%.4f", location.coordinate.latitude)
        let lon = String(format: "%.4f", location.coordinate.longitude)
        let radiusKey = String(format: "%.0f", radius)
        
        return "\(baseCityKey)@\(lat),\(lon)@\(radiusKey)m"
    }
    
    func clearCache() {
        cache.removeAll()
        logger.info("💾 🗑️ Cache cleared")
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
            logger.info("💾 ⏰ Removed \(keysToRemove.count) expired cache entries")
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
    let location: CLLocation?
    let radius: Double?
    
    /// Human-readable identifier for logging
    var identifier: String {
        if let location = location, let radius = radius {
            return "\(cityName)@\(String(format: "%.4f", location.coordinate.latitude)),\(String(format: "%.4f", location.coordinate.longitude))@\(Int(radius))m"
        } else {
            return cityName
        }
    }
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
        
        // 🏙️ City filtering intentionally disabled to accept all POIs within radius
        let cityFilteredPOIs = filteredPOIs.filter { poi in
            // MIGRATION: Skip city filtering completely - accept all POIs in radius
            return true
        }
        
        logger.info("🏙️ City filtering: disabled - keeping all \(allPOIs.count) POIs in radius for '\(startingCity)'")
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
        
        logger.info("📍 Selected \(selectedPOIs.count) POIs from \(allPOIs.count) total")
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
        case .waterfall, .spring, .lake, .river, .canal:
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