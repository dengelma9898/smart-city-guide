# File Refactoring Specification

**Datum:** 17. August 2025  
**Ziel:** Aufspaltung der großen Swift-Dateien in logisch zusammengehörige kleinere Module

## Problem Analysis

Unsere aktuellen großen Dateien (>500 Zeilen):

1. **RouteBuilderView.swift** - 1577 Zeilen 📊
2. **RouteService.swift** - 1347 Zeilen 📊
3. **EnhancedActiveRouteSheetView.swift** - 741 Zeilen 📊
4. **ManualRoutePlanningView.swift** - 693 Zeilen 📊
5. **RouteEditView.swift** - 674 Zeilen 📊
6. **RouteEditService.swift** - 589 Zeilen 📊
7. **WikipediaService.swift** - 564 Zeilen 📊
8. **POISelectionStackView.swift** - 539 Zeilen 📊
9. **HelpSupportView.swift** - 534 Zeilen 📊
10. **ContentView.swift** - 518 Zeilen 📊

## Refactoring Plan

### 🎯 Phase 1: RouteBuilderView.swift (1577 → ~350 Zeilen)

**Aufspaltung in:**

1. **RouteBuilderView.swift** (~350 Zeilen)
   - Hauptview und Navigation
   - Body property mit state switching
   - Basic UI structure

