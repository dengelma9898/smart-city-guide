# MapKit Throttling Optimization Plan
*Created: 17-08-2025*

## 🚨 Problem
MapKit has throttled our app with "Directions Not Available" error:
- **Limit**: 50 MKDirections requests per 60 seconds
- **Our parallel implementation**: 3 concurrent × 0.2s = ~900 requests/min
- **18x over the limit!** 

## 🔧 Immediate Fix (Implemented)
✅ **Disabled parallel route generation** (`parallelRouteGenerationEnabled: false`)  
✅ **Increased rate limiting** to 2.0s between requests in safe mode  
✅ **Added MapKit safe mode** feature flag

**New Rate Calculation**:
- Sequential: 1 request every 2.0s = 30 requests/min ✅ (within 50/min limit)

## 🎯 Long-term Optimization Strategy

### Phase 1: Intelligent Caching
- **Route Caching**: Cache MKRoute results for identical coordinates
- **Distance Matrix**: Pre-cache common route distances in POI-rich areas
- **Coordinate Rounding**: Round coordinates to ~10m precision for cache hits

### Phase 2: Smart Request Batching  
- **Locality-aware**: Group nearby POIs to minimize route requests
- **TSP Pre-filtering**: Use Euclidean distance for initial TSP, MKDirections only for final route
- **Progressive Loading**: Calculate initial route with fewer waypoints, add details on-demand

### Phase 3: Adaptive Rate Limiting
- **Usage Tracking**: Monitor app-wide MKDirections usage across all services
- **Dynamic Throttling**: Adjust delays based on current usage and remaining quota
- **Background Pre-caching**: Use idle time to pre-cache popular routes

## 🧪 Implementation Tasks

### Task 1: Route Caching Service
```swift
actor RouteCacheService {
    private var cache: [RouteCacheKey: MKRoute] = [:]
    private let maxCacheSize = 500
    
    func getCachedRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> MKRoute?
    func cacheRoute(_ route: MKRoute, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
}
```

### Task 2: MapKit Usage Monitor
```swift
actor MapKitUsageMonitor {
    private var requestTimestamps: [Date] = []
    
    func requestsInLastMinute() -> Int
    func canMakeRequest() -> Bool
    func recordRequest()
}
```

### Task 3: Adaptive Parallel Strategy
- Start with sequential
- Gradually enable parallelism based on usage patterns
- Fall back to sequential when approaching limits

## 📊 Success Metrics
- **Zero throttling events** during normal usage
- **Route generation time** under 10s for 10-waypoint routes
- **Cache hit rate** above 30% for repeated area usage
- **User experience** - no "Directions Not Available" errors

## 🔄 Rollback Plan
If optimization doesn't work:
1. Keep `parallelRouteGenerationEnabled: false`
2. Increase `routeCalculationDelayNanoseconds` to 3.0s
3. Reduce max POIs per route to 8-10

## 📈 Performance Testing
- Test with multiple rapid route generations
- Monitor MapKit usage in different scenarios:
  - Quick route planning (3-5 POIs)
  - Full route planning (10+ POIs) 
  - Manual route building
  - Route editing

## 🎛️ Feature Flags for Testing
```swift
enum FeatureFlags {
    static let routeCachingEnabled: Bool = true
    static let adaptiveRateLimitingEnabled: Bool = true
    static let mapKitUsageMonitoringEnabled: Bool = true
}
```
