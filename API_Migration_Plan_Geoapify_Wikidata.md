# API Migration Plan: HERE → Geoapify + Wikimedia/Wikidata

## 🎯 Migrationsziel
Wechsel von HERE API zu **Geoapify Places API + Wikimedia/Wikidata API** für bessere POI-Filterung und Bilddaten.

## 📋 Migration Overview

### Phase 1: HERE → Geoapify Places API
- ✅ **Ziel**: Kompletter Ersatz der HERE API durch Geoapify Places API
- ✅ **Fokus**: POI-Discovery mit verbesserter Kategorien-Filterung
- ✅ **Scope**: `HEREAPIService.swift` → `GeoapifyAPIService.swift`

### Phase 2: Wikimedia/Wikidata Integration  
- ✅ **Ziel**: Anreicherung der POIs mit Bildern und detaillierten Beschreibungen
- ✅ **Fokus**: Zusätzliche Datenquelle für Metadaten
- ✅ **Scope**: Neuer `WikidataService.swift`

### Phase 3: HERE API Removal
- ✅ **Ziel**: Vollständige Entfernung der HERE API Integration
- ✅ **Fokus**: Code-Cleanup und Dependency-Entfernung
- ✅ **Scope**: Löschen aller HERE-spezifischen Komponenten

---

## 🏗️ Phase 1: HERE API → Geoapify Places API Migration

### 1.1 Neue Service-Klasse erstellen

#### `GeoapifyAPIService.swift`
```swift
@MainActor
class GeoapifyAPIService: ObservableObject {
    static let shared = GeoapifyAPIService()
    
    // API Configuration
    private var apiKey: String { /* APIKeys.plist */ }
    private let baseURL = "https://api.geoapify.com/v2"
    private let urlSession: URLSession
    
    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String?
}
```

### 1.2 API Endpoints Mapping

| HERE API Feature | Geoapify Equivalent | Notes |
|-----------------|-------------------|-------|
| Geocoding | `/geocode/search` | City → Coordinates |
| Browse POI Search | `/places` | Categories + Radius |
| Rate Limiting | Standard HTTP 429 | Similar handling |
| Category Filtering | `categories` parameter | Better granularity |

### 1.3 Geoapify Categories Mapping

#### Aktueller HERE Category Mapping:
```swift
// HEREAPIService.swift:568-596
case .attraction: return "300-3000-0023"  // Tourist Attraction
case .monument: return "300-3000-0025"    // Historical Monument
case .castle: return "300-3000-0030"      // Castle
case .museum: return "300-3100-0000"      // Museum
```

#### Neuer Geoapify Category Mapping:
```swift
// GeoapifyAPIService.swift (neu)
extension PlaceCategory {
    var geoapifyCategories: [String] {
        switch self {
        case .attraction:
            return ["tourism.attraction", "heritage", "tourism.information"]
        case .monument:
            return ["heritage.monument", "tourism.attraction.heritage"]
        case .castle:
            return ["heritage.castle", "tourism.attraction.heritage"]
        case .museum:
            return ["entertainment.museum", "tourism.attraction.culture"]
        case .park:
            return ["leisure.park", "natural"]
        case .gallery:
            return ["entertainment.gallery", "tourism.attraction.culture"]
        // ... weitere Mappings
        }
    }
}
```

### 1.4 Response Models Migration

#### Neue Geoapify Response Models:
```swift
// GeoapifyResponseModels.swift (neu)
struct GeoapifyResponse: Codable {
    let type: String
    let features: [GeoapifyFeature]
}

struct GeoapifyFeature: Codable {
    let type: String
    let properties: GeoapifyProperties
    let geometry: GeoapifyGeometry
}

struct GeoapifyProperties: Codable {
    let name: String?
    let formatted: String?
    let categories: [String]?
    let details: [String]?
    let datasource: GeoapifyDatasource?
    let address_line1: String?
    let address_line2: String?
    let city: String?
    let postcode: String?
    let country: String?
    let phone: String?
    let website: String?
    let opening_hours: String?
}

struct GeoapifyGeometry: Codable {
    let type: String
    let coordinates: [Double] // [lng, lat]
}

struct GeoapifyDatasource: Codable {
    let sourcename: String?
    let attribution: String?
    let license: String?
    let url: String?
}
```

### 1.5 POI Conversion Logic

