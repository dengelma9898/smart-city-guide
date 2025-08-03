# 📍 POI Categories & Distribution Documentation

## 🎯 **Übersicht: POI-System Architektur**

Dieses Dokument zeigt alle wichtigen Code-Stellen, wo POIs geholt und Kategorien verteilt werden.

---

## 🚀 **1. POI-Liste Beschaffung (Haupteinstieg)**

### **📍 Einstiegspunkt: RouteBuilderView.swift**
```swift
// Zeile 85-120: loadPOIsAndGenerateRoute()
private func loadPOIsAndGenerateRoute() async {
    do {
        // Step 1: Load POIs from HERE API
        isLoadingPOIs = true
        
        // 🚀 USE DIRECT COORDINATES if available (eliminates geocoding!)
        if let coordinates = startingCoordinates {
            print("RouteBuilderView: 🎯 Using direct coordinates \(coordinates.latitude), \(coordinates.longitude) for '\(startingCity)' - NO GEOCODING!")
            
            discoveredPOIs = try await hereService.fetchPOIs(
                at: coordinates,
                cityName: startingCity,
                categories: PlaceCategory.essentialCategories  // ⭐ HIER: Kategorien definiert
            )
        } else {
            discoveredPOIs = try await hereService.fetchPOIs(
                for: startingCity,
                categories: PlaceCategory.essentialCategories  // ⭐ HIER: Kategorien definiert
            )
        }
        
        // Step 2: Generate route using discovered POIs
        await routeService.generateRoute(
            startingCity: startingCity,
            availablePOIs: discoveredPOIs  // ⭐ HIER: POIs an RouteService weitergeben
        )
    } catch {
        // Error handling...
    }
}
```

---

## 🏷️ **2. Kategorien-Definition**

### **📍 PlaceCategory.swift (Zeile 522-528)**
```swift
// Essential categories to avoid rate limiting - only 4 Level 3 categories
static let essentialCategories: [PlaceCategory] = [
    .attraction,        // Tourist Attraction
    .monument,          // Historical Monument  
    .castle,            // Castle
    .landmarkAttraction // Landmark-Attraction
]
```

### **📍 HERE API Category Mapping (Zeile 531-544)**
```swift
/// HERE Browse API Level 3 Category IDs (more precise than Discover API)
var hereBrowseCategoryID: String {
    switch self {
    case .attraction:
        return "300-3000-0000"  // Tourist Attraction
    case .monument:
        return "300-3100-0000"  // Historical Monument
    case .castle:
        return "300-3100-0023"  // Castle
    case .landmarkAttraction:
        return "300-3000-0023"  // Landmark-Attraction
    default:
        return "300-3000-0000"  // Default to Tourist Attraction
    }
}
```

---

## 🌐 **3. HERE API POI-Abruf**

### **📍 HEREAPIService.swift: fetchPOIs() (Zeile 58-70)**
```swift
/// NEW: Direct POI search with coordinates (eliminates geocoding entirely!)
func fetchPOIs(at coordinates: CLLocationCoordinate2D, cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories) async throws -> [POI] {
    print("HEREAPIService: 🚀 Direct POI search at \(coordinates.latitude), \(coordinates.longitude) for '\(cityName)' - NO GEOCODING!")
    
    // Check cache first
    if let cachedPOIs = await POICacheService.shared.getCachedPOIs(for: cityName) {
        print("HEREAPIService: Using cached POIs for '\(cityName)'")
        return cachedPOIs
    }
    
    let pois = try await searchPOIs(near: coordinates, categories: categories, cityName: cityName)  // ⭐ HIER: Kategorien an Search weitergeben
    await POICacheService.shared.cachePOIs(pois, for: cityName)
    return pois
}
```

### **📍 HERE Browse API Call (Zeile 206-212)**
```swift
// 🚀 HERE BROWSE API: Category-based search for precise POI filtering
let categoryIDs = categories.map { $0.hereBrowseCategoryID }  // ⭐ HIER: Kategorien zu IDs
let categoriesParam = categoryIDs.joined(separator: ",")

// HERE Browse API with Level 3 Category IDs for precise results:
// GET /browse?at=lat,lng&categories=300-3000-0000,300-3100-0000&limit=50&apiKey=key
let urlString = "\(baseURL)/browse?at=\(location.latitude),\(location.longitude)&categories=\(categoriesParam)&limit=50&apiKey=\(apiKey)"
```

