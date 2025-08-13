import Foundation
import CoreLocation

// MARK: - Wikipedia Service
@MainActor
class WikipediaService: ObservableObject {
    static let shared = WikipediaService()
    
    // Secure Logging
    private lazy var secureLogger = SecureLogger.shared
    
    // Network Security
    private let networkSecurity = NetworkSecurityManager.shared
    
    // Wikipedia API Base URLs
    private let baseURL = "https://de.wikipedia.org"
    private let apiPath = "/w/api.php"
    private let restAPIPath = "/api/rest_v1/page/summary"
    
    private let urlSession: URLSession
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cache für Wikipedia-Daten (Requests)
    private var searchCache: [String: WikipediaOpenSearchResponse] = [:]
    private var summaryCache: [String: WikipediaSummary] = [:]
    private let cacheTimeout: TimeInterval = 24 * 60 * 60 // 24 Stunden
    private var cacheTimestamps: [String: Date] = [:]
    
    // Cache für bereits angereicherte POIs (Ergebnis-Cache auf POI-Ebene)
    private var enrichedPOICache: [String: WikipediaEnrichedPOI] = [:] // key: poi.id
    private var enrichedTimestamps: [String: Date] = [:]
    
    init(urlSession: URLSession? = nil) {
        self.urlSession = urlSession ?? NetworkSecurityManager.shared.secureSession
        secureLogger.logInfo("🔐 WikipediaService initialized", category: .security)
    }
    
    // MARK: - Public API
    
      /// Reichert einen POI mit Wikipedia-Daten an (optimiert mit Geoapify-Daten)
  func enrichPOI(_ poi: POI, cityName: String) async throws -> WikipediaEnrichedPOI {
    let enrichmentStart = Date()
    // 🔄 Ergebnis-Cache: Wenn wir diesen POI kürzlich angereichert haben, sofort zurückgeben
    if let cached = enrichedPOICache[poi.id],
       let ts = enrichedTimestamps[poi.id],
       Date().timeIntervalSince(ts) < cacheTimeout {
      // bewusst nur Debug, um Log-Noise zu vermeiden
      secureLogger.logDebug("📚 Enrichment cache hit for POI id=\(poi.id)", category: .data)
      return cached
    }
    
    // 🚀 OPTIMIZATION: Check if Geoapify already provided Wikipedia data
    if let geoapifyWikiData = poi.geoapifyWikiData,
       let wikipediaTitle = geoapifyWikiData.germanWikipediaTitle {
      
      // Removed verbose debug log
      
      // Skip OpenSearch - directly fetch summary with known title
      let enriched = try await enrichPOIWithDirectTitle(poi, wikipediaTitle: wikipediaTitle, geoapifyWikiData: geoapifyWikiData)
      logConsolidatedEnrichment(
        poi: poi,
        cityName: cityName,
        mode: "direct",
        title: wikipediaTitle,
        bestMatchTitle: nil,
        bestMatchScore: nil,
        summary: enriched.wikipediaData,
        finalScore: enriched.relevanceScore,
        status: "ok",
        startedAt: enrichmentStart
      )
       // Ergebnis cachen
       enrichedPOICache[poi.id] = enriched
       enrichedTimestamps[poi.id] = Date()
       return enriched
    }
    
    // Fallback: Traditional OpenSearch approach for POIs without Geoapify Wikipedia data
    
    // Schritt 1: OpenSearch für Wikipedia-Artikel (POI-Name + Stadt für bessere Genauigkeit)
    let searchResponse = try await searchWikipedia(for: poi.name, city: cityName)
        
        guard !searchResponse.searchResults.isEmpty else {
            logConsolidatedEnrichment(
              poi: poi,
              cityName: cityName,
              mode: "opensearch",
              title: nil,
              bestMatchTitle: nil,
              bestMatchScore: nil,
              summary: nil,
              finalScore: 0.0,
              status: "noResults",
              startedAt: enrichmentStart
            )
            return WikipediaEnrichedPOI(
                basePOI: poi,
                wikipediaData: nil,
                searchResult: nil,
                enrichmentTimestamp: Date(),
                relevanceScore: 0.0
            )
        }
        
        // Schritt 2: Beste Übereinstimmung finden
        guard let bestMatch = findBestMatch(searchResults: searchResponse.searchResults, for: poi) else {
            logConsolidatedEnrichment(
              poi: poi,
              cityName: cityName,
              mode: "opensearch",
              title: nil,
              bestMatchTitle: nil,
              bestMatchScore: nil,
              summary: nil,
              finalScore: 0.0,
              status: "noMatch",
              startedAt: enrichmentStart
            )
            return WikipediaEnrichedPOI(
                basePOI: poi,
                wikipediaData: nil,
                searchResult: nil,
                enrichmentTimestamp: Date(),
                relevanceScore: 0.0
            )
        }
        
        // Removed verbose debug log for best-match
        
        // Schritt 3: Detaillierte Summary-Daten abrufen
        let summaryData = try await fetchWikipediaSummary(title: bestMatch.title)
        
        // Schritt 4: Koordinaten-Validierung (falls verfügbar)
        let relevanceScore = calculateFinalRelevanceScore(
            searchResult: bestMatch,
            summaryData: summaryData,
            originalPOI: poi
        )
        
        // Removed verbose debug log for final score
        
        // Konsolidierte Ergebniszeile
        logConsolidatedEnrichment(
          poi: poi,
          cityName: cityName,
          mode: "opensearch",
          title: bestMatch.title,
          bestMatchTitle: bestMatch.title,
          bestMatchScore: bestMatch.relevanceScore(for: poi.name),
          summary: summaryData,
          finalScore: relevanceScore,
          status: "ok",
          startedAt: enrichmentStart
        )
        
        let enriched = WikipediaEnrichedPOI(
            basePOI: poi,
            wikipediaData: summaryData,
            searchResult: bestMatch,
            enrichmentTimestamp: Date(),
            relevanceScore: relevanceScore
        )
        // Ergebnis cachen
        enrichedPOICache[poi.id] = enriched
        enrichedTimestamps[poi.id] = Date()
        return enriched
    }
    