2. **Views/Components/RouteDisplay/**
   - **RouteListView.swift** (~200 Zeilen)
     - `generatedRouteListView(_:)`
     - Route summary section
     - Time breakdown section
   - **RouteWaypointRowView.swift** (~150 Zeilen)
     - `waypointRow(route:index:waypoint:)`
     - `walkingRow(route:index:)`
     - Contact info displays
   - **RouteLoadingStateView.swift** (~100 Zeilen)
     - Loading/generating state UI
     - Progress indicators
     - Loading text states

3. **Views/Components/RouteBuilder/**
   - **WikipediaInfoView.swift** (~200 Zeilen)
     - `wikipediaInfoView(for:)`
     - Full-screen image modal
     - Wikipedia data display
   - **AddPOISheetView.swift** (~250 Zeilen)
     - Add POI sheet content
     - Swipe card integration for adding POIs
     - Manual action bars

4. **Services/RouteBuilder/**
   - **RouteBuilderLogic.swift** (~300 Zeilen)
     - POI loading and route generation logic
     - Wikipedia enrichment (2-phase strategy)
     - Helper methods for city extraction
   - **RouteEditOperations.swift** (~200 Zeilen)
     - Edit/insert/delete POI operations
     - Route recalculation logic
     - History management

### 🎯 Phase 2: RouteService.swift (1347 → ~400 Zeilen)

**Aufspaltung in:**

1. **RouteService.swift** (~400 Zeilen)
   - Main service class with @Published properties
   - High-level route generation entry points
   - Error handling and state management

2. **Services/Route/**
   - **RouteGenerationEngine.swift** (~300 Zeilen)
     - Core route generation algorithms
     - TSP optimization logic
     - Waypoint ordering
   - **RoutePOISelector.swift** (~200 Zeilen)
     - POI selection and filtering
     - Distance calculations
     - Quality scoring
   - **RouteCalculator.swift** (~250 Zeilen)
     - MKDirections integration
     - Walking route calculation
     - Performance optimization (parallel/sequential)
   - **RouteValidator.swift** (~200 Zeilen)
     - Walking time validation
     - Distance constraints
     - Route feasibility checks

### 🎯 Phase 3: ContentView.swift (518 → ~200 Zeilen)

**Aufspaltung in:**

1. **ContentView.swift** (~200 Zeilen)
   - Main app structure
   - Navigation coordination
   - Sheet management

2. **Views/Navigation/**
   - **AppCoordinator.swift** (~150 Zeilen)
     - Central navigation logic
     - Sheet destination management
     - Route state coordination
   - **MainTabView.swift** (~150 Zeilen)
     - Tab structure if needed
     - Deep linking coordination

### 🎯 Phase 4: ManualRoutePlanningView.swift (693 → ~250 Zeilen)

**Aufspaltung in:**

1. **ManualRoutePlanningView.swift** (~250 Zeilen)
   - Main view structure and navigation
   - Phase switching logic

2. **Views/Manual/**
   - **ManualPOILoadingView.swift** (~150 Zeilen)
     - Loading states for POI discovery
     - Progress indicators
   - **ManualPOISelectionView.swift** (~200 Zeilen)
     - POI selection UI
     - Card interaction handling
   - **ManualRouteGenerationView.swift** (~100 Zeilen)
     - Route generation progress
     - Completion handling

### 🎯 Phase 5: Kleinere Views Optimieren

**RouteEditView.swift** (674 → ~300 Zeilen):
- Aufspaltung in EditView + EditComponents
- Separate SwipeCard logic

**POISelectionStackView.swift** (539 → ~250 Zeilen):
- Extract card-specific logic
- Separate gesture handling

**HelpSupportView.swift** (534 → ~300 Zeilen):
- FAQ sections in separate files
- Modular help content

## Implementation Strategy

### Schritt 1: Extract Components (Non-Breaking)
1. Erstelle neue Component-Dateien
2. Move UI methods to separate files
3. Keep original files functional

### Schritt 2: Extract Business Logic 
1. Neue Service-Klassen erstellen
2. Logic methods auslagern
3. Dependency injection setup

### Schritt 3: Cleanup and Integration
1. Original files kürzen
2. Import statements anpassen
3. Build verification

### Schritt 4: Testing & Documentation
1. UI Tests aktualisieren
2. Component documentation
3. Architecture overview update

## File Structure After Refactoring

```
ios/SmartCityGuide/
├── Views/
│   ├── Components/
│   │   ├── RouteDisplay/
│   │   │   ├── RouteListView.swift
│   │   │   ├── RouteWaypointRowView.swift
│   │   │   └── RouteLoadingStateView.swift
│   │   ├── RouteBuilder/
│   │   │   ├── WikipediaInfoView.swift
│   │   │   └── AddPOISheetView.swift
│   │   └── Manual/
│   │       ├── ManualPOILoadingView.swift
│   │       ├── ManualPOISelectionView.swift
│   │       └── ManualRouteGenerationView.swift
│   ├── Navigation/
│   │   ├── AppCoordinator.swift
│   │   └── MainTabView.swift
│   └── RoutePlanning/
│       ├── RouteBuilderView.swift (cleaned)
│       ├── ManualRoutePlanningView.swift (cleaned)
│       └── RouteEditView.swift (cleaned)
├── Services/
│   ├── Route/
│   │   ├── RouteGenerationEngine.swift
│   │   ├── RoutePOISelector.swift
│   │   ├── RouteCalculator.swift
│   │   └── RouteValidator.swift
│   ├── RouteBuilder/
│   │   ├── RouteBuilderLogic.swift
│   │   └── RouteEditOperations.swift
│   └── RouteService.swift (cleaned)
```

## Benefits

✅ **Maintainability**: Kleinere, fokussierte Dateien  
✅ **Testability**: Separate Business Logic  
✅ **Reusability**: Component-basierte UI  
✅ **Team Development**: Weniger Merge-Konflikte  
✅ **Code Navigation**: Bessere Struktur im Xcode Navigator  
✅ **Performance**: Lazy loading von Components  

## Migration Schedule

- **Woche 1**: Phase 1 (RouteBuilderView)
- **Woche 2**: Phase 2 (RouteService)  
- **Woche 3**: Phase 3 (ContentView + ManualPlanning)
- **Woche 4**: Phase 4 (Kleinere Views + Testing)

## Backwards Compatibility

- Alle Public APIs bleiben gleich
- Existing Views funktionieren weiterhin
- Schrittweise Migration möglich
- Rollback-fähig durch Git
