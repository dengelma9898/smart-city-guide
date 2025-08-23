import Foundation
import CoreLocation

// MARK: - Wikipedia Integration Extension for HomeCoordinator

extension HomeCoordinator {
    
    // MARK: - Wikipedia Enrichment
    
    func startWikipediaEnrichment(for route: GeneratedRoute) {
        Task {
            // Get discovered POIs from the route service if available
            let discoveredPOIs = await routeService.getDiscoveredPOIs() ?? []
            
            // Extract city name from first waypoint for better Wikipedia search
            let cityName = extractCityName(from: route.waypoints.first?.address ?? "")
            
            SecureLogger.shared.logInfo("📚 Starting Wikipedia enrichment for \(route.waypoints.count) waypoints in \(cityName)", category: .data)
            
            // Use the RouteWikipediaService to enrich the route
            await wikipediaService.enrichRoute(route, from: discoveredPOIs, startingCity: cityName)
            
            // Update the coordinator's enriched POIs from the service
            await MainActor.run {
                self.enrichedPOIs = wikipediaService.enrichedPOIs
                let enrichedCount = self.enrichedPOIs.values.filter { $0.wikipediaImageURL != nil }.count
                SecureLogger.shared.logInfo("✅ Wikipedia enrichment completed: \(enrichedCount)/\(route.waypoints.count) POIs have images", category: .data)
            }
        }
    }
    
    private func extractCityName(from address: String) -> String {
        // Simple city extraction - split by commas and take relevant part
        let components = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Look for typical German city patterns
        for component in components {
            if !component.isEmpty && 
               !component.lowercased().contains("straße") && 
               !component.lowercased().contains("platz") &&
               component.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
                return component
            }
        }
        
        return components.first ?? "Deutschland"
    }
}

extension BasicHomeCoordinator {
    
    // MARK: - Wikipedia Enrichment
    
    func startWikipediaEnrichment(for route: GeneratedRoute) {
        Task {
            // Get discovered POIs from the route service if available
            let discoveredPOIs = await routeService.getDiscoveredPOIs() ?? []
            
            // Extract city name from first waypoint for better Wikipedia search
            let cityName = extractCityName(from: route.waypoints.first?.address ?? "")
            
            SecureLogger.shared.logInfo("📚 Starting Wikipedia enrichment for \(route.waypoints.count) waypoints in \(cityName)", category: .data)
            
            // Use the RouteWikipediaService to enrich the route
            await wikipediaService.enrichRoute(route, from: discoveredPOIs, startingCity: cityName)
            
            // Update the coordinator's enriched POIs from the service
            await MainActor.run {
                self.enrichedPOIs = wikipediaService.enrichedPOIs
                let enrichedCount = self.enrichedPOIs.values.filter { $0.wikipediaImageURL != nil }.count
                SecureLogger.shared.logInfo("✅ Wikipedia enrichment completed: \(enrichedCount)/\(route.waypoints.count) POIs have images", category: .data)
            }
        }
    }
    
    private func extractCityName(from address: String) -> String {
        // Simple city extraction - split by commas and take relevant part
        let components = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Look for typical German city patterns
        for component in components {
            if !component.isEmpty && 
               !component.lowercased().contains("straße") && 
               !component.lowercased().contains("platz") &&
               component.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
                return component
            }
        }
        
        return components.first ?? "Deutschland"
    }
}
