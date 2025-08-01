# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart City Guide is an iOS SwiftUI application that generates intelligent multi-stop walking/driving routes for city exploration. The app helps users discover attractions, museums, parks, and cultural sites by creating optimized routes with multiple waypoints.

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
   - Manages route generation lifecycle
   - Coordinates place discovery and route optimization
   - Handles MapKit integration for directions
   - Currently uses basic nearest-neighbor selection (needs TSP optimization)

2. **Route Generation Pipeline**:
   ```
   User Input → Location Search → Place Discovery → Route Optimization → MapKit Routing
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

### Current Technical Limitations

1. **Route Optimization**: Uses pseudo-random waypoint selection instead of TSP algorithms
2. **Transportation**: Only supports automobile routing (walking/cycling not implemented)
3. **Place Discovery**: Generic search queries, no intelligent categorization
4. **Distance Calculation**: Uses straight-line distance during optimization (inaccurate)

## Key Files and Their Purpose

- `ios/SmartCityGuide/SmartCityGuideApp.swift`: App entry point
- `ios/SmartCityGuide/ContentView.swift`: Main UI with embedded RouteService, route models, and all views
- `ios/SmartCityGuide.xcodeproj/`: Xcode project configuration
- `RouteOptimization.md`: Comprehensive analysis of current routing system and improvement roadmap
- `current.md`: Summary of MapKit parameters and current implementation status

## Route Generation System Details

### Current Algorithm (in RouteService)
1. **Location Discovery**: MKLocalSearch for starting city
2. **Place Search**: Generic MapKit search for POIs
3. **Selection**: Linear offset selection (essentially random)
4. **Optimization**: Basic distance filtering
5. **Routing**: Sequential MKDirections calls

### Known Issues
- Route optimization uses `attempt * 2 % max(1, places.count - count)` which is pseudo-random
- No TSP (Traveling Salesman Problem) optimization
- Single transport mode (automobile only)
- Straight-line distance used for optimization instead of actual routes

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
- `Map` view with `MapCameraPosition` for viewport control
- `MapPolyline` for route visualization
- `Marker` for waypoint display
- `MKLocalSearch` for location/POI discovery
- `MKDirections` for route calculation

### Error Handling
- Uses Result/throwing patterns
- Error states displayed in UI with retry options
- Rate limiting with 0.2s delays between API calls

## Performance Considerations

- Route generation limited to 10 combination attempts
- Place search gets 5x requested count for better selection
- Geographic distribution applied to prevent clustering
- Caching not implemented (opportunity for improvement)

## Future Enhancement Priorities

1. **High Priority**: Implement proper TSP optimization, category-based place selection
2. **Medium Priority**: Add walking/cycling routes, implement caching
3. **Low Priority**: ML-based recommendations, community features

Refer to `RouteOptimization.md` for detailed technical analysis and implementation roadmap for transforming the current basic routing into an intelligent route generation system.