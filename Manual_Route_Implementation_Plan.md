# Manual Route Feature - Implementation Plan
**Smart City Guide - User-Driven Route Creation mit Tinder-Style POI Selection**

> **Wir sind der Glubb!** 🔴⚫️
> 
> Optimierte Schritt-für-Schritt Implementierung für AI-Assistant

---

## 📋 **OVERVIEW & FEATURE DESCRIPTION**

### **Feature Goal**
Ermögliche Benutzern, ihre eigene Route durch **manuelle POI-Auswahl** zu erstellen, anstatt automatisch generierte Routen zu nutzen. Die User haben volle Kontrolle über jeden Stopp ihrer Tour.

### **User Journey Flow**
```
1. Hauptkarte → "Los planen wir!" → RoutePlanningView
2. RoutePlanningView → Toggle auf "Route manuell erstellen"
3. Minimal Input: Start + Endpunkt (keine komplexen Parameter)
4. POI Discovery & Wikipedia Enrichment
5. Tinder-Style Card Stack → User wählt POIs durch Swipen
6. "Route erstellen" Button → TSP-Optimierung der gewählten POIs
7. RouteBuilderView mit finaler Route (identisch zum Auto-Modus)
8. Edit/Start Optionen verfügbar → Bei Close zurück zum Manual Planning
```

### **Current State Analysis**
- ✅ `RoutePlanningView.swift` - Haupteingabe für Route-Parameter
- ✅ `RouteBuilderView.swift` - Zeigt generierte Route mit Edit-Funktionen
- ✅ Tinder-Style Swipe Components (aus Route-Edit Feature)
- ✅ POI Discovery & Wikipedia Enrichment Pipeline
- ✅ TSP Route Optimization verfügbar

---

## 🗂️ **FILE STRUCTURE PLAN**

```
ios/SmartCityGuide/Views/RoutePlanning/
├── RoutePlanningView.swift (MODIFY - Add manual/auto toggle)
├── ManualRoutePlanningView.swift (NEW - Manual input interface)
├── POISelectionStackView.swift (NEW - Tinder stack for POI selection)
└── RouteBuilderView.swift (MODIFY - Handle manual route results)

ios/SmartCityGuide/Models/
├── ManualRouteModels.swift (NEW - Manual route specific models)
└── POISelectionModels.swift (NEW - POI selection state models)

ios/SmartCityGuide/Services/
├── ManualRouteService.swift (NEW - Manual route business logic)
└── RouteService.swift (EXTEND - Support manual waypoints)
```

---

## 🚀 **STEP-BY-STEP IMPLEMENTATION**

### **Phase 1: UI Toggle & Navigation Structure**

#### **Step 1.1: Modify RoutePlanningView for Mode Selection**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/RoutePlanningView.swift`

**Änderungen:**
```swift
// NEUE STATE VARIABLES:
@State private var planningMode: RoutePlanningMode = .automatic
@State private var showingManualPlanning = false

enum RoutePlanningMode: String, CaseIterable {
    case automatic = "Automatisch"
    case manual = "Manuell erstellen"
}

// NEUE UI SECTION (nach Starting Point, vor Parameters):
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Image(systemName: "slider.horizontal.3")
            .foregroundColor(.blue)
            .font(.system(size: 20))
        
        Text("Wie möchtest du planen?")
            .font(.headline)
            .fontWeight(.semibold)
    }
    
    HStack(spacing: 8) {
        ForEach(RoutePlanningMode.allCases, id: \.self) { mode in
            Button(action: {
                planningMode = mode
            }) {
                Text(mode.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(planningMode == mode ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(planningMode == mode ? .blue : Color(.systemGray6))
                    )
            }
        }
    }
}

// CONDITIONAL PARAMETER DISPLAY:
if planningMode == .automatic {
    // Zeige alle bisherigen Parameter (MaxStops, WalkingTime, etc.)
} else {
    // Nur Endpoint Section für Manual Mode
}

// UPDATED BUTTON ACTION:
Button(action: {
    if planningMode == .automatic {
        showingRouteBuilder = true
    } else {
        showingManualPlanning = true
    }
}) {
    Text(planningMode == .automatic ? "Los geht's!" : "POIs entdecken!")
    // ...
}

// NEW SHEET PRESENTATION:
.sheet(isPresented: $showingManualPlanning) {
    ManualRoutePlanningView(
        startingCity: startingCity,
        startingCoordinates: startingCoordinates,
        usingCurrentLocation: usingCurrentLocation,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        customEndpointCoordinates: customEndpointCoordinates,
        onRouteGenerated: onRouteGenerated
    )
}
```