#### POI Extension für Geoapify:
```swift
// POI+Geoapify.swift (neu)
extension POI {
    init?(from feature: GeoapifyFeature, category: PlaceCategory, requestedCity: String) {
        let props = feature.properties
        let coords = feature.geometry.coordinates
        
        // Basic Properties
        self.id = "geoapify_\(feature.hashValue)"
        self.name = props.name ?? "Unbekannter Ort"
        self.longitude = coords[0] // Geoapify: [lng, lat]
        self.latitude = coords[1]
        self.category = category
        self.sourceType = "geoapify_poi"
        self.sourceId = Int64(feature.hashValue)
        
        // Address Information
        self.address = POIAddress(
            street: props.address_line1,
            houseNumber: nil,
            city: props.city,
            postcode: props.postcode,
            country: props.country
        )
        
        // Contact Information
        self.contact = POIContact(
            phone: props.phone,
            email: nil,
            website: props.website
        )
        
        // Operating Hours
        self.operatingHours = props.opening_hours
        self.website = props.website
        
        // Description from categories/details
        self.description = props.details?.joined(separator: ", ") ?? category.rawValue
        
        // Tags from Geoapify data
        var tags: [String: String] = [:]
        if let categories = props.categories {
            tags["geoapify:categories"] = categories.joined(separator: ",")
        }
        if let datasource = props.datasource?.sourcename {
            tags["source"] = datasource
        }
        self.tags = tags
        
        // Initialize other fields
        self.accessibility = nil
        self.pricing = nil
    }
}
```

### 1.6 API Methods Migration

#### Hauptmethoden Mapping:
```swift
// GeoapifyAPIService.swift

// ALTE HERE Methode:
// func fetchPOIs(for cityName: String, categories: [PlaceCategory]) async throws -> [POI]

// NEUE Geoapify Methode:
func fetchPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories) async throws -> [POI] {
    // 1. Geocoding (falls nötig - kann City Cache verwenden)
    let cityLocation = try await geocodeCity(cityName)
    
    // 2. Places Search mit besserer Kategorien-Filterung
    let pois = try await searchPOIs(near: cityLocation, categories: categories, cityName: cityName)
    
    // 3. Cache wie zuvor
    await POICacheService.shared.cachePOIs(pois, for: cityName)
    return pois
}

private func searchPOIs(near location: CLLocationCoordinate2D, categories: [PlaceCategory], cityName: String) async throws -> [POI] {
    let categoryParams = categories.flatMap { $0.geoapifyCategories }.joined(separator: ",")
    
    // Geoapify Places API Call
    let urlString = "\(baseURL)/places?categories=\(categoryParams)&filter=circle:\(location.longitude),\(location.latitude),5000&limit=50&apiKey=\(apiKey)"
    
    // ... HTTP request logic ähnlich zu HERE
    
    let response = try JSONDecoder().decode(GeoapifyResponse.self, from: data)
    
    // Convert to POIs with intelligent category detection
    let allPOIs = response.features.compactMap { feature -> POI? in
        let detectedCategory = detectCategory(for: feature)
        return POI(from: feature, category: detectedCategory, requestedCity: cityName)
    }
    
    return Array(Set(allPOIs))
}

private func detectCategory(for feature: GeoapifyFeature) -> PlaceCategory {
    let name = feature.properties.name?.lowercased() ?? ""
    let categories = feature.properties.categories ?? []
    
    // Intelligente Kategorien-Erkennung basierend auf Geoapify categories
    for category in categories {
        if category.contains("museum") { return .museum }
        if category.contains("heritage.monument") { return .monument }
        if category.contains("heritage.castle") { return .castle }
        if category.contains("park") { return .park }
        // ... weitere Mappings
    }
    
    // Fallback auf Name-basierte Erkennung (wie HERE)
    // ... existing logic from HERE implementation
    
    return .attraction
}
```

### 1.7 Error Handling Migration

#### Neue Geoapify Error Types:
```swift
// GeoapifyAPIService.swift
enum GeoapifyError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case cityNotFound(String)
    case geocodingFailed(String)
    case searchFailed(String)
    case rateLimitExceeded
    case apiKeyInvalid
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die Geoapify API URL ist ungültig."
        case .invalidResponse(let statusCode):
            return "Ungültige Antwort vom Geoapify Server. Statuscode: \(statusCode)"
        case .cityNotFound(let city):
            return "Die Stadt '\(city)' konnte nicht gefunden werden. Bitte überprüfen Sie die Schreibweise."
        case .geocodingFailed(let description):
            return "Geocoding fehlgeschlagen: \(description)"
        case .searchFailed(let description):
            return "POI-Suche fehlgeschlagen: \(description)"
        case .rateLimitExceeded:
            return "Zu viele Anfragen an Geoapify API. Bitte warten Sie einen Moment und versuchen Sie es erneut."
        case .apiKeyInvalid:
            return "Geoapify API Key ist ungültig. Bitte konfigurieren Sie einen gültigen API Key."
        case .quotaExceeded:
            return "Geoapify API Quota überschritten. Bitte versuchen Sie es später erneut."
        }
    }
}
```

