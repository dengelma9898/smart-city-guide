import Foundation
import MapKit

/// Service for managing Wikipedia enrichment of route POIs with 2-phase strategy
@MainActor
class RouteWikipediaService: ObservableObject {
  
  // MARK: - Published State
  
  @Published var isEnrichingRoutePOIs = false
  @Published var isEnrichingAllPOIs = false
  @Published var enrichmentProgress = 0.0
  @Published var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
  
  // MARK: - Dependencies
  
  private let wikipediaService: WikipediaService
  
  // MARK: - Initialization
  
  init(wikipediaService: WikipediaService = .shared) {
    self.wikipediaService = wikipediaService
  }
  
  // MARK: - Public Interface
  
  /// 2-Phase Wikipedia Enrichment for a generated route
  func enrichRoute(_ route: GeneratedRoute, 
                   from discoveredPOIs: [POI], 
                   startingCity: String) async {
    await enrichRouteWithWikipedia(route: route, discoveredPOIs: discoveredPOIs, startingCity: startingCity)
  }
  
  /// Clear all enriched POI data
  func clearEnrichedData() {
    enrichedPOIs.removeAll()
    isEnrichingRoutePOIs = false
    isEnrichingAllPOIs = false
    enrichmentProgress = 0.0
  }
  
  // MARK: - Wikipedia Enrichment (2-Phase Strategy)
  
  /// Phase 1: Enrich nur die POIs in der generierten Route (schnell für UI)
  private func enrichRouteWithWikipedia(route: GeneratedRoute, 
                                        discoveredPOIs: [POI], 
                                        startingCity: String) async {
    isEnrichingRoutePOIs = true
    
    do {
      // Extrahiere die POIs aus den Route-Waypoints (ohne Start/End)
      let routePOIs = extractPOIsFromRoute(route: route, discoveredPOIs: discoveredPOIs)
      
      SecureLogger.shared.logDebug("📚 [Phase 1] Enriching \(routePOIs.count) route POIs with Wikipedia...", category: .data)
      
      // Enriche nur die Route-POIs
      let cityName = extractCityName(from: startingCity)
      SecureLogger.shared.logDebug("📚 Using extracted city name '\(cityName)' from '\(startingCity)' for Wikipedia enrichment", category: .data)
      let enrichedRoutePOIs = try await wikipediaService.enrichPOIs(routePOIs, cityName: cityName)
      
      // Speichere enriched POIs in Dictionary für schnellen Zugriff
      for enrichedPOI in enrichedRoutePOIs {
        enrichedPOIs[enrichedPOI.basePOI.id] = enrichedPOI
      }
      isEnrichingRoutePOIs = false
      
      let successCount = enrichedRoutePOIs.filter { $0.wikipediaData != nil }.count
      SecureLogger.shared.logInfo("📚 [Phase 1] Route enrichment completed: \(successCount)/\(routePOIs.count) successful", category: .data)
      
      // Phase 2: Enriche alle anderen POIs im Hintergrund
      await enrichAllPOIsInBackground(discoveredPOIs: discoveredPOIs, startingCity: startingCity)
      
    } catch {
      isEnrichingRoutePOIs = false
      SecureLogger.shared.logWarning("📚 [Phase 1] Route enrichment failed: \(error.localizedDescription)", category: .data)
      
      // Starte trotzdem Phase 2
      await enrichAllPOIsInBackground(discoveredPOIs: discoveredPOIs, startingCity: startingCity)
    }
  }
  
  /// Phase 2: Enriche alle gefundenen POIs im Hintergrund (für zukünftige Features)
  private func enrichAllPOIsInBackground(discoveredPOIs: [POI], startingCity: String) async {
    isEnrichingAllPOIs = true
    
    // Filtere POIs die noch nicht enriched wurden
    let unenrichedPOIs = discoveredPOIs.filter { poi in
      enrichedPOIs[poi.id] == nil
    }
    
    guard !unenrichedPOIs.isEmpty else {
      isEnrichingAllPOIs = false
      SecureLogger.shared.logDebug("📚 [Phase 2] All POIs already enriched", category: .data)
      return
    }
    
    SecureLogger.shared.logDebug("📚 [Phase 2] Background enriching \(unenrichedPOIs.count) additional POIs...", category: .data)
    
    // Enriche im Hintergrund (mit langsamerer Rate für bessere UX)
    let cityName = extractCityName(from: startingCity)
    var completedCount = 0
    for poi in unenrichedPOIs {
      do {
        let enrichedPOI = try await wikipediaService.enrichPOI(poi, cityName: cityName)
        
        enrichedPOIs[enrichedPOI.basePOI.id] = enrichedPOI
        completedCount += 1
        enrichmentProgress = Double(completedCount) / Double(unenrichedPOIs.count)
        
        // Längere Pause für Hintergrund-Enrichment
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
      } catch {
        SecureLogger.shared.logWarning("📚 [Phase 2] Failed to enrich POI '\(poi.name)': \(error.localizedDescription)", category: .data)
      }
    }
    
    isEnrichingAllPOIs = false
    enrichmentProgress = 1.0
    
    let totalEnriched = enrichedPOIs.values.filter { $0.wikipediaData != nil }.count
    SecureLogger.shared.logInfo("📚 [Phase 2] Background enrichment completed: \(totalEnriched)/\(discoveredPOIs.count) total enriched", category: .data)
  }
  
  // MARK: - Helper Methods
  
  /// Extrahiert POI-Objekte aus den Route-Waypoints
  private func extractPOIsFromRoute(route: GeneratedRoute, discoveredPOIs: [POI]) -> [POI] {
    var routePOIs: [POI] = []
    
    // Waypoints ohne Start/End (Index 0 und letzter)
    let poiWaypoints = Array(route.waypoints.dropFirst().dropLast())
    
    for waypoint in poiWaypoints {
      // Finde das ursprüngliche POI basierend auf Koordinaten und Name
      if let originalPOI = discoveredPOIs.first(where: { poi in
        let nameMatch = poi.name.lowercased() == waypoint.name.lowercased()
        let coordinateMatch = abs(poi.coordinate.latitude - waypoint.coordinate.latitude) < 0.001 &&
                              abs(poi.coordinate.longitude - waypoint.coordinate.longitude) < 0.001
        return nameMatch || coordinateMatch
      }) {
        routePOIs.append(originalPOI)
      }
    }
    
    return routePOIs
  }
  
  /// Extrahiert nur den Stadtnamen aus einer vollständigen Adresse
  /// Beispiele: "Bienenweg 4, 90537 Feucht" → "Feucht", "Berlin" → "Berlin"
  private func extractCityName(from fullAddress: String) -> String {
    let trimmed = fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Split by comma and take the last part (meist Stadt + Land)
    let parts = trimmed.components(separatedBy: ",")
    let lastPart = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? trimmed
    
    // Split by spaces and find the city after postal code
    let words = lastPart.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    // Finde Wort nach Postleitzahl (5 Zahlen) oder nehme letztes Wort
    for i in 0..<words.count {
      let word = words[i]
      // Ist das eine deutsche Postleitzahl? (5 Zahlen)
      if word.count == 5 && word.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
        // Nehme das nächste Wort als Stadt
        if i + 1 < words.count {
          return words[i + 1]
        }
      }
    }
    
    // Fallback: Nehme das letzte Wort (meist Stadt)
    return words.last ?? trimmed
  }
}