**UI Design Details:**
- **Toggle Position:** Nach "Wo startest du?" Sektion, vor komplexen Parametern
- **Visual Style:** Identisch zu Endpoint Option Buttons (blauer Hintergrund bei Selection)
- **Parameter Hiding:** Im Manual Mode nur Start/End sichtbar, keine MaxStops/WalkingTime
- **Button Text:** "POIs entdecken!" statt "Los geht's!" für Manual Mode

#### **Step 1.2: Create Manual Route Data Models**
**File:** `ios/SmartCityGuide/Models/ManualRouteModels.swift`

```swift
import Foundation
import CoreLocation

/// Configuration for manual route planning
struct ManualRouteConfig {
    let startingCity: String
    let startingCoordinates: CLLocationCoordinate2D?
    let usingCurrentLocation: Bool
    let endpointOption: EndpointOption
    let customEndpoint: String
    let customEndpointCoordinates: CLLocationCoordinate2D?
}

/// User's manual POI selection state
struct ManualPOISelection {
    var selectedPOIs: [POI] = []
    var rejectedPOIs: Set<String> = [] // POI IDs
    var currentCardIndex: Int = 0
    
    var hasSelections: Bool {
        return !selectedPOIs.isEmpty
    }
    
    var canGenerateRoute: Bool {
        return selectedPOIs.count >= 1 // Mindestens 1 POI für Route
    }
}

/// Manual route generation request
struct ManualRouteRequest {
    let config: ManualRouteConfig
    let selectedPOIs: [POI]
    let allDiscoveredPOIs: [POI] // Für mögliche Enrichment-Referenzen
}

/// Result of manual route generation
struct ManualRouteResult {
    let generatedRoute: GeneratedRoute
    let optimizationMetrics: RouteOptimizationMetrics?
    let processingTime: TimeInterval
}

/// Metrics about the TSP optimization for manual routes
struct RouteOptimizationMetrics {
    let originalDistance: Double // Air distance of selected order
    let optimizedDistance: Double // TSP optimized distance
    let improvementPercentage: Double
    let optimizationTime: TimeInterval
}
```

---

### **Phase 2: Manual Planning Interface**

#### **Step 2.1: Create Manual Route Planning View**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/ManualRoutePlanningView.swift`

**Komponenten-Design:**
```swift
struct ManualRoutePlanningView: View {
    // CONFIG
    let config: ManualRouteConfig
    let onRouteGenerated: (GeneratedRoute) -> Void
    
    // SERVICES
    @StateObject private var manualRouteService = ManualRouteService()
    @StateObject private var geoapifyService = GeoapifyAPIService.shared
    @StateObject private var wikipediaService = WikipediaService.shared
    
    // STATE
    @State private var discoveredPOIs: [POI] = []
    @State private var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
    @State private var poiSelection = ManualPOISelection()
    @State private var isLoadingPOIs = false
    @State private var isEnrichingPOIs = false
    @State private var showingPOISelection = false
    @State private var enrichmentProgress = 0.0
    
    var body: some View {
        NavigationView {
            // PHASE PROGRESSION:
            // 1. Loading POIs
            // 2. Enriching POIs  
            // 3. Ready for Selection
            // 4. POI Selection Stack
        }
    }
}
```