### 1.8 Security & Network Migration

#### Gleiche Security Standards beibehalten:
```swift
// GeoapifyAPIService.swift
class GeoapifyAPIService: ObservableObject {
    // Secure Logging beibehalten
    private lazy var secureLogger = SecureLogger.shared
    
    // Network Security mit Certificate Pinning
    private let networkSecurity = NetworkSecurityManager.shared
    
    // Secure API Key loading aus APIKeys.plist
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEOAPIFY_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("GEOAPIFY_API_KEY not found in APIKeys.plist.")
        }
        return key
    }
    
    init(urlSession: URLSession? = nil) {
        // Certificate Pinning für Geoapify domains
        self.urlSession = urlSession ?? NetworkSecurityManager.shared.secureSession
        secureLogger.logInfo("🔐 GeoapifyAPIService initialized with certificate pinning", category: .security)
    }
}
```

### 1.9 Cache Service Updates

#### Keine Änderungen nötig an POICacheService:
- ✅ **Kompatibel**: `POICacheService` arbeitet mit `[POI]` Arrays
- ✅ **Wiederverwendbar**: City-based caching funktioniert identisch
- ✅ **Bestehend**: Scoring und Geographic Distribution unverändert

### 1.10 Integration Points

#### RouteService Integration:
```swift
// RouteService.swift - Minimal Changes + Distance Filtering Deaktivierung
class RouteService: ObservableObject {
    // ALTE LINE: private let hereAPIService = HEREAPIService.shared
    // NEUE LINE: private let poiAPIService = GeoapifyAPIService.shared
    
    // Alle POI-fetching calls ändern sich minimal:
    // OLD: let pois = try await hereAPIService.fetchPOIs(for: cityName, categories: categories)
    // NEW: let pois = try await poiAPIService.fetchPOIs(for: cityName, categories: categories)
    
    // MIGRATION TESTING: Distance constraints deaktivieren
    private func generateRouteWithPOIs(..., routeLength: RouteLength, ...) async throws -> GeneratedRoute {
        // TESTING: Ignore routeLength.searchRadiusMeters and maxTotalDistanceMeters
        let allPOIs = try await poiAPIService.fetchPOIs(for: cityName, categories: categories)
        
        // Skip distance-based POI filtering during migration
        let selectedPOIs = POICacheService.shared.selectBestPOIs(
            from: allPOIs,
            count: numberOfStops,
            routeLength: .long, // Always use largest radius for testing
            startCoordinate: startCoordinate,
            startingCity: cityName,
            categories: categories
        )
        
        // Generate route without distance validation
        let route = try await optimizeRouteOrder(waypoints: selectedPOIs)
        
        // TESTING: Skip maxTotalDistanceMeters validation
        return route // Accept any route length during migration
    }
}
```

---

## 🏗️ Phase 2: Wikimedia/Wikidata Integration

### 2.1 Neue Service-Klasse

#### `WikidataService.swift`
```swift
@MainActor
class WikidataService: ObservableObject {
    static let shared = WikidataService()
    
    private let wikidataBaseURL = "https://www.wikidata.org/w/api.php"
    private let wikimediaBaseURL = "https://commons.wikimedia.org/w/api.php"
    private let urlSession: URLSession
    private let secureLogger = SecureLogger.shared
    
    @Published var isLoading = false
    
    // Cache für Wikidata-Ergebnisse
    private var imageCache: [String: WikiImage] = [:]
    private var descriptionCache: [String: String] = [:]
    
    init(urlSession: URLSession? = nil) {
        self.urlSession = urlSession ?? URLSession.shared
    }
}
```

### 2.2 Wikidata Search Methods