---

## 🎯 **4. Kategorien-Erkennung & Zuordnung**

### **📍 detectCategory() Funktion (Zeile 275-293)**
```swift
/// Intelligently detects the category of a POI based on its name and properties
private func detectCategory(for item: HERESearchItem) -> PlaceCategory {
    let title = item.title.lowercased()
    let categoryIds = item.categories?.compactMap { $0.id } ?? []  // ⭐ HIER: HERE API Categories extrahieren
    
    // Check for museums first (most specific)
    if title.contains("museum") || title.contains("gallery") || 
       categoryIds.contains(where: { $0.contains("museum") || $0.contains("gallery") }) {
        return .museum
    }
    
    // Check for parks and gardens
    if title.contains("park") || title.contains("garden") || title.contains("garten") ||
       categoryIds.contains(where: { $0.contains("park") || $0.contains("garden") }) {
        return .park
    }
    
    // Default to attraction for everything else
    return .attraction  // ⭐ HIER: Fallback-Kategorie
}
```

### **📍 POI Conversion (Zeile 250-268)**
```swift
// Convert each HERE item to our POI model
let pois: [POI] = response.items.compactMap { item in
    guard let poi = POI(from: item, category: detectedCategory) else {  // ⭐ HIER: Category Assignment
        print("HEREAPIService: Failed to convert item: \(item.title)")
        return nil
    }
    return poi
}
```

---

## ⚖️ **5. POI-Verteilung & Auswahl**

### **📍 POICacheService.swift: selectBestPOIs() (Zeile 71-139)**
```swift
/// Intelligent POI selection based on category importance, distance, and data richness
func selectBestPOIs(from allPOIs: [POI], routeLength: RouteLength, startLocation: CLLocationCoordinate2D, maxPOIs: Int = 10) -> [POI] {
    
    // Step 1: Filter POIs within reasonable distance
    let maxDistance = getMaxDistanceForRouteLength(routeLength)
    let nearbyPOIs = allPOIs.filter { poi in
        let distance = startLocation.distance(to: poi.coordinate)
        return distance <= maxDistance
    }
    
    // Step 2: Score each POI based on multiple factors
    let scoredPOIs = nearbyPOIs.map { poi in
        let categoryScore = getCategoryScore(poi.category)  // ⭐ HIER: Category-basierte Bewertung
        let distanceScore = getDistanceScore(poi, from: startLocation, maxDistance: maxDistance)
        let dataScore = getDataRichnessScore(poi)
        
        let totalScore = categoryScore * 0.4 + distanceScore * 0.3 + dataScore * 0.3  // ⭐ HIER: Gewichtung
        
        return (poi: poi, score: totalScore)
    }
    
    // Step 3: Sort by score and ensure category diversity
    let sortedPOIs = scoredPOIs.sorted { $0.score > $1.score }
    let selectedPOIs = ensureCategoryDiversity(sortedPOIs.map { $0.poi }, maxPOIs: maxPOIs)  // ⭐ HIER: Diversity-Algorithmus
    
    return selectedPOIs
}
```

### **📍 Category Scoring (Zeile 167-188)**
```swift
private func getCategoryScore(_ category: PlaceCategory) -> Double {
    // Priority scoring for different categories
    switch category {
    case .attraction, .castle, .monument, .cathedral:
        return 1.0  // ⭐ HÖCHSTE Priorität
    case .museum, .gallery, .viewpoint:
        return 0.9
    case .memorial, .archaeologicalSite, .ruins:
        return 0.8
    case .park, .garden, .artsCenter:
        return 0.7
    case .townhall, .placeOfWorship:
        return 0.6
    case .artwork, .chapel, .monastery, .shrine:
        return 0.5
    case .waterfall, .spring, .lake:
        return 0.4
    case .nationalPark:
        return 0.9
    case .landmarkAttraction:
        return 1.0  // ⭐ HÖCHSTE Priorität
    }
}
```

