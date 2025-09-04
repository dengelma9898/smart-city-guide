# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart City Guide is an iOS SwiftUI application that generates intelligent multi-stop walking routes for city exploration. The app uses advanced TSP (Traveling Salesman Problem) optimization algorithms to create efficient routes connecting attractions, museums, parks, and cultural sites with proper distance validation and category-based place selection.

## Development Commands

### iOS Development (Use MCP XcodeBuild tools)
- **Build for Simulator**: `mcp__XcodeBuildMCP__build_sim_name_proj` with projectPath `ios/SmartCityGuide.xcodeproj`, scheme `SmartCityGuide`, simulatorName `iPhone 16`
- **Run on Simulator**: Use `mcp__XcodeBuildMCP__build_run_sim_name_proj` for complete build+run
- **Build for macOS**: `mcp__XcodeBuildMCP__build_mac_proj` (project supports macOS builds)
- **List Simulators**: `mcp__XcodeBuildMCP__list_sims` to see available devices
- **Install & Launch**: `mcp__XcodeBuildMCP__install_app_sim` + `mcp__XcodeBuildMCP__launch_app_sim`

### Legacy Xcode Commands (avoid - use MCP tools instead)
- **Build**: Open `ios/SmartCityGuide.xcodeproj` in Xcode and build (⌘+B)
- **Run**: Select target device/simulator in Xcode and run (⌘+R)
- **Test**: Run tests in Xcode (⌘+U)

### Key Build Settings
- **Target iOS Version**: 17.5+
- **Swift Version**: 5.0
- **Bundle ID**: de.dengelma.smartcity-guide (updated from com.smartcity.guide)
- **Xcode Version**: 15.4+

## Architecture Overview

### Core Services Architecture

1. **RouteService (@MainActor)**: Heart of the application
   - Manages route generation lifecycle with intelligent algorithms
   - Coordinates place discovery using category-based selection
   - Implements TSP optimization with actual walking distance validation
   - Handles MapKit integration for walking routes with proper error handling

2. **GeoapifyAPIService**: External POI data integration
   - Singleton service for Geoapify API integration with API key management
   - Coordinates-based POI discovery with caching via POICacheService
   - Category-filtered searches across attractions, museums, parks, cultural sites
   - Rate limiting and error handling for API calls

3. **Route Generation Pipeline**:
   ```
   User Input → Location Search → Geoapify Places Discovery → TSP Optimization → Distance Validation → MapKit Walking Routes
   ```

4. **Data Models**:
   - `RoutePoint`: Waypoint with location, category, and metadata including contact info
   - `GeneratedRoute`: Complete route with waypoints, directions, and timing
   - `PlaceCategory`: Classification system (attraction, museum, park, nationalPark)
   - `POI`: Geoapify response model with rich metadata (phone, email, hours, website)

### UI Structure & User Experience

- **ContentView**: Main map interface with route display and friendly tone ("Los, planen wir!")
- **RoutePlanningView**: Route configuration form with conversational UI ("Wo startest du?", "Wie viele Stopps?")
- **RouteBuilderView**: Route generation and preview ("Wir basteln deine Route!", "Zeig mir die Tour!")
- **ProfileView**: Enhanced user profile with achievement system and statistics
- **RouteHistoryView**: Adventure history with visual enhancements ("Deine Abenteuer")
- **ProfileSettingsView**: User preferences with friendly tone ("So magst du's")

### Current Implementation Status

**✅ Completed Optimizations:**

**Core Route Engine (Phase 1)**:
1. **TSP Route Optimization**: Implements intelligent waypoint ordering using actual walking distances
2. **Walking-Focused Routes**: All routes use `.walking` transport type for city exploration
3. **Category-Based Place Selection**: Intelligent distribution across attraction, museum, park, and cultural categories
4. **Distance Validation**: Respects user-selected distance limits (5km/15km/50km) with proper error handling
5. **Geographic Distribution**: Prevents clustering with 200m minimum distance between waypoints
6. **Smart Fallback**: Automatically reduces stops if route exceeds distance limits

**Geoapify API Integration**:
7. **POI Discovery**: Geoapify Places API for comprehensive POI data and geocoding
8. **Contact Information**: POI details include phone numbers, websites, emails, operating hours
9. **Coordinate-Based Search**: Direct coordinate usage eliminates geocoding overhead
10. **Caching System**: POICacheService reduces API calls and improves performance

**User Experience Enhancements**:
11. **Friendly Tone**: Complete app language transformation from formal to conversational German
12. **Profile System**: Achievement badges, statistics, and visual enhancements
13. **Route History**: Enhanced adventure tracking with summary statistics and visual improvements
14. **Info Dialogs**: Contextual help throughout the planning process

**🔄 Current Limitations:**
1. **Advanced TSP**: Uses nearest-neighbor + basic optimization (genetic algorithms planned for Phase 2)
2. **Transport Modes**: Only walking routes implemented (cycling/transit planned)
3. **Tests**: No automated test suite implemented yet

## Project Structure

### Core Application
- `ios/SmartCityGuide/SmartCityGuideApp.swift`: App entry point with window configuration
- `ios/SmartCityGuide/ContentView.swift`: Main map interface with route display and overlay controls