**Screen Phases:**
1. **Loading Phase:** "Entdecke POIs in [Stadt]..." mit ProgressView
2. **Enriching Phase:** "Lade Wikipedia-Infos..." mit Progress Bar
3. **Ready Phase:** Übersicht der gefundenen POIs + "Auswahl starten" Button
4. **Selection Phase:** Fullscreen POI Stack View

**UI Layout - Ready Phase:**
```swift
VStack(spacing: 20) {
    // Header
    VStack(spacing: 8) {
        Text("POIs gefunden!")
            .font(.title2)
            .fontWeight(.semibold)
        
        Text("\(discoveredPOIs.count) interessante Orte in \(config.startingCity) entdeckt")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    // POI Categories Overview
    POICategoriesOverview(pois: discoveredPOIs)
    
    // Selection Status
    if poiSelection.hasSelections {
        SelectedPOIsPreview(selectedPOIs: poiSelection.selectedPOIs)
    }
    
    // Action Buttons
    VStack(spacing: 12) {
        Button("Auswahl starten") {
            showingPOISelection = true
        }
        .buttonStyle(.borderedProminent)
        
        if poiSelection.canGenerateRoute {
            Button("Route erstellen (\(poiSelection.selectedPOIs.count) POIs)") {
                Task {
                    await generateManualRoute()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
```

#### **Step 2.2: Create POI Selection Stack**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/POISelectionStackView.swift`

**Reuse Strategy:**
- **Basis:** Existierende `SwipeCardStackView` und `SpotSwipeCardView`
- **Anpassung:** Neue Actions für `accept/reject` statt `replace`
- **State Management:** Trackinge der gesammelten POIs

```swift
struct POISelectionStackView: View {
    @Binding var availablePOIs: [POI]
    @Binding var selection: ManualPOISelection
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    let onSelectionComplete: () -> Void
    
    @State private var swipeCards: [SwipeCard] = []
    @State private var currentCardIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                if currentCardIndex < swipeCards.count {
                    // Active Card Stack
                    cardStackView
                    
                    // Selection Status Overlay
                    selectionStatusOverlay
                } else {
                    // All cards completed
                    completionView
                }
            }
            .navigationTitle("POI Auswahl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") {
                        onSelectionComplete()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    selectionCounter
                }
            }
        }
    }
    
    private var selectionCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("\(selection.selectedPOIs.count)")
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}
```

**Card Actions:**
```swift
enum POISelectionAction {
    case select(POI)    // Left swipe - add to route
    case reject(POI)    // Right swipe - skip
    case undo           // Optional: undo last action
}

private func handleCardAction(_ action: POISelectionAction) {
    switch action {
    case .select(let poi):
        selection.selectedPOIs.append(poi)
        advanceToNextCard()
        
    case .reject(let poi):
        selection.rejectedPOIs.insert(poi.id)
        advanceToNextCard()
        
    case .undo:
        // Implement undo logic
        break
    }
}
```

---

### **Phase 3: Manual Route Service & Generation**

#### **Step 3.1: Create Manual Route Service**
**File:** `ios/SmartCityGuide/Services/ManualRouteService.swift`