    /// Reichert mehrere POIs parallel an
    func enrichPOIs(_ pois: [POI], cityName: String) async throws -> [WikipediaEnrichedPOI] {
        secureLogger.logInfo("📚 Starting batch Wikipedia enrichment for \(pois.count) POIs in \(cityName)", category: .data)
        
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Parallel enrichment mit Rate Limiting
        var enrichedPOIs: [WikipediaEnrichedPOI] = []
        
        for poi in pois {
            do {
                let enrichedPOI = try await enrichPOI(poi, cityName: cityName)
                enrichedPOIs.append(enrichedPOI)
                
                // Rate Limiting: 100ms Pause zwischen Requests
                try await Task.sleep(nanoseconds: 100_000_000)
                
            } catch {
                secureLogger.logWarning("📚 Failed to enrich POI '\(poi.name)': \(error.localizedDescription)", category: .data)
                
                // Fallback: POI ohne Wikipedia-Daten
                let fallbackPOI = WikipediaEnrichedPOI(
                    basePOI: poi,
                    wikipediaData: nil,
                    searchResult: nil,
                    enrichmentTimestamp: Date(),
                    relevanceScore: 0.0
                )
                enrichedPOIs.append(fallbackPOI)
            }
        }
        
        let successCount = enrichedPOIs.filter { $0.wikipediaData != nil }.count
        secureLogger.logInfo("📚 Batch enrichment completed: \(successCount)/\(pois.count) successful", category: .data)
        
        return enrichedPOIs
    }
    
    // MARK: - Private Implementation
    
