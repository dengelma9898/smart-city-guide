import Foundation
import CoreLocation
import SwiftUI

/// Service for discovering POIs in manual route planning
@MainActor
class ManualRoutePOIDiscoveryService: ObservableObject {
    
    @Published var discoveredPOIs: [POI] = []
    @Published var errorMessage: String?
    @Published var enrichmentProgress: Double = 0.0
    @Published var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
    
    private let geoapifyService: GeoapifyAPIService
    private let wikipediaService: WikipediaService
    private let logger = SecureLogger.shared
    
    init(geoapifyService: GeoapifyAPIService? = nil,
         wikipediaService: WikipediaService? = nil) {
        self.geoapifyService = geoapifyService ?? GeoapifyAPIService.shared
        self.wikipediaService = wikipediaService ?? WikipediaService.shared
    }
    
    func discoverPOIs(config: ManualRouteConfig) async {
        logger.logDebug("🌍 Manual Route: Starting POI discovery for \(config.startingCity)", category: .ui)
        
        do {
            let coordinates: CLLocationCoordinate2D
            
            if let coords = config.startingCoordinates {
                coordinates = coords
                logger.logDebug("🌍 Manual Route: Using provided coordinates for \(config.startingCity)", category: .ui)
            } else {
                logger.logDebug("🌍 Manual Route: No coordinates provided, using fallback for city: \(config.startingCity)", category: .ui)
                // For now, use GeoapifyAPIService to geocode the city
                let pois = try await geoapifyService.fetchPOIs(
                    for: config.startingCity,
                    categories: PlaceCategory.geoapifyEssentialCategories
                )
                
                discoveredPOIs = pois
                if pois.isEmpty {
                    errorMessage = "Keine POIs in \(config.startingCity) gefunden. Versuche eine andere Stadt."
                } else {
                    await enrichPOIs(cityName: config.startingCity)
                }
                return
            }
            
            // Discover POIs using GeoapifyAPIService
            let pois = try await geoapifyService.fetchPOIs(
                at: coordinates,
                cityName: config.startingCity,
                categories: PlaceCategory.geoapifyEssentialCategories
            )
            
            discoveredPOIs = pois
            if pois.isEmpty {
                errorMessage = "Keine POIs in \(config.startingCity) gefunden. Versuche eine andere Stadt."
            } else {
                await enrichPOIs(cityName: config.startingCity)
            }
        } catch {
            errorMessage = "Fehler beim Laden der POIs: \(error.localizedDescription)"
        }
    }
    
    private func enrichPOIs(cityName: String) async {
        let totalPOIs = discoveredPOIs.count
        guard totalPOIs > 0 else {
            return
        }
        
        var enrichedData: [String: WikipediaEnrichedPOI] = [:]
        
        for (index, poi) in discoveredPOIs.enumerated() {
            do {
                let enriched = try await wikipediaService.enrichPOI(poi, cityName: cityName)
                enrichedData[poi.id] = enriched
            } catch {
                // Continue with other POIs even if one fails
                logger.logWarning("Failed to enrich POI \(poi.name): \(error.localizedDescription)", category: .data)
            }
            
            // Update progress
            let progress = Double(index + 1) / Double(totalPOIs)
            enrichmentProgress = progress
        }
        
        self.enrichedPOIs = enrichedData
    }
    
    func clearData() {
        discoveredPOIs = []
        enrichedPOIs = [:]
        enrichmentProgress = 0.0
        errorMessage = nil
    }
}