```swift
@MainActor
class ManualRouteService: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedRoute: GeneratedRoute?
    @Published var errorMessage: String?
    @Published var optimizationMetrics: RouteOptimizationMetrics?
    
    private let routeService = RouteService()
    
    /// Generate optimized route from manually selected POIs
    func generateRoute(from request: ManualRouteRequest) async {
        isGenerating = true
        errorMessage = nil
        
        let startTime = Date()
        
        do {
            // 1. Create waypoints from selection
            let waypoints = try createWaypoints(from: request)
            
            // 2. Apply TSP optimization to selected POIs
            let optimizedWaypoints = try await optimizeWaypointOrder(waypoints)
            
            // 3. Calculate walking routes
            let routes = try await calculateWalkingRoutes(for: optimizedWaypoints)
            
            // 4. Calculate metrics
            let metrics = calculateMetrics(
                originalWaypoints: waypoints,
                optimizedWaypoints: optimizedWaypoints,
                routes: routes,
                processingTime: Date().timeIntervalSince(startTime)
            )
            
            // 5. Create final route
            let finalRoute = GeneratedRoute(
                waypoints: optimizedWaypoints,
                routes: routes,
                totalDistance: metrics.totalDistance,
                totalTravelTime: metrics.totalTravelTime,
                totalVisitTime: metrics.totalVisitTime,
                totalExperienceTime: metrics.totalExperienceTime
            )
            
            self.generatedRoute = finalRoute
            self.optimizationMetrics = metrics.optimizationMetrics
            
        } catch {
            self.errorMessage = "Route-Generierung fehlgeschlagen: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    /// TSP optimization specifically for manual route POIs
    private func optimizeWaypointOrder(_ waypoints: [RoutePoint]) async throws -> [RoutePoint] {
        // Reuse existing TSP logic from RouteService
        // Input: Start + Selected POIs + End
        // Output: Start + Optimized POI Order + End
        
        guard waypoints.count >= 3 else { return waypoints } // Start + ≥1 POI + End
        
        let startPoint = waypoints.first!
        let endPoint = waypoints.last!
        let poiWaypoints = Array(waypoints.dropFirst().dropLast())
        
        // Apply TSP optimization to POI waypoints only
        let optimizedPOIs = try await routeService.optimizePOIOrder(
            pois: poiWaypoints,
            startPoint: startPoint.coordinate,
            endPoint: endPoint.coordinate
        )
        
        return [startPoint] + optimizedPOIs + [endPoint]
    }
}
```

**TSP Integration:**
- **Eingabe:** Start + User-Selected POIs + End
- **Optimierung:** Nur die POI-Reihenfolge (Start/End fix)
- **Metrik:** Vergleich original selection vs. optimized order

#### **Step 3.2: Extend RouteService for Manual Routes**
**File:** `ios/SmartCityGuide/Services/RouteService.swift`

```swift
// NEUE METHODE HINZUFÜGEN:

/// Generate route from manually selected POIs (TSP optimized)
func generateManualRoute(
    from selectedPOIs: [POI],
    startLocation: CLLocationCoordinate2D,
    endpointOption: EndpointOption,
    customEndpoint: String = ""
) async throws -> GeneratedRoute {
    
    isGenerating = true
    errorMessage = nil
    
    do {
        // 1. Create start waypoint
        let startWaypoint = RoutePoint(
            name: "Start",
            coordinate: startLocation,
            address: "Startpunkt",
            category: .attraction
        )
        
        // 2. Convert POIs to waypoints
        let poiWaypoints = selectedPOIs.map { RoutePoint(from: $0) }
        
        // 3. Create end waypoint based on option
        let endWaypoint = try await createEndWaypoint(
            from: endpointOption,
            customEndpoint: customEndpoint,
            startLocation: startLocation
        )
        
        // 4. Combine and optimize
        let allWaypoints = [startWaypoint] + poiWaypoints + [endWaypoint]
        let optimizedWaypoints = try await optimizeWaypointOrder(allWaypoints)
        
        // 5. Calculate routes and metrics
        let routes = try await calculateWalkingDirections(for: optimizedWaypoints)
        let metrics = calculateRouteMetrics(routes: routes, waypoints: optimizedWaypoints)
        
        let finalRoute = GeneratedRoute(
            waypoints: optimizedWaypoints,
            routes: routes,
            totalDistance: metrics.totalDistance,
            totalTravelTime: metrics.totalTravelTime,
            totalVisitTime: metrics.totalVisitTime,
            totalExperienceTime: metrics.totalExperienceTime
        )
        
        // 6. Save to history
        historyManager?.saveRoute(finalRoute, type: .manual)
        
        generatedRoute = finalRoute
        isGenerating = false
        
        return finalRoute
        
    } catch {
        isGenerating = false
        errorMessage = error.localizedDescription
        throw error
    }
}
```