#### POI → Wikidata Matching:
```swift
// WikidataService.swift
func enrichPOI(_ poi: POI) async throws -> EnrichedPOI {
    // 1. Suche Wikidata Entity
    let wikidataEntity = try await searchWikidataEntity(name: poi.name, coordinates: poi.coordinate)
    
    var enrichedPOI = EnrichedPOI(from: poi)
    
    if let entity = wikidataEntity {
        // 2. Lade Beschreibung
        if let description = try await fetchWikidataDescription(entityId: entity.id) {
            enrichedPOI.detailedDescription = description
        }
        
        // 3. Lade Bilder
        if let images = try await fetchWikimediaImages(entityId: entity.id) {
            enrichedPOI.images = images
        }
        
        // 4. Lade zusätzliche Metadaten
        if let metadata = try await fetchWikidataMetadata(entityId: entity.id) {
            enrichedPOI.wikidataMetadata = metadata
        }
    }
    
    return enrichedPOI
}

private func searchWikidataEntity(name: String, coordinates: CLLocationCoordinate2D) async throws -> WikidataEntity? {
    // Wikidata Entity Search via SPARQL oder Wikidata API
    let query = buildWikidataSearchQuery(name: name, coordinates: coordinates)
    
    let urlString = "\(wikidataBaseURL)?action=wbsearchentities&search=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&language=de&format=json"
    
    guard let url = URL(string: urlString) else {
        throw WikidataError.invalidURL
    }
    
    let (data, _) = try await urlSession.data(from: url)
    let response = try JSONDecoder().decode(WikidataSearchResponse.self, from: data)
    
    return response.search.first
}

private func fetchWikidataDescription(entityId: String) async throws -> String? {
    let urlString = "\(wikidataBaseURL)?action=wbgetentities&ids=\(entityId)&props=descriptions&languages=de&format=json"
    
    guard let url = URL(string: urlString) else { return nil }
    
    let (data, _) = try await urlSession.data(from: url)
    let response = try JSONDecoder().decode(WikidataEntityResponse.self, from: data)
    
    return response.entities[entityId]?.descriptions?["de"]?.value
}

private func fetchWikimediaImages(entityId: String) async throws -> [WikiImage]? {
    // 1. Hole P18 (image) Property von Wikidata
    let imageFileNames = try await fetchWikidataImageProperties(entityId: entityId)
    
    var images: [WikiImage] = []
    
    // 2. Für jedes Bild, hole Wikimedia Commons URLs
    for fileName in imageFileNames.prefix(3) { // Limit auf 3 Bilder
        if let imageInfo = try await fetchWikimediaImageInfo(fileName: fileName) {
            images.append(imageInfo)
        }
    }
    
    return images.isEmpty ? nil : images
}

private func fetchWikidataImageProperties(entityId: String) async throws -> [String] {
    let urlString = "\(wikidataBaseURL)?action=wbgetentities&ids=\(entityId)&props=claims&format=json"
    
    guard let url = URL(string: urlString) else { return [] }
    
    let (data, _) = try await urlSession.data(from: url)
    let response = try JSONDecoder().decode(WikidataEntityResponse.self, from: data)
    
    // Extrahiere P18 (image) claims
    return response.entities[entityId]?.claims?.P18?.compactMap { claim in
        claim.mainsnak?.datavalue?.value?.stringValue
    } ?? []
}

private func fetchWikimediaImageInfo(fileName: String) async throws -> WikiImage? {
    let urlString = "\(wikimediaBaseURL)?action=query&titles=File:\(fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&prop=imageinfo&iiprop=url|size|metadata&iiurlwidth=800&format=json"
    
    guard let url = URL(string: urlString) else { return nil }
    
    let (data, _) = try await urlSession.data(from: url)
    let response = try JSONDecoder().decode(WikimediaImageResponse.self, from: data)
    
    guard let page = response.query.pages.values.first,
          let imageInfo = page.imageinfo?.first else { return nil }
    
    return WikiImage(
        fileName: fileName,
        url: imageInfo.url,
        thumbUrl: imageInfo.thumburl,
        width: imageInfo.width,
        height: imageInfo.height,
        description: imageInfo.extmetadata?.imageDescription?.value
    )
}
```

### 2.3 Erweiterte POI Models

#### `EnrichedPOI.swift` (neu):
```swift
// Models/EnrichedPOI.swift
struct EnrichedPOI: Identifiable, Codable {
    // Basis POI Daten
    let basePOI: POI
    
    // Wikidata Erweiterungen
    let detailedDescription: String?
    let images: [WikiImage]?
    let wikidataMetadata: WikidataMetadata?
    
    // Computed Properties
    var id: String { basePOI.id }
    var name: String { basePOI.name }
    var coordinate: CLLocationCoordinate2D { basePOI.coordinate }
    var category: PlaceCategory { basePOI.category }
    
    // Enhanced Display Properties
    var primaryImage: WikiImage? { images?.first }
    var hasImages: Bool { !(images?.isEmpty ?? true) }
    var richDescription: String {
        detailedDescription ?? basePOI.displayDescription
    }
    
    init(from poi: POI) {
        self.basePOI = poi
        self.detailedDescription = nil
        self.images = nil
        self.wikidataMetadata = nil
    }
    
    func withEnrichments(description: String?, images: [WikiImage]?, metadata: WikidataMetadata?) -> EnrichedPOI {
        return EnrichedPOI(
            basePOI: self.basePOI,
            detailedDescription: description,
            images: images,
            wikidataMetadata: metadata
        )
    }
}

struct WikiImage: Codable {
    let fileName: String
    let url: String
    let thumbUrl: String?
    let width: Int?
    let height: Int?
    let description: String?
}

struct WikidataMetadata: Codable {
    let entityId: String
    let architecturalStyle: String?
    let constructionYear: String?
    let website: String?
    let coordinates: WikidataCoordinates?
    let categories: [String]?
}

struct WikidataCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}
```