### Services Layer
- `ios/SmartCityGuide/Services/RouteService.swift`: Main route generation service (@MainActor)
- `ios/SmartCityGuide/Services/GeoapifyAPIService.swift`: Geoapify API integration with caching
- `ios/SmartCityGuide/Services/POICacheService.swift`: POI caching service for performance
- `ios/SmartCityGuide/Services/RouteHistoryManager.swift`: Route persistence and history management
- `ios/SmartCityGuide/Services/UserProfileManager.swift`: User profile and settings management

### Models & Data
- `ios/SmartCityGuide/Models/RouteModels.swift`: Core route data structures (RoutePoint, GeneratedRoute)
- `ios/SmartCityGuide/Models/PlaceCategory.swift`: POI categorization system
- `ios/SmartCityGuide/Models/OverpassPOI.swift`: POI data models for Geoapify/OpenStreetMap
- `ios/SmartCityGuide/Models/RouteHistory.swift`: Route persistence models
- `ios/SmartCityGuide/Models/UserProfile.swift`: User profile and achievement models
- `ios/SmartCityGuide/Models/ProfileSettings.swift`: User preferences and defaults

### Views & UI Components
- `ios/SmartCityGuide/Views/RoutePlanning/`: Route planning and creation flows
- `ios/SmartCityGuide/Views/Profile/`: User profile, history, and settings
- `ios/SmartCityGuide/Views/Components/`: Reusable UI components

### Supporting Files
- `RouteOptimization.md`: Comprehensive TSP implementation analysis and roadmap
- `testing-instructions-phase-1.md`: Testing procedures for route optimization
- `current.md`: MapKit parameters and implementation status

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

## Development Patterns & Architecture

### SwiftUI State Management
- Uses `@State`, `@StateObject`, and `@Published` for reactive UI
- RouteService is `@MainActor` for UI thread safety
- Async/await pattern for MapKit and Geoapify API operations
- Environment objects for shared state (ProfileManager, HistoryManager, SettingsManager)

### Service Architecture Patterns
- **Singleton Services**: GeoapifyAPIService.shared for API coordination
- **Dependency Injection**: Services injected via init() or setters
- **Caching Layer**: POICacheService provides transparent caching with async/await
- **Manager Pattern**: Separate managers for profile, history, and settings persistence

### MapKit Integration
- `Map` view with `MapCameraPosition` for viewport control and automatic route framing
- `MapPolyline` for walking route visualization with blue styling
- `Marker` for waypoint display with category-specific colors and icons
- `MKDirections` for walking route calculation with proper error handling
- `LocationSearchField` with autocomplete displaying full addresses (street, postal code, city)
- **Coordinate Storage**: LocationSearchField stores full `MKMapItem` coordinates to prevent geocoding errors

### Error Handling & User Experience
- Uses Result/throwing patterns with async/await
- Error states displayed in UI with retry options and friendly messages
- Rate limiting with 0.2s delays between API calls
- **Graceful Degradation**: App falls back to fewer stops if distance constraints cannot be met
- **User Feedback**: Loading states with descriptive messages ("Wir basteln deine Route!")

### Geoapify API Integration Pattern
- **Coordinates-First**: Direct coordinate usage eliminates geocoding when possible
- **Category Filtering**: Geoapify categories mapped to internal PlaceCategory enum
- **Retry Logic**: Automatic retry with exponential backoff for API failures
- **Error Recovery**: Falls back gracefully when Geoapify API is unavailable

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

### API Key Management
**✅ Security**: Geoapify API key wird über den Info.plist‑Schlüssel `GEOAPIFY_API_KEY` bezogen. Der tatsächliche Wert kommt aus Build Settings/CI‑Secrets (nicht eingecheckt).

### Recent Architecture Changes
- **Geoapify API Migration**: Replaced MKLocalSearch with Geoapify Places API for richer POI data
- **Coordinate-Based Workflow**: `LocationSearchField` stores full `MKMapItem` coordinates to eliminate geocoding overhead
- **Enhanced Contact Info**: POI models include phone, email, website, and operating hours from Geoapify
- **Achievement System**: ProfileView includes dynamic achievement badges based on user activity
- **Friendly UX**: Complete language transformation from formal to conversational German throughout the app

### Performance Optimizations
- **POI Caching**: `POICacheService` caches Geoapify API responses to reduce network calls
- **Direct Coordinates**: When available, coordinates are passed directly to avoid geocoding
- **Route Optimization**: TSP algorithm uses actual MapKit walking distances, not straight-line calculations
- **Early Termination**: Route generation stops when good solution found (not exhaustive search)

### User Experience Patterns
- **Conversational UI**: All user-facing text uses informal German ("du" form)
- **Visual Feedback**: Achievement badges and statistics provide gamification elements
- **Error Recovery**: Graceful handling of API failures with user-friendly messages
- **Loading States**: Descriptive progress messages during route generation

### Testing & Validation
- **No Unit Tests**: Current implementation lacks automated test suite
- **Manual Testing**: Use MCP XcodeBuild tools for simulator testing
- **Route Validation**: Built-in distance and constraint validation prevents invalid routes

Refer to `RouteOptimization.md` for comprehensive technical analysis and `testing-instructions-phase-1.md` for verification procedures.