### **📍 Category Diversity Algorithm (Zeile 201-226)**
```swift
private func ensureCategoryDiversity(_ pois: [POI], maxPOIs: Int) -> [POI] {
    var selectedPOIs: [POI] = []
    var categoryCounts: [PlaceCategory: Int] = [:]
    
    // Try to get at least one POI from each represented category
    let representedCategories = Set(pois.map { $0.category })
    let maxPerCategory = max(1, maxPOIs / representedCategories.count)  // ⭐ HIER: Gleichmäßige Verteilung
    
    for poi in pois {
        guard selectedPOIs.count < maxPOIs else { break }
        
        let currentCount = categoryCounts[poi.category] ?? 0
        if currentCount < maxPerCategory {  // ⭐ HIER: Category-Limit prüfen
            selectedPOIs.append(poi)
            categoryCounts[poi.category] = currentCount + 1
        }
    }
    
    // Fill remaining slots with best remaining POIs regardless of category
    for poi in pois {
        guard selectedPOIs.count < maxPOIs else { break }
        if !selectedPOIs.contains(where: { $0.id == poi.id }) {  // ⭐ HIER: Duplikate vermeiden
            selectedPOIs.append(poi)
        }
    }
    
    return selectedPOIs
}
```

---

## 🎯 **6. Route Generation Integration**

### **📍 RouteService.swift: generateRoute() (Zeile 35-60)**
```swift
func generateRoute(startingCity: String, availablePOIs: [POI], ...) async {
    // Use POIs directly - no fallback to old logic
    guard !availablePOIs.isEmpty else {
        throw RouteGenerationError.noPOIsAvailable  // ⭐ HIER: POI-Validierung
    }
    
    // Select and optimize POIs for route
    let selectedPOIs = try await findOptimalRouteWithPOIs(
        availablePOIs: availablePOIs,  // ⭐ HIER: Alle verfügbaren POIs
        routeLength: routeLength,
        startLocation: startingCoordinate
    )
}
```

### **📍 POI Selection & Ordering (Zeile 447-470)**
```swift
private func findOptimalRouteWithPOIs(availablePOIs: [POI], ...) async throws -> [RoutePoint] {
    // Step 1: Select best POIs using cache service
    let selectedPOIs = await POICacheService.shared.selectBestPOIs(  // ⭐ HIER: Smart Selection
        from: availablePOIs,
        routeLength: routeLength,
        startLocation: startLocation,
        maxPOIs: maxWaypoints
    )
    
    // Step 2: Convert POIs to RoutePoints with visit duration
    let poiRoutePoints = selectedPOIs.map { poi in
        RoutePoint(
            coordinate: poi.coordinate,
            name: poi.name,
            category: poi.category.rawValue,
            visitDuration: getEstimatedVisitDuration(for: poi.category),  // ⭐ HIER: Category-basierte Duration
            description: poi.description ?? "Interessanter Ort"
        )
    }
    
    return poiRoutePoints
}
```

---

## 📊 **7. UI Integration & Display**

### **📍 RouteBuilderView.swift: POI Summary (Zeile 200-220)**
```swift
// POI Categories Summary
if !discoveredPOIs.isEmpty {
    VStack(alignment: .leading, spacing: 8) {
        let categoryGroups = Dictionary(grouping: discoveredPOIs, by: { $0.category })  // ⭐ HIER: Grouping by Category
        
        ForEach(Array(categoryGroups.keys), id: \.self) { category in
            let count = categoryGroups[category]?.count ?? 0
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text("\(category.rawValue): \(count)")  // ⭐ HIER: Category Count Display
                    .font(.caption)
            }
        }
    }
}
```

---

## 🎯 **Zusammenfassung: Datenfluss**

```
1. RouteBuilderView ➜ fetchPOIs(categories: essentialCategories)
2. HEREAPIService ➜ Browse API Call mit Category IDs
3. detectCategory() ➜ HERE Response → PlaceCategory
4. POICacheService.selectBestPOIs() ➜ Smart Distribution
5. RouteService ➜ POIs → RoutePoints mit Category-Duration
6. UI ➜ Category-grouped Display
```

**🏷️ Kategorien werden an 4 Stellen verarbeitet:**
- **Definition**: PlaceCategory.essentialCategories
- **API Mapping**: hereBrowseCategoryID 
- **Detection**: detectCategory() für HERE Response
- **Distribution**: selectBestPOIs() mit Category Scoring & Diversity
