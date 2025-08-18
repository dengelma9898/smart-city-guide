# Phase 3: Cache-Strategie Optimization
*Created: 17-08-2025*

## 🎯 Ziele
- **Intelligentes Route Caching** für MKDirections Results
- **Disk Persistence** für alle Cache-Services (POI, Wikipedia, Routes)
- **Performance Boost** durch weniger API-Calls → weniger Throttling
- **Cache Analytics** für Hit-Rate monitoring

## 📊 Current State Analysis

### ✅ Existing Caching (In-Memory)
- **POICacheService**: City-based POI caching (24h TTL)
- **WikipediaService**: Search + Summary caching (24h TTL) + Enriched POI cache
- **Cache Expiration**: Automatic cleanup of expired entries

### ❌ Missing Caching
- **Route Caching**: No MKRoute results caching between coordinates
- **Disk Persistence**: All caches lost on app restart
- **Intelligent Cache Keys**: Only simple cityName-based keys
- **Cache Analytics**: No hit-rate tracking for optimization

## 🏗️ Implementation Plan

### Task 1: RouteCacheService 
```swift
@MainActor
class RouteCacheService: ObservableObject {
    static let shared = RouteCacheService()
    
    // Cache MKRoute results by coordinate pairs
    private var routeCache: [RouteCacheKey: CachedRoute] = [:]
    private let cacheExpirationTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    func getCachedRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> MKRoute?
    func cacheRoute(_ route: MKRoute, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
}

struct RouteCacheKey: Hashable {
    let fromLat: Double
    let fromLon: Double
    let toLat: Double
    let toLon: Double
    
    // Round coordinates to ~10m precision for cache hits
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.fromLat = (from.latitude * 10000).rounded() / 10000
        self.fromLon = (from.longitude * 10000).rounded() / 10000
        self.toLat = (to.latitude * 10000).rounded() / 10000
        self.toLon = (to.longitude * 10000).rounded() / 10000
    }
}
```

### Task 2: Intelligent Cache Keys
```swift
enum CacheKeyStrategy {
    case cityName(String)                                    // "nürnberg"
    case cityWithLocation(String, CLLocationCoordinate2D)    // "nürnberg@49.4521@11.0767"
    case locationWithRadius(CLLocationCoordinate2D, Double)  // "49.4521@11.0767@5000m"
    
    var key: String { ... }
}
```

### Task 3: Unified Cache Manager
```swift
@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    let poiCache = POICacheService.shared
    let routeCache = RouteCacheService.shared
    let wikipediaCache = WikipediaService.shared
    
    // Disk persistence coordinator
    private let diskManager = DiskCacheManager()
    
    func saveToDisk() async
    func loadFromDisk() async
    func clearAllCaches()
    func getCacheStatistics() -> CacheStatistics
}
```

### Task 4: Disk Persistence
```swift
actor DiskCacheManager {
    private let cacheDirectory: URL
    
    func save<T: Codable>(_ data: T, to file: String) async throws
    func load<T: Codable>(_ type: T.Type, from file: String) async throws -> T?
    func delete(_ file: String) async throws
    func deleteExpired() async
}
```

### Task 5: Cache Analytics
```swift
struct CacheStatistics {
    let poiCacheHits: Int
    let poiCacheMisses: Int
    let routeCacheHits: Int
    let routeCacheMisses: Int
    let wikipediaCacheHits: Int
    let wikipediaCacheMisses: Int
    
    var overallHitRate: Double
    var estimatedAPICallsSaved: Int
}
```

## 🎯 Integration Points

### RouteService Integration
- Check `RouteCacheService` before `MKDirections.calculate()`
- Cache successful route results automatically
- Log cache hit/miss for analytics

### POICacheService Enhancement
- Add location-based cache keys for precise area searches
- Migrate to unified disk persistence
- Support different cache strategies per use case

### MapKit Throttling Mitigation
- Route cache reduces MKDirections calls significantly
- Smart cache invalidation prevents stale route data
- Background cache warming for popular routes

## 🧪 Success Metrics

### Performance KPIs
- **Cache Hit Rate > 40%** for repeated area usage
- **Route Generation Time < 3s** for cached routes  
- **API Call Reduction > 60%** for returning users
- **Zero MapKit throttling** for normal usage patterns

### User Experience
- **Instant route loading** for previously visited areas
- **Offline-capable POI browsing** (cached data)
- **Seamless app restarts** with persisted cache

## 🔧 Implementation Order

1. **RouteCacheService** - Core route caching functionality
2. **DiskCacheManager** - Persistence layer for all caches  
3. **CacheManager** - Unified coordination and analytics
4. **Cache Key Enhancement** - Intelligent location-based keys
5. **Integration** - Wire into RouteService, POICacheService
6. **Analytics Dashboard** - Cache performance monitoring

## 🚨 Edge Cases & Considerations

### Cache Invalidation
- Route cache: 7 days (routes change less frequently)
- POI cache: 24 hours (POIs can change/close)
- Wikipedia cache: 7 days (content is stable)

### Memory Management
- LRU eviction for memory caches
- Disk cache size limits (100MB max)
- Background cleanup on app launch

### Coordinate Precision
- Round coordinates to ~10m precision for cache hits
- Balance between cache hit rate and accuracy
- Consider user movement patterns

## 🛡️ Security & Privacy
- No sensitive user data in caches
- Cache encryption for disk storage
- Automatic cache cleanup on app uninstall

## ⚡ Performance Optimizations
- Lazy cache loading on first access
- Background cache warming for popular areas
- Batch cache operations for efficiency
- Memory-mapped file access for large caches

## 🔄 Migration Strategy
- Existing caches continue to work unchanged
- Gradual migration to new cache keys
- Backward compatibility for cache data
- Soft rollout with feature flags

## 📊 Monitoring & Debugging
- Cache hit/miss logging via SecureLogger
- Cache size and performance metrics
- Debug views for cache inspection
- Automatic anomaly detection