---

### **Phase 4: Integration & Navigation Flow**

#### **Step 4.1: Update RouteBuilderView for Manual Routes**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/RouteBuilderView.swift`

**Änderungen:**
```swift
// NEUE EIGENSCHAFTEN HINZUFÜGEN:
let routeSource: RouteSource // Unterscheidung Auto vs Manual
let manualRouteConfig: ManualRouteConfig? // Nur für Manual Routes

enum RouteSource {
    case automatic
    case manual(ManualRouteConfig)
}

// NEUE INITIALIZER:
init(manualRoute: GeneratedRoute, config: ManualRouteConfig, onRouteGenerated: @escaping (GeneratedRoute) -> Void) {
    self.routeSource = .manual(config)
    self.manualRouteConfig = config
    // ... set all properties from route
}

// NAVIGATION HANDLING:
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Fertig") {
            switch routeSource {
            case .automatic:
                // Normale Navigation zurück
                dismiss()
            case .manual(let config):
                // Navigation zurück zur Manual Planning View
                dismiss()
            }
        }
    }
}

// ROUTE EDIT UNTERSTÜTZUNG:
// Manual Routes können genauso editiert werden wie Auto Routes
// Alle Edit-Funktionen bleiben verfügbar
```

**Display Unterschiede:**
- **Header Text:** "Deine manuelle Route!" statt "Deine Tour entsteht!"
- **Optimization Badge:** "✨ TSP-optimiert" für Manual Routes
- **Source Indicator:** Kleine Badge "Manuell erstellt" vs "Automatisch generiert"

#### **Step 4.2: Complete Navigation Flow**
**Navigation Chain:**
```
MainMap 
  → "Los planen wir!" 
  → RoutePlanningView 
  → Toggle "Manuell erstellen"
  → ManualRoutePlanningView [Sheet]
    → POI Discovery + Enrichment
    → POISelectionStackView [Fullscreen]
    → Route Generation
    → RouteBuilderView [Navigation]
      → Edit/Start Options
      → Close → zurück zu ManualRoutePlanningView
    → Close → zurück zu RoutePlanningView
```

**State Management:**
```swift
// In ManualRoutePlanningView:
@State private var showingRouteBuilder = false
@State private var finalRoute: GeneratedRoute?

.fullScreenCover(isPresented: $showingRouteBuilder) {
    if let route = finalRoute {
        RouteBuilderView(
            manualRoute: route,
            config: config,
            onRouteGenerated: onRouteGenerated
        )
    }
}
```

---

### **Phase 5: Enhanced Features & Polish**

#### **Step 5.1: Selection Statistics & Insights**
```swift
// In POISelectionStackView:
struct SelectionInsights: View {
    let selectedPOIs: [POI]
    
    var categoryDistribution: [PlaceCategory: Int] {
        Dictionary(grouping: selectedPOIs, by: \.category)
            .mapValues { $0.count }
    }
    
    var estimatedWalkingTime: String {
        // Rough calculation based on POI count
        let baseTime = selectedPOIs.count * 30 // 30 min per POI
        let walkingTime = selectedPOIs.count * 10 // 10 min walking between POIs
        return "\(baseTime + walkingTime) Min"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deine Auswahl:")
                .font(.headline)
            
            // Category breakdown
            ForEach(PlaceCategory.allCases, id: \.self) { category in
                if let count = categoryDistribution[category], count > 0 {
                    HStack {
                        Text(category.icon + " " + category.rawValue)
                        Spacer()
                        Text("\(count)")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            HStack {
                Text("Geschätzte Zeit:")
                Spacer()
                Text(estimatedWalkingTime)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

#### **Step 5.2: Undo/Redo Functionality**
```swift
// In ManualPOISelection:
struct SelectionHistory {
    private var actions: [POISelectionAction] = []
    private var currentIndex = -1
    