    /// Wikipedia OpenSearch API - Sucht mit POI-Name + Stadt für bessere Genauigkeit
    private func searchWikipedia(for poiName: String, city: String) async throws -> WikipediaOpenSearchResponse {
        // Kombiniere POI-Name und Stadt: "Schöner Brunnen Nürnberg"
        let searchQuery = "\(poiName) \(city)"
        let cacheKey = "search_\(searchQuery.lowercased())"
        
        // Cache Check
        if let cached = searchCache[cacheKey],
           let timestamp = cacheTimestamps[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            // Removed verbose debug log for cache hit (search)
            return cached
        }
        
        // URL Encoding
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        let urlString = "\(baseURL)\(apiPath)?action=opensearch&search=\(encodedQuery)&limit=5&namespace=0&format=json"
        
        // Removed verbose debug log for OpenSearch query
        
        guard let url = URL(string: urlString) else {
            throw WikipediaError.invalidURL
        }
        
        do {
            // Rate Limiting
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WikipediaError.invalidResponse
            }
            
            if httpResponse.statusCode == 429 {
                throw WikipediaError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WikipediaError.invalidResponse
            }
            
            // JSON als Array parsen
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any]
            guard let array = jsonArray,
                  let searchResponse = WikipediaOpenSearchResponse(from: array) else {
                throw WikipediaError.invalidResponse
            }
            
            // Cache speichern
            searchCache[cacheKey] = searchResponse
            cacheTimestamps[cacheKey] = Date()
            
            // Removed verbose debug log for OpenSearch results count
            
