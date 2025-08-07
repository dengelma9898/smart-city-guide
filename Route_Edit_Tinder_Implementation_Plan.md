# Route Edit Feature - Tinder-Style Implementation Plan
**Smart City Guide - Route Spot Editing mit Swipe Interface**

> **Wir sind der Glubb!** 🔵⚪️
> 
> Detaillierte Schritt-für-Schritt Implementierung für AI-Assistant optimiert

---

## 📋 **OVERVIEW & ARCHITECTURE**

### **Current State Analysis**
- ✅ `RouteBuilderView.swift` zeigt generierte Route mit Waypoints
- ✅ `discoveredPOIs` Cache mit allen gefundenen Spots verfügbar
- ✅ `enrichedPOIs` Dictionary mit Wikipedia-Daten
- ✅ Route-Neuberechnung via `RouteService` möglich

### **Feature Goal**
**Tinder-ähnliches Swipe-Interface** zum Ersetzen einzelner Route-Spots mit alternativen POIs aus dem Cache.

**References:**
- [Manual Route Changes Best Practices](https://www.myrouteonline.com/user-guides/manually-change-route-plan-order)
- Modern Swipe UI Patterns (Tinder, Bumble, etc.)

---

## 🗂️ **FILE STRUCTURE PLAN**

```
ios/SmartCityGuide/Views/RoutePlanning/
├── RouteBuilderView.swift (existing - MODIFY)
├── RouteEditView.swift (NEW - Main edit interface)
├── SpotSwipeCardView.swift (NEW - Individual swipe card)
└── SwipeCardStackView.swift (NEW - Card stack container)

ios/SmartCityGuide/Models/
├── RouteEditModels.swift (NEW - Edit-specific data models)
└── SwipeCardModels.swift (NEW - Card interaction models)

ios/SmartCityGuide/Services/
├── RouteEditService.swift (NEW - Edit logic service)
└── RouteService.swift (existing - EXTEND)
```

---

## 🚀 **STEP-BY-STEP IMPLEMENTATION**

### **Phase 1: Data Models & Architecture**

#### **Step 1.1: Create Route Edit Models**
**File:** `ios/SmartCityGuide/Models/RouteEditModels.swift`

```swift
// IMPLEMENTATION DETAILS:
struct EditableRouteSpot {
    let originalWaypoint: RoutePoint
    let waypointIndex: Int // Position in route
    let alternativePOIs: [POI] // Cached alternatives
    let currentPOI: POI? // Currently selected POI
}

struct SpotEditRequest {
    let targetSpotIndex: Int
    let currentRoute: GeneratedRoute
    let availableAlternatives: [POI]
    let maxDistanceFromOriginal: Double // 500m radius
}

enum SwipeAction {
    case accept(POI)
    case reject(POI)
    case skip
}
```

**Optimierung für AI:**
- Klare Datenstrukturen für Route-Editing
- Type-safe Swipe Actions
- Distance-basierte POI-Filterung

#### **Step 1.2: Create Swipe Card Models**
**File:** `ios/SmartCityGuide/Models/SwipeCardModels.swift`

```swift
// IMPLEMENTATION DETAILS:
struct SwipeCard: Identifiable {
    let id = UUID()
    let poi: POI
    let enrichedData: WikipediaEnrichedPOI?
    let distanceFromOriginal: Double
    let category: PlaceCategory
    var offset: CGSize = .zero
    var isAnimating: Bool = false
}

enum SwipeDirection {
    case left  // Accept
    case right // Reject
    case none
}

struct SwipeGesture {
    let direction: SwipeDirection
    let velocity: CGFloat
    let translation: CGSize
}
```

---

### **Phase 2: Core Swipe UI Components**

#### **Step 2.1: Create Individual Swipe Card**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/SpotSwipeCardView.swift`

**Komponenten-Design:**
```swift
struct SpotSwipeCardView: View {
    @Binding var card: SwipeCard
    let onSwipe: (SwipeAction) -> Void
    
    // VISUAL COMPONENTS:
    // - Hero Image (Wikipedia/POI image)
    // - Name & Category Badge
    // - Description (Wikipedia extract)
    // - Distance Indicator
    // - Swipe Action Indicators (Accept/Reject)
}
```

**UI Requirements:**
- **Hero Image:** 280x180pt, rounded corners, shadow
- **Content Card:** White background, 16pt padding
- **Distance Badge:** Green badge with walking time
- **Swipe Indicators:** Left (green checkmark), Right (red X)
- **Gesture Feedback:** Scale + rotation on drag

**Animation Details:**
```swift
// GESTURE IMPLEMENTATION:
.offset(card.offset)
.rotationEffect(.degrees(card.offset.width / 10))
.scaleEffect(card.isAnimating ? 0.95 : 1.0)
.gesture(DragGesture()
    .onChanged { value in
        card.offset = value.translation
        // Real-time swipe indicators
    }
    .onEnded { value in
        handleSwipeEnd(value)
    }
)
```

#### **Step 2.2: Create Card Stack Container**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/SwipeCardStackView.swift`

**Stack Behavior:**
```swift
struct SwipeCardStackView: View {
    @State private var cards: [SwipeCard]
    let onCardAction: (SwipeAction) -> Void
    
    // STACK FEATURES:
    // - ZStack with 3 visible cards max
    // - Background cards slightly scaled/offset
    // - Smooth card transitions
    // - Empty state when no more cards
}
```

**Card Stack Logic:**
- **Visible Cards:** Max 3 cards (top + 2 background)
- **Background Offset:** 8pt vertical, 0.95 scale
- **Transition:** 0.3s spring animation
- **Card Removal:** Fade out + scale down

---

### **Phase 3: Main Edit Interface**

#### **Step 3.1: Create Route Edit View**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/RouteEditView.swift`

**Interface Structure:**
```swift
struct RouteEditView: View {
    let originalRoute: GeneratedRoute
    let editableSpot: EditableRouteSpot
    let onSpotChanged: (POI) -> Void
    let onCancel: () -> Void
    
    @StateObject private var editService = RouteEditService()
    @State private var availableCards: [SwipeCard] = []
    @State private var showingIntroAnimation = true
}
```

**Screen Layout:**
1. **Header:** "Finde besseren Spot" + Cancel Button
2. **Original Spot Info:** Current waypoint details
3. **Swipe Area:** Card stack (60% screen height)
4. **Action Buttons:** Accept/Reject buttons (accessibility)
5. **Progress:** "X von Y Alternativen"

**Intro Animation:**
```swift
// INITIAL CARD ANIMATION:
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        // Slight left-right wiggle to show swipeability
        withAnimation(.easeInOut(duration: 0.8)) {
            topCard.offset.width = 30
        }
        withAnimation(.easeInOut(duration: 0.8).delay(0.4)) {
            topCard.offset.width = -30
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.8)) {
            topCard.offset.width = 0
            showingIntroAnimation = false
        }
    }
}
```

#### **Step 3.2: Integrate Edit Service Logic**
**File:** `ios/SmartCityGuide/Services/RouteEditService.swift`

**Service Responsibilities:**
```swift
@MainActor
class RouteEditService: ObservableObject {
    @Published var isGeneratingNewRoute = false
    @Published var newRoute: GeneratedRoute?
    @Published var errorMessage: String?
    
    // CORE METHODS:
    func findAlternativePOIs(for waypoint: RoutePoint, from cache: [POI]) -> [POI]
    func calculateDistanceFromOriginal(poi: POI, original: RoutePoint) -> Double
    func generateUpdatedRoute(replacing index: Int, with newPOI: POI, in route: GeneratedRoute) async
    func createSwipeCards(from pois: [POI], enrichedData: [String: WikipediaEnrichedPOI]) -> [SwipeCard]
}
```

**POI Selection Algorithm:**
```swift
// ALTERNATIVE POI FILTERING:
func findAlternativePOIs(for waypoint: RoutePoint, from cache: [POI]) -> [POI] {
    return cache.filter { poi in
        // 1. Same category preferred
        let categoryMatch = poi.category == waypoint.category
        
        // 2. Distance constraint (500m radius)
        let distance = poi.coordinate.distance(from: waypoint.coordinate)
        let withinRadius = distance <= 500
        
        // 3. Not already in route
        let notInRoute = !isAlreadyInRoute(poi)
        
        // 4. Has quality data (Wikipedia preferred)
        let hasQualityData = enrichedPOIs[poi.id]?.wikipediaData != nil
        
        return withinRadius && notInRoute && (categoryMatch || hasQualityData)
    }
    .sorted { poi1, poi2 in
        // Sort by: category match > quality > distance
        let distance1 = poi1.coordinate.distance(from: waypoint.coordinate)
        let distance2 = poi2.coordinate.distance(from: waypoint.coordinate)
        return distance1 < distance2
    }
    .prefix(20) // Max 20 alternatives
}
```

---

### **Phase 4: RouteBuilderView Integration**

#### **Step 4.1: Add Edit Functionality to RouteBuilderView**
**File:** `ios/SmartCityGuide/Views/RoutePlanning/RouteBuilderView.swift`

**Modification Points:**
```swift
// ADD EDIT BUTTON TO WAYPOINT CARDS:
HStack(spacing: 12) {
    // ... existing waypoint UI ...
    
    Spacer()
    
    // EDIT BUTTON (only for intermediate waypoints)
    if index > 0 && index < route.waypoints.count - 1 {
        Button(action: {
            editWaypoint(at: index)
        }) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Edit Integration:**
```swift
// NEW STATE VARIABLES:
@State private var showingEditView = false
@State private var editingWaypointIndex: Int?
@State private var editableSpot: EditableRouteSpot?

// EDIT METHODS:
private func editWaypoint(at index: Int) {
    guard let route = routeService.generatedRoute,
          index < route.waypoints.count else { return }
    
    let waypoint = route.waypoints[index]
    let alternatives = findAlternativePOIs(for: waypoint)
    
    editableSpot = EditableRouteSpot(
        originalWaypoint: waypoint,
        waypointIndex: index,
        alternativePOIs: alternatives,
        currentPOI: findOriginalPOI(for: waypoint)
    )
    
    showingEditView = true
}

private func handleSpotChange(_ newPOI: POI) {
    guard let editableSpot = editableSpot,
          let originalRoute = routeService.generatedRoute else { return }
    
    // Generate new route with replacement
    Task {
        await generateUpdatedRoute(
            replacing: editableSpot.waypointIndex,
            with: newPOI,
            in: originalRoute
        )
    }
    
    showingEditView = false
    self.editableSpot = nil
}
```

**Sheet Presentation:**
```swift
.sheet(isPresented: $showingEditView) {
    if let editableSpot = editableSpot {
        RouteEditView(
            originalRoute: routeService.generatedRoute!,
            editableSpot: editableSpot,
            onSpotChanged: handleSpotChange,
            onCancel: {
                showingEditView = false
                editableSpot = nil
            }
        )
    }
}
```

---

### **Phase 5: Advanced Features**

#### **Step 5.1: Route Recalculation Logic**
**Extension:** `ios/SmartCityGuide/Services/RouteService.swift`

```swift
// ADD TO RouteService:
func generateUpdatedRoute(
    replacing waypointIndex: Int,
    with newPOI: POI,
    in originalRoute: GeneratedRoute
) async {
    isGenerating = true
    
    do {
        // 1. Create new waypoints array
        var newWaypoints = originalRoute.waypoints
        
        // 2. Replace waypoint at index
        let newWaypoint = RoutePoint(
            id: UUID(),
            name: newPOI.name,
            address: newPOI.address,
            coordinate: newPOI.coordinate,
            category: newPOI.category,
            // ... other properties
        )
        newWaypoints[waypointIndex] = newWaypoint
        
        // 3. Recalculate walking directions
        let newDirections = try await calculateWalkingDirections(for: newWaypoints)
        
        // 4. Create updated route
        let updatedRoute = GeneratedRoute(
            waypoints: newWaypoints,
            walkingDirections: newDirections,
            // ... recalculated metrics
        )
        
        generatedRoute = updatedRoute
        isGenerating = false
        
    } catch {
        errorMessage = "Konnte Route nicht aktualisieren: \(error.localizedDescription)"
        isGenerating = false
    }
}
```

#### **Step 5.2: Enhanced UX Features**

**Haptic Feedback:**
```swift
// IN SwipeCardView:
.onChanged { value in
    card.offset = value.translation
    
    // Haptic feedback at swipe thresholds
    let threshold: CGFloat = 100
    if abs(value.translation.width) > threshold {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}
```

**Loading States:**
```swift
// DURING ROUTE RECALCULATION:
if editService.isGeneratingNewRoute {
    VStack(spacing: 16) {
        ProgressView()
            .scaleEffect(1.2)
        Text("Optimiere neue Route...")
            .font(.body)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground).opacity(0.9))
}
```

**Empty State:**
```swift
// WHEN NO MORE CARDS:
VStack(spacing: 16) {
    Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(.green)
    
    Text("Alle Alternativen durchgeschaut!")
        .font(.headline)
        .fontWeight(.semibold)
    
    Text("Der ursprüngliche Spot bleibt in deiner Route.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    
    Button("Fertig") {
        onCancel()
    }
    .buttonStyle(.borderedProminent)
}
```

---

### **Phase 6: FAQ Documentation Update (MANDATORY)**

#### **Step 6.1: Update HelpSupportView.swift**
**File:** `ios/SmartCityGuide/Views/Profile/HelpSupportView.swift`

**🚨 MANDATORY RULE:** Jede neue Feature-Implementation MUSS die FAQs aktualisieren!

**FAQ Additions Required:**
```swift
// ADD TO ROUTE PLANNING SECTION:
FAQItem(
    question: "Wie kann ich einzelne Stopps in meiner Route ändern?",
    answer: """
    Du kannst jeden Stopp deiner generierten Route bearbeiten:
    
    1. **Stopp auswählen:** Tippe auf das Bearbeiten-Symbol (Stift) neben einem Stopp
    2. **Alternativen durchschauen:** Swipe die Karten nach links (nehmen) oder rechts (überspringen)
    3. **Neue Route:** Bei Auswahl wird automatisch eine optimierte Route berechnet
    
    **Swipe-Steuerung:**
    • Nach links swipen = Stopp übernehmen
    • Nach rechts swipen = Stopp ablehnen
    • Alternativ: Verwende die Buttons am unteren Rand
    
    **Was wird gezeigt:**
    • Bilder und Beschreibung des Ortes
    • Entfernung zum ursprünglichen Stopp
    • Wikipedia-Informationen (falls verfügbar)
    """
),

FAQItem(
    question: "Warum werden mir nur bestimmte Alternative Stopps gezeigt?",
    answer: """
    Die App filtert Alternativen intelligent:
    
    **Filterkriterien:**
    • Maximal 500m Entfernung zum ursprünglichen Stopp
    • Nicht bereits in der Route enthalten
    • Bevorzugt gleiche Kategorie (Museum, Park, etc.)
    • Wikipedia-Daten verfügbar für bessere Infos
    
    **Sortierung:**
    1. Kategorie-Übereinstimmung
    2. Verfügbarkeit von Qualitätsdaten
    3. Entfernung zum Original-Stopp
    
    Wenn keine Alternativen gefunden werden, bleibt der ursprüngliche Stopp in deiner Route.
    """
),

FAQItem(
    question: "Was passiert wenn ich einen Stopp ändere?",
    answer: """
    **Automatische Route-Optimierung:**
    
    1. **Neuer Stopp eingefügt:** Der gewählte alternative Stopp ersetzt den ursprünglichen
    2. **Route neu berechnet:** Laufwege werden automatisch neu optimiert
    3. **Zeiten aktualisiert:** Gesamtzeit und Laufdauer werden angepasst
    4. **Wikipedia-Daten geladen:** Neue Informationen werden im Hintergrund ergänzt
    
    **Wichtig:** Die Reihenfolge der anderen Stopps kann sich durch die Optimierung leicht ändern, um die beste Laufroute zu gewährleisten.
    """
)
```

**Integration Steps:**
1. **Locate existing FAQ sections** in HelpSupportView.swift
2. **Add to "Route Planning" category** (create if not exists)
3. **Maintain consistent German style** and friendly tone
4. **Test FAQ expansion/collapse** functionality
5. **Verify FAQ search** includes new content

**FAQ Categories to Update:**
- **Route Planning:** Main edit functionality
- **App Features:** Swipe interaction explanation  
- **Troubleshooting:** What to do if editing fails

#### **Step 6.2: FAQ Content Guidelines**

**Writing Style:**
- **Friendly & Conversational:** Use "du" and explain like talking to a friend
- **Step-by-Step:** Clear numbered instructions where applicable
- **Visual Indicators:** Use emojis and bullet points for better scanning
- **Problem-Solution:** Address likely user questions and concerns

**Content Requirements:**
```swift
// TEMPLATE FOR NEW FAQ ITEMS:
FAQItem(
    question: "Kurze, klare Frage in deutscher Sprache?",
    answer: """
    Kurze Einführung zum Problem/Feature.
    
    **Schritt-für-Schritt Anleitung:**
    1. Erster Schritt
    2. Zweiter Schritt  
    3. Dritter Schritt
    
    **Wichtige Punkte:**
    • Punkt eins
    • Punkt zwei
    
    **Troubleshooting:** Was tun wenn es nicht funktioniert.
    """
)
```

**Quality Assurance:**
- [ ] German language correctness
- [ ] Consistent with existing FAQ style  
- [ ] Covers all user-facing aspects of route editing
- [ ] Addresses potential confusion points
- [ ] Provides clear troubleshooting steps

---

## 🧪 **TESTING & VALIDATION STRATEGY**

### **Step 6.1: Build Verification**
```bash
# MANDATORY BUILD CHECK:
mcp_XcodeBuildMCP_build_sim_name_proj({
    projectPath: '/path/to/SmartCityGuide.xcodeproj',
    scheme: 'SmartCityGuide',
    simulatorName: 'iPhone 16'
})
```

### **Step 6.2: User Flow Testing**
**Manual Test Scenarios:**
1. **Basic Edit Flow:**
   - Generate route → Tap edit on middle waypoint → Swipe cards → Accept spot → Verify new route

2. **Edge Cases:**
   - No alternatives available → Show empty state
   - Network error during recalculation → Show error message
   - Cancel edit → Return to original route

3. **Performance Testing:**
   - Large POI cache (200+ items) → Smooth scrolling
   - Route recalculation time → Max 3 seconds
   - Memory usage during swipe animations

### **Step 6.3: Accessibility Testing**
- **VoiceOver:** Card content readable
- **Button Access:** Accept/Reject buttons for non-swipe users
- **Dynamic Type:** Text scales properly
- **Color Contrast:** Swipe indicators visible

---

## 📱 **UI/UX SPECIFICATIONS**

### **Design System Compliance**
- **Colors:** Smart City Guide color palette
- **Typography:** System fonts with Dynamic Type
- **Spacing:** 8pt grid system
- **Animations:** Spring animations (0.3s duration)

### **Tinder-Style Interactions**
**References:** Modern dating app UI patterns
- **Swipe Threshold:** 100pt minimum drag distance
- **Auto-Complete:** 150pt threshold for automatic action
- **Visual Feedback:** Real-time rotation and scaling
- **Card Physics:** Bounce-back for insufficient swipe

### **German UI Text**
```swift
// LOCALIZATION STRINGS:
"Finde besseren Spot" // Edit view title
"Alternativen für %@" // Alternatives for waypoint
"Nach links = Nehmen" // Swipe instructions
"Nach rechts = Überspringen"
"Optimiere neue Route..." // Loading state
"Alle Alternativen durchgeschaut!" // Empty state
```

---

## 🚀 **IMPLEMENTATION PRIORITY**

### **Phase A: Core Infrastructure (Priority 1)**
- [ ] RouteEditModels.swift
- [ ] SwipeCardModels.swift
- [ ] RouteEditService.swift

### **Phase B: UI Components (Priority 2)**
- [ ] SpotSwipeCardView.swift
- [ ] SwipeCardStackView.swift
- [ ] RouteEditView.swift

### **Phase C: Integration (Priority 3)**
- [ ] RouteBuilderView modifications
- [ ] Route recalculation logic
- [ ] Error handling

### **Phase D: Polish (Priority 4)**
- [ ] Animations and haptics
- [ ] Empty states
- [ ] Accessibility features

### **Phase E: Documentation Update (MANDATORY)**
- [ ] Update FAQs in HelpSupportView.swift (Step 6.1)
- [ ] Verify FAQ functionality and search integration
- [ ] Test German language consistency

---

## 💡 **SUCCESS CRITERIA**

### **Functional Requirements**
✅ User can edit any intermediate waypoint in generated route
✅ Tinder-style swipe interface works smoothly
✅ Route recalculation completes within 3 seconds
✅ Alternative POIs filtered by distance and quality

### **UX Requirements**
✅ Intro animation teaches swipe interaction
✅ Visual feedback during swipe gestures
✅ Clear accept/reject indicators
✅ Fallback buttons for accessibility

### **Performance Requirements**
✅ Smooth animations at 60fps
✅ Memory usage stays below 150MB
✅ POI filtering completes instantly
✅ No blocking UI operations

### **Documentation Requirements (MANDATORY)**
✅ FAQs updated with Route Edit feature explanation
✅ German language consistency maintained
✅ All user-facing features documented in help section
✅ FAQ search functionality includes new content

---

## 📚 **REFERENCES & INSPIRATION**

1. **Route Editing Patterns:**
   - [MyRouteOnline Manual Changes](https://www.myrouteonline.com/user-guides/manually-change-route-plan-order)
   - Modern navigation app editing flows

2. **Swipe UI Patterns:**
   - Tinder card stack interactions
   - iOS Mail swipe actions
   - Modern dating app UX

3. **Apple Design Guidelines:**
   - Human Interface Guidelines - Gestures
   - SwiftUI Animation Best Practices
   - Accessibility in SwiftUI

---

**🎯 Optimiert für AI-Assistant Implementation**
- Klare Schritt-für-Schritt Struktur
- Copy-paste-ready Code-Snippets
- Detaillierte Spezifikationen für jeden Komponenten
- Build-Verification Checkpoints
- Umfassende Test-Szenarien

**Wir sind der Glubb!** 🔵⚪️ Ready für Implementation! 🚀