### 2.4 Wikidata Response Models

#### `WikidataModels.swift` (neu):
```swift
// Models/WikidataModels.swift
struct WikidataSearchResponse: Codable {
    let search: [WikidataEntity]
}

struct WikidataEntity: Codable {
    let id: String
    let label: String?
    let description: String?
    let concepturi: String?
}

struct WikidataEntityResponse: Codable {
    let entities: [String: WikidataEntityDetail]
}

struct WikidataEntityDetail: Codable {
    let id: String
    let descriptions: [String: WikidataDescription]?
    let claims: WikidataClaims?
}

struct WikidataDescription: Codable {
    let language: String
    let value: String
}

struct WikidataClaims: Codable {
    let P18: [WikidataClaim]? // image
    let P31: [WikidataClaim]? // instance of
    let P625: [WikidataClaim]? // coordinate location
}

struct WikidataClaim: Codable {
    let mainsnak: WikidataMainsnak?
}

struct WikidataMainsnak: Codable {
    let datavalue: WikidataDatavalue?
}

struct WikidataDatavalue: Codable {
    let value: WikidataValue?
}

struct WikidataValue: Codable {
    let stringValue: String?
    
    private enum CodingKeys: String, CodingKey {
        case stringValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            stringValue = string
        } else {
            stringValue = nil
        }
    }
}

// Wikimedia Commons Models
struct WikimediaImageResponse: Codable {
    let query: WikimediaQuery
}

struct WikimediaQuery: Codable {
    let pages: [String: WikimediaPage]
}

struct WikimediaPage: Codable {
    let pageid: Int?
    let title: String?
    let imageinfo: [WikimediaImageInfo]?
}

struct WikimediaImageInfo: Codable {
    let url: String
    let thumburl: String?
    let width: Int?
    let height: Int?
    let extmetadata: WikimediaExtMetadata?
}

struct WikimediaExtMetadata: Codable {
    let imageDescription: WikimediaMetadataValue?
    
    private enum CodingKeys: String, CodingKey {
        case imageDescription = "ImageDescription"
    }
}

struct WikimediaMetadataValue: Codable {
    let value: String
}
```

### 2.5 Service Integration

#### Geoapify + Wikidata Workflow:
```swift
// EnrichedPOIService.swift (neu)
@MainActor
class EnrichedPOIService: ObservableObject {
    static let shared = EnrichedPOIService()
    
    private let geoapifyService = GeoapifyAPIService.shared
    private let wikidataService = WikidataService.shared
    
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    
    /// Hauptmethode: Hole POIs von Geoapify und reichere sie mit Wikidata an
    func fetchEnrichedPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories) async throws -> [EnrichedPOI] {
        
        await MainActor.run { isLoading = true; progress = 0.0 }
        defer { Task { @MainActor in isLoading = false } }
        
        // Phase 1: Hole POIs von Geoapify (60% des Fortschritts)
        let basePOIs = try await geoapifyService.fetchPOIs(for: cityName, categories: categories)
        await MainActor.run { progress = 0.6 }
        
        // Phase 2: Reichere die besten POIs mit Wikidata an (40% des Fortschritts)
        let topPOIs = Array(basePOIs.prefix(15)) // Limitiere auf 15 POIs für Wikidata-Enrichment
        var enrichedPOIs: [EnrichedPOI] = []
        
        for (index, poi) in topPOIs.enumerated() {
            do {
                let enriched = try await wikidataService.enrichPOI(poi)
                enrichedPOIs.append(enriched)
            } catch {
                // Bei Wikidata-Fehlern: verwende basis POI ohne Enrichment
                enrichedPOIs.append(EnrichedPOI(from: poi))
            }
            
            await MainActor.run { 
                progress = 0.6 + (0.4 * Double(index + 1) / Double(topPOIs.count))
            }
        }
        
        // Füge restliche POIs ohne Enrichment hinzu
        let remainingPOIs = Array(basePOIs.dropFirst(15)).map { EnrichedPOI(from: $0) }
        enrichedPOIs.append(contentsOf: remainingPOIs)
        
        return enrichedPOIs
    }
}
```

---

## 🏗️ Phase 3: HERE API Removal

### 3.1 Dateien zum Löschen

#### Vollständig entfernen:
```bash
# Core HERE API Files
ios/SmartCityGuide/Services/HEREAPIService.swift

# HERE-spezifische Response Models (falls separiert)
# ios/SmartCityGuide/Models/HEREModels.swift (falls vorhanden)
```

### 3.2 Code-Bereiche zum Bereinigen

