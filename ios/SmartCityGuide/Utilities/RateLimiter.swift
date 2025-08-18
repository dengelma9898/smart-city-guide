import Foundation

// MARK: - Centralized Rate Limiter for async throttling
enum RateLimiter {
    /// Default delay for MapKit route calculations (0.2s)
    static let routeCalculationDelayNanoseconds: UInt64 = 200_000_000

    /// Await a throttling tick for route calculations
    /// - Parameter multiplier: Multiply the base delay (e.g., 2.0 → 0.4s)
    static func awaitRouteCalculationTick(multiplier: Double = 1.0) async throws {
        let ns = UInt64(Double(routeCalculationDelayNanoseconds) * multiplier)
        try await Task.sleep(nanoseconds: ns)
    }

    /// Await a generic throttling tick (default 0.2s)
    static func awaitBackgroundTick(nanoseconds: UInt64 = 200_000_000) async {
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}


