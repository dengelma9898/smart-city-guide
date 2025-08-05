// BEISPIEL: Verwendung des WikipediaService
// Diese Datei zeigt, wie der WikipediaService verwendet werden kann
// NICHT in das Xcode-Projekt einbinden - nur zur Dokumentation!

import Foundation

// MARK: - Beispiel 1: Einzelnen POI enrichen
func enrichSinglePOI() async {
    let service = WikipediaService.shared
    
    // Beispiel-POI (normalerweise von Geoapify)
    let examplePOI = POI(
        id: "example_1",
        name: "Kaiserburg Nürnberg",
        latitude: 49.4583,
        longitude: 11.0758,
        category: .castle,
        description: "Burg in Nürnberg",
        tags: [:],
        sourceType: "geoapify",
        sourceId: 12345,
        address: nil,
        contact: nil,
        accessibility: nil,
        pricing: nil,
        operatingHours: nil,
        website: nil
    )
    
    do {
        let enrichedPOI = try await service.enrichPOI(examplePOI, cityName: "Nürnberg")
        
        print("🏰 Original: \(enrichedPOI.basePOI.name)")
        print("📚 Wikipedia: \(enrichedPOI.wikipediaData?.title ?? "Nicht gefunden")")
        print("📖 Beschreibung: \(enrichedPOI.enhancedDescription)")
        print("🖼️ Bild: \(enrichedPOI.wikipediaImageURL ?? "Kein Bild")")
        print("🎯 Relevanz: \(String(format: "%.2f", enrichedPOI.relevanceScore))")
        print("✅ Hochwertig: \(enrichedPOI.isHighQuality)")
        
    } catch {
        print("❌ Fehler: \(error.localizedDescription)")
    }
}

// MARK: - Beispiel 2: Mehrere POIs parallel enrichen
func enrichMultiplePOIs() async {
    let service = WikipediaService.shared
    
    let examplePOIs = [
        POI(id: "1", name: "Kaiserburg Nürnberg", latitude: 49.4583, longitude: 11.0758, 
            category: .castle, description: nil, tags: [:], sourceType: "geoapify", sourceId: 1,
            address: nil, contact: nil, accessibility: nil, pricing: nil, operatingHours: nil, website: nil),
        
        POI(id: "2", name: "Germanisches Nationalmuseum", latitude: 49.4447, longitude: 11.0736,
            category: .museum, description: nil, tags: [:], sourceType: "geoapify", sourceId: 2,
            address: nil, contact: nil, accessibility: nil, pricing: nil, operatingHours: nil, website: nil),
        
        POI(id: "3", name: "Hauptkirche St. Lorenz", latitude: 49.4500, longitude: 11.0775,
            category: .placeOfWorship, description: nil, tags: [:], sourceType: "geoapify", sourceId: 3,
            address: nil, contact: nil, accessibility: nil, pricing: nil, operatingHours: nil, website: nil)
    ]
    
    do {
        let enrichedPOIs = try await service.enrichPOIs(examplePOIs, cityName: "Nürnberg")
        
        print("📚 Batch Enrichment Ergebnisse:")
        for enrichedPOI in enrichedPOIs {
            print("---")
            print("🏛️ \(enrichedPOI.basePOI.name)")
            print("   📖 Wikipedia: \(enrichedPOI.wikipediaData?.title ?? "❌")")
            print("   🎯 Score: \(String(format: "%.2f", enrichedPOI.relevanceScore))")
            print("   🖼️ Bild: \(enrichedPOI.wikipediaImageURL != nil ? "✅" : "❌")")
            print("   📍 Koordinaten: \(enrichedPOI.isLocationValidated ? "✅" : "❌")")
        }
        
        let highQualityCount = enrichedPOIs.filter { $0.isHighQuality }.count
        print("📊 Hochwertige Enrichments: \(highQualityCount)/\(enrichedPOIs.count)")
        
    } catch {
        print("❌ Batch-Fehler: \(error.localizedDescription)")
    }
}