#### In bestehenden Dateien:
```swift
// HEREAPIService.swift: Lines 1-780 → LÖSCHEN
// POI.swift: Lines 658-780 (HERE Extension) → LÖSCHEN  
// PlaceCategory.swift: Lines 551-654 (HERE Integration) → LÖSCHEN
```

### 3.3 Dependencies & References

#### RouteService Updates:
```swift
// RouteService.swift
class RouteService: ObservableObject {
    // REMOVE: private let hereAPIService = HEREAPIService.shared
    // ADD: private let enrichedPOIService = EnrichedPOIService.shared
    
    private func generateRouteWithPOIs(...) async throws -> GeneratedRoute {
        // OLD: let pois = try await hereAPIService.fetchPOIs(...)
        // NEW: let enrichedPOIs = try await enrichedPOIService.fetchEnrichedPOIs(...)
        
        // Convert EnrichedPOI → POI für bestehende TSP Logic
        let pois = enrichedPOIs.map { $0.basePOI }
        
        // ... rest bleibt unverändert
    }
}
```

### 3.4 API Key Configuration

#### APIKeys.plist Updates:
```xml
<!-- REMOVE HERE_API_KEY -->
<!-- ADD GEOAPIFY_API_KEY -->
<dict>
    <key>GEOAPIFY_API_KEY</key>
    <string>YOUR_GEOAPIFY_API_KEY</string>
    <!-- Wikidata/Wikimedia benötigt keine API Keys -->
</dict>
```

### 3.5 Certificate Pinning Updates

#### NetworkSecurityManager.swift:
```swift
// NetworkSecurityManager.swift
class NetworkSecurityManager: NSObject, ObservableObject {
    
    // REMOVE HERE domain pinning
    // REMOVE: "discover.search.hereapi.com"
    // REMOVE: "geocoder.ls.hereapi.com"
    
    // ADD Geoapify domain pinning
    // ADD: "api.geoapify.com"
    
    // ADD Wikimedia domain pinning (optional)
    // ADD: "www.wikidata.org"
    // ADD: "commons.wikimedia.org"
}
```

---

## ⚠️ Important Testing Notes

### Distance Filtering Exclusion während Migration
🚨 **CRITICAL**: Beim Testen der API Migration sollen wir **Distance-Filterung IGNORIEREN**:

- ✅ **UI Option beibehalten**: `RouteLength` Picker in `RoutePlanningView.swift` bleibt sichtbar
- ❌ **Filtering deaktivieren**: Keine `maxDistance`/`searchRadiusMeters` Validierung anwenden
- ❌ **Total DistanceIgnorieren**: Keine `maxTotalDistanceMeters` Constraint-Prüfung
- ✅ **Einfache Route-Generierung**: Nur gegebene Stops + Endpunkt verwenden

#### Betroffene Code-Bereiche:
```swift
// RouteService.swift - DEAKTIVIEREN während Migration Testing:
// Line 137: maxDistance: routeLength.searchRadiusMeters ❌
// Line 160: maxTotalDistance: routeLength.maxTotalDistanceMeters ❌

// POICacheService.swift - DEAKTIVIEREN während Migration Testing:
// Line 135: routeLength: routeLength ❌ 
// Line 205: getMaxDistanceForRouteLength(_ routeLength: RouteLength) ❌
```

#### Testing-spezifische Service Updates:
```swift
// GeoapifyAPIService.swift - Simplified für Testing
func fetchPOIs(for cityName: String, categories: [PlaceCategory]) async throws -> [POI] {
    let cityLocation = try await geocodeCity(cityName)
    
    // TESTING: Use fixed large radius instead of routeLength.searchRadiusMeters
    let pois = try await searchPOIs(near: cityLocation, categories: categories, cityName: cityName, radius: 20000) // 20km fixed
    
    await POICacheService.shared.cachePOIs(pois, for: cityName)
    return pois
}

// Simplified Route Generation für Testing
private func generateRouteWithPOIs(...) async throws -> GeneratedRoute {
    // TESTING: Skip distance validation
    // let maxTotalDistance = routeLength.maxTotalDistanceMeters ❌
    
    // Use all provided stops without distance constraints
    let route = try await optimizeRoute(waypoints: allWaypoints)
    
    // TESTING: Accept any route length
    return route // No distance validation
}
```

---

## 🧪 Testing Strategy

### 4.1 Phase 1 Testing (Geoapify)