    mutating func addAction(_ action: POISelectionAction) {
        // Remove any actions after current index (for redo)
        actions = Array(actions.prefix(currentIndex + 1))
        actions.append(action)
        currentIndex = actions.count - 1
    }
    
    func canUndo: Bool {
        return currentIndex >= 0
    }
    
    func canRedo: Bool {
        return currentIndex < actions.count - 1
    }
    
    mutating func undo() -> POISelectionAction? {
        guard canUndo else { return nil }
        let action = actions[currentIndex]
        currentIndex -= 1
        return action
    }
}
```

#### **Step 5.3: POI Filtering & Search**
```swift
// Optional: Advanced POI filtering in ManualRoutePlanningView
struct POIFilterOptions {
    var categories: Set<PlaceCategory> = Set(PlaceCategory.allCases)
    var hasWikipediaData: Bool = false
    var minimumRating: Double? = nil
    var searchText: String = ""
}

private var filteredPOIs: [POI] {
    discoveredPOIs.filter { poi in
        // Category filter
        guard filterOptions.categories.contains(poi.category) else { return false }
        
        // Wikipedia filter
        if filterOptions.hasWikipediaData {
            guard enrichedPOIs[poi.id]?.wikipediaData != nil else { return false }
        }
        
        // Search text filter
        if !filterOptions.searchText.isEmpty {
            let searchTerm = filterOptions.searchText.lowercased()
            guard poi.name.lowercased().contains(searchTerm) else { return false }
        }
        
        return true
    }
}
```

---

### **Phase 6: FAQ Documentation Update (MANDATORY)**

#### **Step 6.1: Update HelpSupportView.swift**
**File:** `ios/SmartCityGuide/Views/Profile/HelpSupportView.swift`

**🚨 MANDATORY RULE:** FAQ-Update für Manual Route Feature!

**Neue FAQ-Einträge:**
```swift
FAQ(
    question: "Wie erstelle ich eine manuelle Route?",
    answer: """
    Du kannst deine eigene Route zusammenstellen:
    
    **So funktioniert's:**
    1. **Modus wählen:** In der Routenplanung auf "Manuell erstellen" umschalten
    2. **Start/Ziel eingeben:** Nur Startpunkt und Endpunkt sind nötig
    3. **POIs entdecken:** App findet alle interessanten Orte in der Stadt
    4. **Auswahl treffen:** Swipe durch die POI-Karten (links = nehmen, rechts = überspringen)
    5. **Route optimieren:** App berechnet automatisch die beste Reihenfolge deiner Auswahl
    
    **Vorteile:**
    • Volle Kontrolle über jeden Stopp
    • Nur Orte die dich wirklich interessieren
    • Trotzdem optimierte Laufroute dank TSP-Algorithmus
    """
),

FAQ(
    question: "Was ist der Unterschied zwischen automatischer und manueller Route?",
    answer: """
    **Automatische Route:**
    • App wählt die besten POIs basierend auf deinen Parametern
    • Schneller und einfacher
    • Berücksichtigt Gehzeit, Anzahl Stopps, Mindestabstand
    • Ideal für Entdeckungstouren
    
    **Manuelle Route:**
    • Du wählst jeden Stopp selbst durch Swipen
    • Maximale Kontrolle über deine Tour
    • Nur Start- und Endpunkt als Parameter nötig
    • App optimiert trotzdem die Reihenfolge für kürzeste Route
    • Perfekt wenn du schon weißt was dich interessiert
    
    **Beide Modi** bieten dieselben Features: Route bearbeiten, Navigation starten, Wikipedia-Infos, etc.
    """
),

