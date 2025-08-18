import Foundation
import CoreLocation

/// Unified cache coordinator for all caching services in the app
@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    private let logger = SecureLogger.shared
    private let diskManager: DiskCacheManager
    
    // Cache service references
    let poiCache = POICacheService.shared
    let routeCache = RouteCacheService.shared
    let wikipediaCache = WikipediaService.shared
    
    // Cache file names
    private let routeCacheFileName = "route_cache.json"
    private let poiCacheFileName = "poi_cache.json"
    private let wikipediaCacheFileName = "wikipedia_cache.json"
    
    @Published var isLoading = false
    @Published var diskCacheStatistics: DiskCacheStatistics?
    
    private init() {
        do {
            self.diskManager = try DiskCacheManager()
            logger.logInfo("🗃️ CacheManager initialized with disk persistence", category: .performance)
        } catch {
            fatalError("Failed to initialize DiskCacheManager: \(error)")
        }
    }
    
    // MARK: - Lifecycle Management
    
    /// Load all caches from disk on app startup
    func loadFromDisk() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.logInfo("🗃️ Loading caches from disk...", category: .performance)
        
        await withTaskGroup(of: Void.self) { group in
            // Load route cache
            group.addTask {
                await self.loadRouteCache()
            }
            
            // Load POI cache  
            group.addTask {
                await self.loadPOICache()
            }
            
            // Load Wikipedia cache
            group.addTask {
                await self.loadWikipediaCache()
            }
            
            // Clean up expired entries
            group.addTask {
                await self.diskManager.deleteExpired()
                await self.diskManager.enforceStorageLimit()
            }
        }
        
        // Update statistics
        diskCacheStatistics = await diskManager.getCacheStatistics()
        logger.logInfo("🗃️ All caches loaded from disk", category: .performance)
    }
    
    /// Save all caches to disk
    func saveToDisk() async {
        logger.logInfo("🗃️ Saving caches to disk...", category: .performance)
        
        await withTaskGroup(of: Void.self) { group in
            // Save route cache
            group.addTask {
                await self.saveRouteCache()
            }
            
            // Save POI cache
            group.addTask {
                await self.savePOICache()
            }
            
            // Save Wikipedia cache  
            group.addTask {
                await self.saveWikipediaCache()
            }
        }
        
        // Update statistics
        diskCacheStatistics = await diskManager.getCacheStatistics()
        logger.logInfo("🗃️ All caches saved to disk", category: .performance)
    }
    
    /// Clear all caches (memory and disk)
    func clearAllCaches() async {
        logger.logInfo("🗃️ Clearing all caches...", category: .performance)
        
        // Clear memory caches
        poiCache.clearCache()
        routeCache.clearCache()
        // Note: WikipediaService cache clearing would need to be added
        
        // Clear disk cache
        await diskManager.clearAll()
        
        // Update statistics
        diskCacheStatistics = await diskManager.getCacheStatistics()
        logger.logInfo("🗃️ All caches cleared", category: .performance)
    }
    
    // MARK: - Cache Statistics
    
    /// Get comprehensive cache statistics
    func getCacheStatistics() async -> CacheStatistics {
        let routeStats = routeCache.cacheStatistics
        let poiInfo = poiCache.getCacheInfo()
        let diskStats = await diskManager.getCacheStatistics()
        
        return CacheStatistics(
            routeCache: routeStats,
            poiCacheSize: poiInfo["cities"] as? Int ?? 0,
            poiTotalCount: poiInfo["totalPOIs"] as? Int ?? 0,
            diskCache: diskStats,
            overallHitRate: calculateOverallHitRate(routeStats: routeStats),
            estimatedAPICallsSaved: routeStats.estimatedAPICallsSaved
        )
    }
    
    /// Get cache info for debugging/monitoring
    func getCacheInfo() async -> [String: Any] {
        let routeInfo = routeCache.getCacheInfo()
        let poiInfo = poiCache.getCacheInfo()
        let diskStats = await diskManager.getCacheStatistics()
        
        return [
            "route": routeInfo,
            "poi": poiInfo,
            "disk": [
                "fileCount": diskStats.fileCount,
                "totalSize": diskStats.formattedSize,
                "maxSize": diskStats.formattedMaxSize,
                "usage": String(format: "%.1f%%", diskStats.usagePercentage),
                "directory": diskStats.cacheDirectory
            ]
        ]
    }
    
    // MARK: - Background Maintenance
    
    /// Perform background cache maintenance
    func performMaintenace() async {
        logger.logInfo("🗃️ Performing cache maintenance...", category: .performance)
        
        // Clean expired entries from memory caches
        poiCache.clearExpiredEntries()
        routeCache.clearExpiredEntries()
        
        // Clean expired entries from disk
        await diskManager.deleteExpired()
        await diskManager.enforceStorageLimit()
        
        // Update statistics
        diskCacheStatistics = await diskManager.getCacheStatistics()
        
        logger.logInfo("🗃️ Cache maintenance completed", category: .performance)
    }
    
    // MARK: - Private Implementation
    
    private func loadRouteCache() async {
        do {
            if let routes: [String: CachedRouteData] = try await diskManager.load([String: CachedRouteData].self, from: routeCacheFileName) {
                // Restore routes to RouteCacheService
                // Note: This would require enhancing RouteCacheService to support bulk loading
                logger.logDebug("🗃️ ✅ Loaded \(routes.count) routes from disk", category: .performance)
            }
        } catch {
            logger.logWarning("🗃️ ⚠️ Failed to load route cache: \(error.localizedDescription)", category: .performance)
        }
    }
    
    private func saveRouteCache() async {
        do {
            // Extract route cache data from RouteCacheService
            // Note: This would require enhancing RouteCacheService to export cache data
            let routeData: [String: CachedRouteData] = [:] // Placeholder
            try await diskManager.save(routeData, to: routeCacheFileName)
            logger.logDebug("🗃️ ✅ Saved route cache to disk", category: .performance)
        } catch {
            logger.logWarning("🗃️ ⚠️ Failed to save route cache: \(error.localizedDescription)", category: .performance)
        }
    }
    
    private func loadPOICache() async {
        do {
            if let pois: [String: SerializablePOIData] = try await diskManager.load([String: SerializablePOIData].self, from: poiCacheFileName) {
                // Restore POIs to POICacheService
                // Note: This would require enhancing POICacheService to support bulk loading
                logger.logDebug("🗃️ ✅ Loaded \(pois.count) POI caches from disk", category: .performance)
            }
        } catch {
            logger.logWarning("🗃️ ⚠️ Failed to load POI cache: \(error.localizedDescription)", category: .performance)
        }
    }
    
    private func savePOICache() async {
        do {
            // Extract POI cache data from POICacheService
            // Note: This would require enhancing POICacheService to export cache data
            let poiData: [String: SerializablePOIData] = [:] // Placeholder
            try await diskManager.save(poiData, to: poiCacheFileName)
            logger.logDebug("🗃️ ✅ Saved POI cache to disk", category: .performance)
        } catch {
            logger.logWarning("🗃️ ⚠️ Failed to save POI cache: \(error.localizedDescription)", category: .performance)
        }
    }
    
    private func loadWikipediaCache() async {
        // Wikipedia cache loading would be implemented here
        logger.logDebug("🗃️ Wikipedia cache loading not yet implemented", category: .performance)
    }
    
    private func saveWikipediaCache() async {
        // Wikipedia cache saving would be implemented here
        logger.logDebug("🗃️ Wikipedia cache saving not yet implemented", category: .performance)
    }
    
    private func calculateOverallHitRate(routeStats: RouteCacheStatistics) -> Double {
        // For now, just use route cache hit rate
        // Later could be expanded to include POI and Wikipedia hit rates
        return routeStats.hitRate
    }
}

