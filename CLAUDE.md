# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart City Guide is an iOS SwiftUI application that generates intelligent multi-stop walking routes for city exploration. The app uses advanced TSP (Traveling Salesman Problem) optimization algorithms to create efficient routes connecting attractions, museums, parks, and cultural sites with proper distance validation and category-based place selection.

## Development Commands

### iOS Development
- **Build**: Open `ios/SmartCityGuide.xcodeproj` in Xcode and build (⌘+B)
- **Run**: Select target device/simulator in Xcode and run (⌘+R)
- **Test**: Run tests in Xcode (⌘+U)

### Key Build Settings
- **Target iOS Version**: 17.5+
- **Swift Version**: 5.0
- **Bundle ID**: com.smartcity.guide
- **Xcode Version**: 15.4+

## Architecture Overview

### Core Components

1. **RouteService (@MainActor)**: Heart of the application
   - Manages route generation lifecycle with intelligent algorithms
   - Coordinates place discovery using category-based selection
   - Implements TSP optimization with actual walking distance validation
   - Handles MapKit integration for walking routes with proper error handling

2. **Route Generation Pipeline**:
   ```
   User Input → Location Search → Category-Based Place Discovery → TSP Optimization → Distance Validation → MapKit Walking Routes
   ```

3. **Data Models**:
   - `RoutePoint`: Waypoint with location, category, and metadata
   - `GeneratedRoute`: Complete route with waypoints, directions, and timing
   - `PlaceCategory`: Classification system (attraction, museum, park, nationalPark)

### UI Structure

- **ContentView**: Main map interface with route display
- **RoutePlanningView**: Route configuration form
- **RouteBuilderView**: Route generation and preview
- **ProfileView**: User profile and settings

### Current Implementation Status

**✅ Completed Optimizations (Phase 1):**
1. **TSP Route Optimization**: Implements intelligent waypoint ordering using actual walking distances
2. **Walking-Focused Routes**: All routes use `.walking` transport type for city exploration
3. **Category-Based Place Selection**: Intelligent distribution across attraction, museum, park, and cultural categories
4. **Distance Validation**: Respects user-selected distance limits (5km/15km/50km) with proper error handling
5. **Geographic Distribution**: Prevents clustering with 200m minimum distance between waypoints
6. **Smart Fallback**: Automatically reduces stops if route exceeds distance limits

**🔄 Current Limitations:**
1. **Caching**: Distance calculations not cached (performance opportunity)
2. **Advanced TSP**: Uses nearest-neighbor + basic optimization (genetic algorithms planned for Phase 2)
3. **Transport Modes**: Only walking routes implemented (cycling/transit planned)

## Key Files and Their Purpose

- `ios/SmartCityGuide/SmartCityGuideApp.swift`: App entry point
- `ios/SmartCityGuide/ContentView.swift`: Main UI with embedded RouteService, route models, and all views
- `ios/SmartCityGuide.xcodeproj/`: Xcode project configuration
- `RouteOptimization.md`: Comprehensive analysis and Phase 1-3 implementation roadmap for TSP optimization
- `testing-instructions-phase-1.md`: Testing checklist for verifying TSP optimization and place selection improvements
- `current.md`: Summary of MapKit parameters and implementation status

## Route Generation System Details

### Current Algorithm (in RouteService)
1. **Location Discovery**: MKLocalSearch with full address formatting and coordinate storage
2. **Category-Based Place Search**: Parallel searches across attraction, museum, park, and cultural categories
3. **Geographic Distribution**: Prevents clustering with 200m minimum distance between places
4. **TSP Optimization**: Tries multiple route combinations using actual MapKit walking distances
5. **Distance Validation**: Respects user-selected limits, automatically reduces stops if needed
6. **Route Generation**: Sequential `.walking` MKDirections calls with 0.2s rate limiting

### Key Implementation Features
- Uses actual walking distances from MapKit instead of straight-line calculations
- Implements intelligent place selection with category distribution targeting (40% attractions, 30% museums, etc.)
- Validates routes against user-selected distance limits (5km/15km/50km) before acceptance
- Provides helpful error messages when insufficient nearby places are found within distance constraints
- Automatically falls back to fewer stops if route exceeds distance limits

### Route Length Categories
```swift
case short  // ≤5km total, 3km search radius
case medium // ≤15km total, 8km search radius  
case long   // ≤50km total, 15km search radius
```

## Development Patterns

### SwiftUI State Management
- Uses `@State`, `@StateObject`, and `@Published` for reactive UI
- RouteService is `@MainActor` for UI thread safety
- Async/await pattern for MapKit operations

### MapKit Integration
- `Map` view with `MapCameraPosition` for viewport control and automatic route framing
- `MapPolyline` for walking route visualization with blue styling
- `Marker` for waypoint display with category-specific colors and icons
- `MKLocalSearch` for location/POI discovery with full address formatting
- `MKDirections` for walking route calculation with proper error handling
- `LocationSearchField` with autocomplete displaying full addresses (street, postal code, city)

### Error Handling
- Uses Result/throwing patterns
- Error states displayed in UI with retry options
- Rate limiting with 0.2s delays between API calls

## Performance Considerations

- Route generation limited to 10 combination attempts with early termination for good routes
- Place search gets 5x requested count for better selection across categories
- Geographic distribution applied to prevent clustering (200m minimum distance)
- Parallel category searches for improved discovery speed
- Rate limiting (0.2s delays) to avoid MapKit API throttling
- **Optimization Opportunity**: Distance caching not yet implemented

## Implementation Phases

**✅ Phase 1 Complete** (Current): TSP optimization with category-based place selection
- Nearest-neighbor TSP algorithm with actual walking distances
- Category distribution targeting and geographic anti-clustering
- Distance validation respecting user-selected limits (5km/15km/50km)
- Smart fallback reducing stops when routes exceed distance constraints

**🔄 Phase 2 Planned**: Advanced optimization and performance
- Distance caching system for repeated route calculations
- 2-opt and genetic algorithm implementations for complex routes
- Enhanced place quality scoring system

**📋 Phase 3 Future**: Extended functionality
- Cycling and transit route options
- Offline route storage and sharing
- ML-based personalized recommendations

## Critical Implementation Details

**Address Selection Bug Fix**: `LocationSearchField` now stores full `MKMapItem` coordinates, not just text, preventing incorrect location selection during route generation.

**Route Length Validation**: System validates routes against user-selected distance limits using actual MapKit walking distances, providing helpful error messages when constraints cannot be met.

Refer to `RouteOptimization.md` for comprehensive technical analysis and `testing-instructions-phase-1.md` for verification procedures.