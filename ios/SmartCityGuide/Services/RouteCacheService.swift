import Foundation
import MapKit
import CoreLocation

/// Service for caching MKRoute results to reduce MapKit API calls and improve performance
@MainActor
class RouteCacheService: ObservableObject {
    static let shared = RouteCacheService()
    
    private let logger = SecureLogger.shared
    private var routeCache: [RouteCacheKey: CachedRoute] = [:]
    private let cacheExpirationTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let maxCacheSize = 1000 // Maximum number of cached routes
    
    // Analytics tracking
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    private init() {
        logger.logInfo("🗺️ RouteCacheService initialized", category: .performance)
    }
    
    // MARK: - Public API
    
    /// Get a cached route between two coordinates
    /// - Parameters:
    ///   - from: Starting coordinate
    ///   - to: Destination coordinate
    /// - Returns: Cached MKRoute if available and valid, nil otherwise
    func getCachedRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> MKRoute? {
        let cacheKey = RouteCacheKey(from: from, to: to)
        
        guard let cachedRoute = routeCache[cacheKey] else {
            cacheMisses += 1
            logger.logDebug("🗺️ ❌ Route cache miss: \(cacheKey.description)", category: .performance)
            return nil
        }
        
        // Check if cache entry is still valid
        if Date().timeIntervalSince(cachedRoute.timestamp) > cacheExpirationTime {
            logger.logDebug("🗺️ ⏰ Route cache expired: \(cacheKey.description)", category: .performance)
            routeCache.removeValue(forKey: cacheKey)
            cacheMisses += 1
            return nil
        }
        
        cacheHits += 1
        logger.logDebug("🗺️ ✅ Route cache hit: \(cacheKey.description)", category: .performance)
        return cachedRoute.route
    }
    
    /// Cache a route result for future use
    /// - Parameters:
    ///   - route: The MKRoute to cache
    ///   - from: Starting coordinate
    ///   - to: Destination coordinate
    func cacheRoute(_ route: MKRoute, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let cacheKey = RouteCacheKey(from: from, to: to)
        
        // Enforce cache size limit using LRU eviction
        if routeCache.count >= maxCacheSize {
            evictOldestCacheEntry()
        }
        
        let cachedRoute = CachedRoute(
            route: route,
            timestamp: Date(),
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
        
        routeCache[cacheKey] = cachedRoute
        logger.logDebug("🗺️ 💾 Route cached: \(cacheKey.description) (\(Int(route.distance))m, \(Int(route.expectedTravelTime))s)", category: .performance)
    }
    
    /// Clear all cached routes
    func clearCache() {
        let entriesCleared = routeCache.count
        routeCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
        logger.logInfo("🗺️ 🗑️ Route cache cleared: \(entriesCleared) entries", category: .performance)
    }
    
    /// Remove expired cache entries
    func clearExpiredEntries() {
        let now = Date()
        let keysToRemove = routeCache.compactMap { key, value in
            now.timeIntervalSince(value.timestamp) > cacheExpirationTime ? key : nil
        }
        
        for key in keysToRemove {
            routeCache.removeValue(forKey: key)
        }
        
        if !keysToRemove.isEmpty {
            logger.logInfo("🗺️ ⏰ Removed \(keysToRemove.count) expired route cache entries", category: .performance)
        }
    }
    
    // MARK: - Cache Statistics
    
    /// Get current cache statistics for monitoring
    var cacheStatistics: RouteCacheStatistics {
        return RouteCacheStatistics(
            cacheSize: routeCache.count,
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            hitRate: cacheHits + cacheMisses > 0 ? Double(cacheHits) / Double(cacheHits + cacheMisses) : 0.0,
            totalDistance: routeCache.values.reduce(0) { $0 + $1.distance },
            totalTravelTime: routeCache.values.reduce(0) { $0 + $1.expectedTravelTime }
        )
    }
    
    /// Get cache information for debugging
    func getCacheInfo() -> [String: Any] {
        let stats = cacheStatistics
        return [
            "cacheSize": stats.cacheSize,
            "maxCacheSize": maxCacheSize,
            "cacheHits": stats.cacheHits,
            "cacheMisses": stats.cacheMisses,
            "hitRate": String(format: "%.1f%%", stats.hitRate * 100),
            "totalDistance": String(format: "%.1fkm", stats.totalDistance / 1000),
            "totalTravelTime": String(format: "%.1fh", stats.totalTravelTime / 3600),
            "expirationTime": "\(Int(cacheExpirationTime / 86400)) days"
        ]
    }
    
    // MARK: - Private Methods
    
    /// Remove the oldest cache entry (LRU eviction)
    private func evictOldestCacheEntry() {
        guard !routeCache.isEmpty else { return }
        
        let oldestKey = routeCache.min { first, second in
            first.value.timestamp < second.value.timestamp
        }?.key
        
        if let keyToRemove = oldestKey {
            routeCache.removeValue(forKey: keyToRemove)
            logger.logDebug("🗺️ 🗑️ Evicted oldest route cache entry: \(keyToRemove.description)", category: .performance)
        }
    }
}

// MARK: - Supporting Types

/// Cache key for route lookups based on rounded coordinates
struct RouteCacheKey: Hashable, CustomStringConvertible {
    let fromLat: Double
    let fromLon: Double
    let toLat: Double
    let toLon: Double
    
    /// Initialize with coordinate rounding for cache hits
    /// Rounds to ~10m precision to balance cache hit rate with accuracy
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        // Round to 4 decimal places (~10m precision)
        self.fromLat = (from.latitude * 10000).rounded() / 10000
        self.fromLon = (from.longitude * 10000).rounded() / 10000
        self.toLat = (to.latitude * 10000).rounded() / 10000
        self.toLon = (to.longitude * 10000).rounded() / 10000
    }
    
    var description: String {
        return "\(fromLat),\(fromLon) → \(toLat),\(toLon)"
    }
}

/// Cached route data with metadata
private struct CachedRoute {
    let route: MKRoute
    let timestamp: Date
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
}

/// Route cache statistics for monitoring and analytics
struct RouteCacheStatistics {
    let cacheSize: Int
    let cacheHits: Int
    let cacheMisses: Int
    let hitRate: Double
    let totalDistance: CLLocationDistance
    let totalTravelTime: TimeInterval
    
    /// Estimated API calls saved by caching
    var estimatedAPICallsSaved: Int {
        return cacheHits
    }
    
    /// Average route distance in cache
    var averageDistance: CLLocationDistance {
        return cacheSize > 0 ? totalDistance / Double(cacheSize) : 0
    }
    
    /// Average travel time in cache
    var averageTravelTime: TimeInterval {
        return cacheSize > 0 ? totalTravelTime / Double(cacheSize) : 0
    }
}

// MARK: - FeatureFlags Extension

extension FeatureFlags {
    /// Enable route caching to reduce MapKit API calls
    static let routeCachingEnabled: Bool = true
    
    /// Enable cache analytics logging
    static let cacheAnalyticsEnabled: Bool = true
}