#### Unit Tests:
```swift
// Tests/GeoapifyAPIServiceTests.swift
class GeoapifyAPIServiceTests: XCTestCase {
    
    func testGeocoding() async throws {
        let service = GeoapifyAPIService()
        let coordinates = try await service.geocodeCity("Nürnberg")
        XCTAssertEqual(coordinates.latitude, 49.4521, accuracy: 0.1)
        XCTAssertEqual(coordinates.longitude, 11.0767, accuracy: 0.1)
    }
    
    func testPOISearch() async throws {
        let service = GeoapifyAPIService()
        let pois = try await service.fetchPOIs(for: "Nürnberg", categories: [.attraction, .museum])
        XCTAssertGreaterThan(pois.count, 0)
        XCTAssertTrue(pois.contains { $0.category == .attraction })
    }
    
    func testCategoryMapping() {
        XCTAssertEqual(PlaceCategory.museum.geoapifyCategories, ["entertainment.museum", "tourism.attraction.culture"])
    }
}
```

#### Integration Tests:
```swift
// Tests/GeoapifyIntegrationTests.swift
class GeoapifyIntegrationTests: XCTestCase {
    
    func testFullWorkflow() async throws {
        // Test complete Geoapify → POI → Route workflow
        let service = GeoapifyAPIService()
        let pois = try await service.fetchPOIs(for: "Nürnberg")
        
        // Verify POI structure compatibility
        let routePoint = RoutePoint(from: pois.first!)
        XCTAssertNotNil(routePoint.name)
        XCTAssertNotEqual(routePoint.coordinate.latitude, 0)
    }
}
```

### 4.2 Phase 2 Testing (Wikidata)

#### Wikidata Service Tests:
```swift
// Tests/WikidataServiceTests.swift
class WikidataServiceTests: XCTestCase {
    
    func testWikidataSearch() async throws {
        let service = WikidataService()
        let poi = POI(/* test data */)
        let enriched = try await service.enrichPOI(poi)
        
        // Verify enrichment
        if enriched.images?.count ?? 0 > 0 {
            XCTAssertNotNil(enriched.primaryImage?.url)
        }
    }
    
    func testImageRetrieval() async throws {
        let service = WikidataService()
        let images = try await service.fetchWikimediaImages(entityId: "Q2090")
        XCTAssertGreaterThan(images?.count ?? 0, 0)
    }
}
```

### 4.3 UI Testing

#### Simulator Testing mit MCP:
```bash
# Build & Run Tests
mcp_XcodeBuildMCP_build_sim_name_proj(
    projectPath: "ios/SmartCityGuide.xcodeproj",
    scheme: "SmartCityGuide", 
    simulatorName: "iPhone 16"
)

# Test UI Components mit erweiterten POIs
mcp_XcodeBuildMCP_describe_ui(simulatorUuid: "...")
```

### 4.4 Performance Testing

#### Benchmark Tests:
```swift
// Tests/PerformanceTests.swift
class PerformanceTests: XCTestCase {
    
    func testGeoapifyPerformance() throws {
        measure {
            // Benchmark Geoapify vs HERE response times
        }
    }
    
    func testWikidataEnrichmentPerformance() throws {
        measure {
            // Benchmark Wikidata enrichment impact
        }
    }
}
```

---

## 📊 Implementation Checklist

### Phase 1: Geoapify Migration
- [ ] 1.1 Erstelle `GeoapifyAPIService.swift`
- [ ] 1.2 Implementiere Geoapify Response Models
- [ ] 1.3 Mappe PlaceCategory → Geoapify Categories
- [ ] 1.4 Implementiere POI Conversion (Geoapify → POI)
- [ ] 1.5 Migration von Error Handling
- [ ] 1.6 Security & Certificate Pinning Updates
- [ ] 1.7 Integration in RouteService
- [ ] 1.8 API Key Configuration (APIKeys.plist)
- [ ] 1.9 Testing & Validation
- [ ] 1.10 Build Verification mit MCP

### Phase 2: Wikidata Integration  
- [ ] 2.1 Erstelle `WikidataService.swift`
- [ ] 2.2 Implementiere Wikidata Response Models
- [ ] 2.3 Erstelle `EnrichedPOI` Model
- [ ] 2.4 Implementiere Entity Search & Matching
- [ ] 2.5 Implementiere Image Retrieval (Wikimedia)
- [ ] 2.6 Implementiere Description Enrichment
- [ ] 2.7 Erstelle `EnrichedPOIService` als Coordinator
- [ ] 2.8 UI Updates für erweiterte POI-Daten
- [ ] 2.9 Testing & Validation
- [ ] 2.10 Performance Optimization

### Phase 3: HERE API Removal
- [ ] 3.1 Lösche `HEREAPIService.swift`
- [ ] 3.2 Entferne HERE Extensions aus POI.swift
- [ ] 3.3 Entferne HERE Extensions aus PlaceCategory.swift
- [ ] 3.4 Update RouteService Dependencies
- [ ] 3.5 Update Certificate Pinning Configuration
- [ ] 3.6 Remove HERE API Key aus APIKeys.plist
- [ ] 3.7 Clean Build & Test
- [ ] 3.8 Code Review & Documentation Updates