            return searchResponse
            
        } catch let error as WikipediaError {
            throw error
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    /// Wikipedia Summary API
    private func fetchWikipediaSummary(title: String) async throws -> WikipediaSummary {
        let cacheKey = "summary_\(title.lowercased())"
        
        // Cache Check
        if let cached = summaryCache[cacheKey],
           let timestamp = cacheTimestamps[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            // Removed verbose debug log for cache hit (summary)
            return cached
        }
        
        // URL Encoding
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        let urlString = "\(baseURL)\(restAPIPath)/\(encodedTitle)"
        
        // Removed verbose debug log for Summary request
        
        guard let url = URL(string: urlString) else {
            throw WikipediaError.invalidURL
        }
        
        do {
            // Rate Limiting
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WikipediaError.invalidResponse
            }
            
            if httpResponse.statusCode == 429 {
                throw WikipediaError.rateLimitExceeded
            }
            
            if httpResponse.statusCode == 404 {
                throw WikipediaError.noResults
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WikipediaError.invalidResponse
            }
            
            // JSON als WikipediaSummary dekodieren
            let decoder = JSONDecoder()
            let summary = try decoder.decode(WikipediaSummary.self, from: data)
            
            // Cache speichern
            summaryCache[cacheKey] = summary
            cacheTimestamps[cacheKey] = Date()
            
            // Removed verbose debug log for summary length
            
            return summary
            
        } catch let error as WikipediaError {
            throw error
        } catch let error as DecodingError {
            throw WikipediaError.decodingError(error)
        } catch {
            throw WikipediaError.networkError(error)
        }
    }
    
    /// Findet die beste Übereinstimmung aus den OpenSearch-Ergebnissen
    private func findBestMatch(searchResults: [WikipediaSearchResult], for poi: POI) -> WikipediaSearchResult? {
        guard !searchResults.isEmpty else {
            secureLogger.logWarning("📚 No search results provided for matching '\(poi.name)'", category: .data)
            return nil
        }
        
        // Berechne Relevanz-Scores für alle Ergebnisse
        let scoredResults = searchResults.map { result in
            (result, result.relevanceScore(for: poi.name))
        }
        
        // Sortiere nach Score (höchster zuerst)
        let sortedResults = scoredResults.sorted { $0.1 > $1.1 }
        
        // Debug-Logging der Kandidaten entfernt, um Log-Noise zu reduzieren
        
        let bestMatch = sortedResults.first!
        let bestScore = bestMatch.1
        
        // Qualitäts-Check: Reject schlechte Matches
        if bestScore < 0.4 {
            secureLogger.logWarning("📚 ❌ REJECTED: Best match '\(bestMatch.0.title)' has too low score \(String(format: "%.3f", bestScore)) for '\(poi.name)'", category: .data)
            return nil
        }
        
        // Removed verbose debug log for accepted match
        return bestMatch.0
    }
    
    /// Berechnet finalen Relevanz-Score unter Berücksichtigung aller Faktoren
    private func calculateFinalRelevanceScore(
        searchResult: WikipediaSearchResult,
        summaryData: WikipediaSummary?,
        originalPOI: POI
    ) -> Double {
        var score = searchResult.relevanceScore(for: originalPOI.name)
        
        // Bonus für verfügbare Daten
        if summaryData?.extract != nil && !(summaryData?.extract?.isEmpty ?? true) {
            score += 0.1 // Bonus für Extract
        }
        
        if summaryData?.thumbnail != nil {
            score += 0.1 // Bonus für Bild
        }
        
        // Koordinaten-Validierung (falls verfügbar)
        if let coordinates = summaryData?.coordinates {
            let distance = coordinates.distance(to: originalPOI.coordinate)
            if distance < 500 { // Innerhalb 500m
                score += 0.2 // Starker Bonus für Nähe
            } else if distance < 1000 { // Innerhalb 1km
                score += 0.1 // Schwacher Bonus
            }
            // Kein Bonus/Malus für größere Entfernungen
        }
        
        // Beschreibungs-Relevanz
        if let description = summaryData?.description,
           description.lowercased().contains(originalPOI.category.rawValue.lowercased()) {
            score += 0.05 // Bonus für Kategorie-Match
        }
        
            return min(score, 1.0) // Max 1.0
  }
  
  // MARK: - Optimized Enrichment with Geoapify Data
  
  /// Reichert POI direkt mit bekanntem Wikipedia-Titel an (skip OpenSearch)
  private func enrichPOIWithDirectTitle(_ poi: POI, wikipediaTitle: String, geoapifyWikiData: GeoapifyWikiAndMedia) async throws -> WikipediaEnrichedPOI {
    
    // Direkt Wikipedia Summary API mit bekanntem Titel aufrufen
    let summaryData = try await fetchWikipediaSummary(title: wikipediaTitle)
    
    // Erstelle künstlichen SearchResult für Konsistenz mit dem bestehenden System
    let searchResult = WikipediaSearchResult(
      title: wikipediaTitle,
      description: summaryData.description ?? "Wikipedia-Artikel",
      url: summaryData.contentUrls?.desktop?.page ?? "https://de.wikipedia.org/wiki/\(wikipediaTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? wikipediaTitle)"
    )
    
    // Berechne Relevanz-Score (hoch, da direkt von Geoapify)
    let relevanceScore = calculateDirectRelevanceScore(
      summaryData: summaryData,
      originalPOI: poi,
      geoapifyWikiData: geoapifyWikiData
    )
    
    // Removed verbose debug log for direct enrichment result
    
    let enriched = WikipediaEnrichedPOI(
      basePOI: poi,
      wikipediaData: summaryData,
      searchResult: searchResult,
      enrichmentTimestamp: Date(),
      relevanceScore: relevanceScore
    )
    // Ergebnis cachen
    enrichedPOICache[poi.id] = enriched
    enrichedTimestamps[poi.id] = Date()
    return enriched
  }

  // MARK: - Consolidated Logging
  private func logConsolidatedEnrichment(
    poi: POI,
    cityName: String,
    mode: String, // "direct" | "opensearch"
    title: String?,
    bestMatchTitle: String?,
    bestMatchScore: Double?,
    summary: WikipediaSummary?,
    finalScore: Double?,
    status: String, // "ok" | "noResults" | "noMatch"
    startedAt: Date
  ) {
    let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
    let extractLen = summary?.extract?.count ?? 0
    let hasImage = summary?.thumbnail != nil
    var parts: [String] = []
    parts.append("Wikipedia | POI='\(poi.name)' city='\(cityName)'")
    parts.append("mode=\(mode)")
    parts.append("status=\(status)")
    if let t = title { parts.append("title='\(t)'") }
    if let bt = bestMatchTitle { parts.append("best='\(bt)'") }
    if let bs = bestMatchScore { parts.append("matchScore=\(String(format: "%.2f", bs))") }
    parts.append("summaryChars=\(extractLen)")
    parts.append("image=\(hasImage ? "yes" : "no")")
    if let fs = finalScore { parts.append("finalScore=\(String(format: "%.2f", fs))") }
    parts.append("durationMs=\(durationMs)")
    secureLogger.logInfo(parts.joined(separator: " | "), category: .data)
  }
  
  /// Berechnet Relevanz-Score für direkte Geoapify-Wikipedia-Matches
  private func calculateDirectRelevanceScore(
    summaryData: WikipediaSummary?,
    originalPOI: POI,
    geoapifyWikiData: GeoapifyWikiAndMedia
  ) -> Double {
    var score: Double = 0.8 // Hohe Grundwertung da direkt von Geoapify
    
    // Bonus für verfügbare Daten
    if summaryData?.extract != nil && !(summaryData?.extract?.isEmpty ?? true) {
      score += 0.1 // Bonus für Extract
    }
    
    if summaryData?.thumbnail != nil {
      score += 0.1 // Bonus für Bild
    }
    
    // Koordinaten-Validierung (falls verfügbar)
    if let coordinates = summaryData?.coordinates {
      let distance = coordinates.distance(to: originalPOI.coordinate)
      if distance < 500 { // Innerhalb 500m
        score += 0.05 // Bonus für Nähe
      }
    }
    
    // Wikidata-ID als Qualitätsindikator
    if geoapifyWikiData.wikidata != nil {
      score += 0.05 // Bonus für Wikidata-Verknüpfung
    }
    
    return min(score, 1.0) // Max 1.0
  }
  
  // MARK: - Cache Management
    
    /// Löscht veraltete Cache-Einträge
    func cleanupCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) > cacheTimeout ? key : nil
        }
        
        for key in expiredKeys {
            if key.hasPrefix("search_") {
                searchCache.removeValue(forKey: key)
            } else if key.hasPrefix("summary_") {
                summaryCache.removeValue(forKey: key)
            }
            cacheTimestamps.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            secureLogger.logInfo("📚 Cleaned up \(expiredKeys.count) expired cache entries", category: .data)
        }
        // Clean enriched cache as well
        let enrichedExpired = enrichedTimestamps.compactMap { key, ts in
            now.timeIntervalSince(ts) > cacheTimeout ? key : nil
        }
        for key in enrichedExpired { enrichedPOICache.removeValue(forKey: key); enrichedTimestamps.removeValue(forKey: key) }
        if !enrichedExpired.isEmpty {
            secureLogger.logInfo("📚 Cleaned up \(enrichedExpired.count) expired enriched entries", category: .data)
        }
    }
    
    /// Löscht kompletten Cache
    func clearCache() {
        searchCache.removeAll()
        summaryCache.removeAll()
        cacheTimestamps.removeAll()
        enrichedPOICache.removeAll()
        enrichedTimestamps.removeAll()
        secureLogger.logInfo("📚 Wikipedia cache cleared", category: .data)
    }
    
    // MARK: - Debugging & Statistics
    
    /// Debugging-Informationen über den Cache
    func getCacheStats() -> (searchEntries: Int, summaryEntries: Int, totalSize: Int) {
        return (
            searchEntries: searchCache.count,
            summaryEntries: summaryCache.count,
            totalSize: searchCache.count + summaryCache.count + enrichedPOICache.count
        )
    }
}