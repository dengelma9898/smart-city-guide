import Foundation

// MARK: - Centralized Rate Limiter for async throttling
enum RateLimiter {
    /// Default delay for MapKit route calculations
    /// MapKit limit: 50 requests/60s = 1.2s between requests minimum
    /// Safe delay: 1.5s to account for app usage patterns and safety margin
    static let routeCalculationDelayNanoseconds: UInt64 = 1_500_000_000 // 1.5s
    
    /// Conservative delay for safe mode (even slower)
    static let safeDelayNanoseconds: UInt64 = 2_000_000_000 // 2.0s

    /// Await a throttling tick for route calculations
    /// - Parameter multiplier: Multiply the base delay (e.g., 2.0 → 3s)
    static func awaitRouteCalculationTick(multiplier: Double = 1.0) async throws {
        let baseDelay = FeatureFlags.mapKitSafeMode ? safeDelayNanoseconds : routeCalculationDelayNanoseconds
        let ns = UInt64(Double(baseDelay) * multiplier)
        try await Task.sleep(nanoseconds: ns)
    }

    /// Await a generic throttling tick (default 0.2s)
    static func awaitBackgroundTick(nanoseconds: UInt64 = 200_000_000) async {
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}


