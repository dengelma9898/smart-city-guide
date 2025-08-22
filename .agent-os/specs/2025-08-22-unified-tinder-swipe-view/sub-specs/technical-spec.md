# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-22-unified-tinder-swipe-view/spec.md

## Technical Requirements

### Unified Component Architecture

- **UnifiedSwipeView** - Neue SwiftUI-View, die SpotSwipeCardView und POISelectionCardStackView ersetzt
- **SwipeFlowConfiguration** - Enum oder Struct zur Definition von Flow-spezifischen Verhaltensweisen (Manual/Add vs Edit)
- **UnifiedSwipeService** - Service-Klasse (@MainActor), die POISelectionCardService-Funktionalität erweitert und flow-spezifische Logik kapselt
- **Card Stack Management** - Wiederverwendung und Erweiterung der bestehenden SwipeCard und CardStackState-Models

### Gesture Implementation

- **Tinder-Standard Gestures** - Links=Accept (Grün, Checkmark), Rechts=Reject (Rot, X), basierend auf Web-Research zu Tinder UX-Conventions
- **Manual Action Buttons** - Zwei zentrierte Buttons am unteren Rand, die identische Swipe-Animationen wie Gestures triggern
- **Programmatic Animations** - Verwendung der bestehenden NotificationCenter-basierten Animation-Triggerung aus SpotSwipeCardView
- **Haptic Feedback** - Integration der bestehenden UIImpactFeedbackGenerator-Implementation

### Flow-Specific Behavior Configuration

**Manual & Add Flow:**
- `showSelectionCounter: Bool = true` - Anzeige der POI-Auswahl-Anzahl
- `showConfirmButton: Bool = true` - Bestätigungs-Button erforderlich
- `autoConfirmSelection: Bool = false` - Keine automatische Bestätigung
- `allowContinuousSwipe: Bool = true` - Fortlaufendes Swipen bis Bestätigung
- `onAbort: ClearSelections` - Bei Abbruch werden Auswahlen verworfen

**Edit Flow:**
- `showSelectionCounter: Bool = false` - Keine Anzahlanzeige
- `showConfirmButton: Bool = false` - Kein Bestätigungs-Button
- `autoConfirmSelection: Bool = true` - Sofortige Bestätigung bei Auswahl
- `allowContinuousSwipe: Bool = false` - Schließen nach erster Auswahl
- `excludedPOIs: [POI]` - Filterung von aktiven Route-POIs und zu ersetzendem POI

### Data Flow Integration

- **POI Filtering** - Integration mit bestehender getPOIAlternatives-Logik für Edit-Flow
- **Wikipedia Enrichment** - Weiterverwendung der bestehenden WikipediaEnrichedPOI-Integration
- **Distance Calculation** - Beibehaltung der distanceFromOriginal-Berechnung für POI-Anzeige
- **Category Icons & Colors** - Verwendung der bestehenden PlaceCategory-Konfiguration

### Animation & Performance

- **Card Stack Recycling** - Rejected Cards wandern ans Ende des Stapels (Queue-Logik)
- **Memory Management** - Lazy Loading der Card-Stack mit maximal 3 sichtbaren Karten
- **Animation Optimization** - Wiederverwendung der bestehenden CardAnimationConfig-Konfiguration
- **Rate Limiting** - Integration mit bestehender RateLimiter-Implementation bei API-Aufrufen

### Integration Points

- **HomeCoordinator Integration** - Verwendung der bestehenden replacePOI/deletePOI-Methoden
- **ActiveRouteSheetView** - Ersetzung der aktuellen POIAlternativesSheetView-Implementation
- **RouteBuilderView** - Integration in bestehende AddPOISheetView-Logik
- **ManualRoutePlanningView** - Ersetzung der POISelectionStackView-Implementation

### Error Handling & Validation

- **Input Validation** - Verwendung des bestehenden InputValidator für POI-Validierung
- **Error Recovery** - Graceful Degradation bei Empty Card Stacks oder API-Fehlern
- **Accessibility** - Beibehaltung der bestehenden Accessibility IDs für UI-Tests
- **Logging** - Integration mit SecureLogger für Debug-Information und Performance-Monitoring