### Testing & Validation
- [ ] 4.1 Unit Tests für Geoapify Service (ohne Distance-Constraints)
- [ ] 4.2 Unit Tests für Wikidata Service  
- [ ] 4.3 Integration Tests für kompletten Workflow (Distance-Filtering deaktiviert)
- [ ] 4.4 UI Tests mit MCP Simulator Control
- [ ] 4.5 Performance Tests & Benchmarks
- [ ] 4.6 Regression Tests (bestehende Features, UI bleibt unverändert)
- [ ] 4.7 Build Verification auf physischen Geräten
- [ ] 4.8 **MIGRATION-SPECIFIC**: Distance-Filtering Deaktivierung validieren
- [ ] 4.9 **MIGRATION-SPECIFIC**: RouteLength UI Option weiterhin sichtbar prüfen

### Documentation Updates
- [ ] 5.1 Update FAQ in HelpSupportView.swift
- [ ] 5.2 Update CLAUDE.md Context Documentation
- [ ] 5.3 Update .cursorrules API References
- [ ] 5.4 Update README.md
- [ ] 5.5 Create API Migration Notes

---

## 🔧 Configuration Requirements

### API Keys Needed:
1. **Geoapify API Key** → `APIKeys.plist`
   - Kostenlos: 3.000 requests/Tag
   - Registrierung: https://www.geoapify.com/
   
2. **Wikimedia/Wikidata** 
   - ✅ Keine API Keys nötig (Open Data)
   - Rate Limiting: Respektvolle Nutzung

### Certificate Pinning:
- `api.geoapify.com`
- `www.wikidata.org` (optional)
- `commons.wikimedia.org` (optional)

### Bundle ID & Permissions:
- ✅ Keine Änderungen nötig
- ✅ Bestehende Location Permissions ausreichend

---

## 🚀 Expected Benefits

### Bessere POI-Filterung:
- ✅ **Granularere Kategorien** durch Geoapify
- ✅ **Bessere Qualität** durch multiple Datenquellen
- ✅ **Mehr Flexibilität** bei der POI-Auswahl

### Erweiterte Daten:
- ✅ **Bilder** für visuell ansprechende POI-Darstellung
- ✅ **Detaillierte Beschreibungen** aus Wikidata
- ✅ **Metadaten** wie Baujahr, Architekturstil, etc.

### European Privacy Compliance:
- ✅ **DSGVO-konform** durch europäische Services
- ✅ **Open Data** durch Wikimedia Foundation
- ✅ **Transparenz** in der Datenherkunft

---

## ⚠️ Risks & Mitigation

### Technical Risks:
1. **API Rate Limits**
   - *Mitigation*: Intelligent Caching, Request Batching
2. **Wikidata Matching Accuracy**  
   - *Mitigation*: Fallback zu Basis-POI bei fehlenden Matches
3. **Performance Impact**
   - *Mitigation*: Parallele Requests, Background Processing

### Business Risks:
1. **API Costs bei Scale-up**
   - *Mitigation*: Geoapify Free Tier monitoring, Upgrade-Pfad
2. **Service Dependencies**
   - *Mitigation*: Graceful Degradation, Multiple Service Fallbacks

### Migration Risks:
1. **Breaking Changes**
   - *Mitigation*: Phased Migration, Feature Flags
2. **Data Quality Differences**
   - *Mitigation*: Extensive Testing, Quality Comparison

---

## ⚠️ POST-MIGRATION: Distance Filtering Reaktivierung

### Nach erfolgreicher API Migration:
🚨 **WICHTIG**: Nach Abschluss der Migration muss Distance-Filtering **wieder aktiviert** werden:

1. **RouteService.swift**: 
   - `routeLength.searchRadiusMeters` wieder verwenden
   - `maxTotalDistanceMeters` Validierung wieder einschalten

2. **POICacheService.swift**:
   - `routeLength` Parameter wieder nutzen für POI Selection
   - `getMaxDistanceForRouteLength()` wieder aktivieren

3. **Testing**: 
   - Vollständige Regression Tests mit Distance-Constraints
   - UI Testing: RouteLength-Auswahl soll wieder funktionieren

### Next Iteration (außerhalb dieser Migration):
- **Distance Options Refactoring**: Separates Ticket für Verbesserung der Distance-Logik
- **Performance Optimierung**: Distance Caching implementieren
- **UI/UX**: Distance Options überarbeiten basierend auf User Feedback

---

*Erstellt: Datum*  
*Version: 1.1*  
*Status: Planning Phase - Updated mit Distance Filtering Hinweisen*