// MARK: - Supporting Types

/// Serializable route cache data for disk persistence
struct CachedRouteData: Codable {
    let distance: Double
    let expectedTravelTime: Double
    let timestamp: Date
    let coordinates: RouteCoordinates
}

struct RouteCoordinates: Codable {
    let fromLat: Double
    let fromLon: Double
    let toLat: Double
    let toLon: Double
}

/// Serializable POI cache data for disk persistence
struct SerializablePOIData: Codable {
    let pois: [POI]
    let timestamp: Date
    let cityName: String
}

/// Comprehensive cache statistics
struct CacheStatistics {
    let routeCache: RouteCacheStatistics
    let poiCacheSize: Int
    let poiTotalCount: Int
    let diskCache: DiskCacheStatistics
    let overallHitRate: Double
    let estimatedAPICallsSaved: Int
    
    var summary: String {
        return """
        Cache Performance Summary:
        - Route Cache: \(routeCache.cacheSize) routes, \(String(format: "%.1f%%", routeCache.hitRate * 100)) hit rate
        - POI Cache: \(poiCacheSize) cities, \(poiTotalCount) total POIs
        - Disk Usage: \(diskCache.formattedSize) / \(diskCache.formattedMaxSize) (\(String(format: "%.1f%%", diskCache.usagePercentage)))
        - API Calls Saved: ~\(estimatedAPICallsSaved)
        """
    }
}

// MARK: - FeatureFlags Extension

extension FeatureFlags {
    /// Enable disk persistence for all caches
    static let diskCachePersistenceEnabled: Bool = true
    
    /// Enable unified cache management
    static let unifiedCacheManagerEnabled: Bool = true
    
    /// Enable automatic cache maintenance
    static let automaticCacheMaintenanceEnabled: Bool = true
}