FAQ(
    question: "Wie viele POIs kann ich in einer manuellen Route auswählen?",
    answer: """
    **Empfohlene Anzahl:**
    • 3-8 POIs für optimale Erfahrung
    • Minimum: 1 POI (sonst nur Start → Ziel)
    • Maximum: Technisch unbegrenzt, aber nicht empfohlen
    
    **Planungshilfe:**
    • Pro POI: 30-60 Minuten Aufenthalt
    • Dazu kommt Laufzeit zwischen den Orten
    • Die App zeigt dir eine Zeitschätzung während der Auswahl
    
    **TSP-Optimierung:**
    Egal in welcher Reihenfolge du die POIs auswählst - die App berechnet automatisch die kürzeste Route zwischen allen Punkten!
    """
)
```

---

## 🧪 **TESTING & VALIDATION STRATEGY**

### **User Flow Testing**
1. **Mode Toggle:** RoutePlanningView → Toggle zwischen Auto/Manual
2. **Minimal Input:** Nur Start/End eingeben → POI Discovery
3. **POI Selection:** Swipe Interface → Sammeln von 3-5 POIs
4. **Route Generation:** TSP Optimization → Verification der Reihenfolge
5. **RouteBuilder Integration:** Edit/Start Funktionen testen
6. **Navigation Flow:** Zurück-Navigation durch alle Screens

### **Edge Cases**
- Keine POIs ausgewählt → Disabled "Route erstellen" Button
- Nur 1 POI ausgewählt → Route Start → POI → End
- Alle POIs abgelehnt → Empty State mit Retry Option
- Network Error während POI Loading → Error Handling

### **Performance Testing**
- POI Discovery mit 200+ POIs → Smooth Rendering
- Wikipedia Enrichment → Progress Indicator
- TSP Optimization für 10+ POIs → Max 3 Sekunden

---

## 📱 **UI/UX SPECIFICATIONS**

### **Design Consistency**
- **Toggle Buttons:** Identisch zu Endpoint Option Style
- **Card Stack:** Reuse der Route-Edit Swipe Components
- **Loading States:** Konsistent mit bestehendem RouteBuilder
- **Navigation:** Standard iOS Navigation Patterns

### **German UI Text**
```swift
"Route manuell erstellen"        // Mode toggle
"POIs entdecken!"               // Action button
"Auswahl starten"               // Begin POI selection
"Route erstellen (X POIs)"      // Generate route
"Deine manuelle Route!"         // RouteBuilder title
"✨ TSP-optimiert"              // Optimization badge
```

---

## 💡 **SUCCESS CRITERIA**

### **Functional Requirements**
✅ Toggle zwischen Auto/Manual Mode in RoutePlanningView
✅ Minimal Input Interface (nur Start/End)
✅ POI Discovery & Wikipedia Enrichment
✅ Tinder-Style POI Selection
✅ TSP Route Optimization der User-Auswahl
✅ Integration mit bestehendem RouteBuilderView
✅ Vollständige Navigation Chain

### **UX Requirements**
✅ Intuitive Mode-Auswahl
✅ Klare Progress Indication (Loading → Enriching → Ready → Selection)
✅ Real-time Selection Counter
✅ Smooth Swipe Interactions
✅ Optimization Feedback (Metrics)

### **Technical Requirements**
✅ Reuse bestehender Components (SwipeCardStack, RouteBuilder)
✅ Service Layer Separation (ManualRouteService)
✅ Proper State Management zwischen Views
✅ Error Handling & Empty States
✅ Performance: POI Loading < 5s, Route Generation < 3s

### **Documentation Requirements (MANDATORY)**
✅ FAQ Update für Manual Route Feature
✅ Unterschied Auto vs Manual erklärt
✅ POI Selection Anleitung dokumentiert
✅ TSP Optimization Benefits erwähnt

---

**🎯 Optimiert für AI-Assistant Implementation**
- Klare Schritt-für-Schritt Struktur mit Priorities
- Copy-paste-ready Code-Snippets
- Reuse bestehender Components wo möglich
- Detaillierte Navigation Flow Specification
- Comprehensive Testing Scenarios

**Wir sind der Glubb!** 🔴⚫️ Ready für Manual Route Implementation! 🚀