// MARK: - Beispiel 3: Integration in RouteBuilderView (Konzept)
func integrationExample() {
    /*
    // In RouteBuilderView.swift könnte es so aussehen:
    
    @StateObject private var wikipediaService = WikipediaService.shared
    @State private var enrichedPOIs: [WikipediaEnrichedPOI] = []
    
    private func loadPOIsAndEnrich() async {
        do {
            // Schritt 1: POIs von Geoapify laden
            let basePOIs = try await geoapifyService.fetchPOIs(for: startingCity)
            
            // Schritt 2: Wikipedia-Enrichment
            enrichedPOIs = try await wikipediaService.enrichPOIs(basePOIs, cityName: startingCity)
            
            // Schritt 3: Route generieren (mit Original-POIs)
            let originalPOIs = enrichedPOIs.map { $0.basePOI }
            await routeService.generateRoute(
                startingCity: startingCity,
                numberOfPlaces: numberOfPlaces,
                endpointOption: endpointOption,
                customEndpoint: customEndpoint,
                routeLength: routeLength,
                availablePOIs: originalPOIs
            )
            
        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
        }
    }
    */
}

// MARK: - Beispiel 4: Cache-Management
func cacheManagementExample() {
    let service = WikipediaService.shared
    
    // Cache-Statistiken anzeigen
    let stats = service.getCacheStats()
    print("📊 Cache Stats:")
    print("   🔍 OpenSearch: \(stats.searchEntries) Einträge")
    print("   📄 Summaries: \(stats.summaryEntries) Einträge")
    print("   📦 Gesamt: \(stats.totalSize) Einträge")
    
    // Veraltete Einträge löschen
    service.cleanupCache()
    
    // Kompletten Cache löschen (bei Bedarf)
    // service.clearCache()
}

// MARK: - Beispiel 5: Error Handling
func errorHandlingExample() async {
    let service = WikipediaService.shared
    
    let problematicPOI = POI(
        id: "error_test",
        name: "Nicht existierender Ort xyz123",
        latitude: 0.0,
        longitude: 0.0,
        category: .attraction,
        description: nil,
        tags: [:],
        sourceType: "test",
        sourceId: 99999,
        address: nil, contact: nil, accessibility: nil, pricing: nil, operatingHours: nil, website: nil
    )
    
    do {
        let result = try await service.enrichPOI(problematicPOI, cityName: "TestStadt")
        
        if result.wikipediaData == nil {
            print("⚠️ Kein Wikipedia-Artikel gefunden für: \(problematicPOI.name)")
            print("📄 Fallback-Beschreibung: \(result.enhancedDescription)")
        }
        
    } catch WikipediaError.noResults {
        print("❌ Keine Wikipedia-Ergebnisse")
    } catch WikipediaError.rateLimitExceeded {
        print("❌ Rate Limit erreicht - später versuchen")
    } catch WikipediaError.networkError(let error) {
        print("❌ Netzwerkfehler: \(error.localizedDescription)")
    } catch {
        print("❌ Unerwarteter Fehler: \(error.localizedDescription)")
    }
}

// MARK: - API-Endpoints für Debugging
func debugAPIEndpoints() {
    print("🌐 Wikipedia API Endpoints:")
    print("📚 OpenSearch: https://de.wikipedia.org/w/api.php?action=opensearch&search=QUERY&limit=5&namespace=0&format=json")
    print("📄 Summary: https://de.wikipedia.org/api/rest_v1/page/summary/TITLE")
    print("")
    print("🧪 Test URLs:")
    print("🏰 Kaiserburg: https://de.wikipedia.org/api/rest_v1/page/summary/Kaiserburg_Nürnberg")
    print("🏛️ Museum: https://de.wikipedia.org/api/rest_v1/page/summary/Germanisches_Nationalmuseum")
    print("⛪ Kirche: https://de.wikipedia.org/api/rest_v1/page/summary/St._Sebaldus_(Nürnberg)")
}