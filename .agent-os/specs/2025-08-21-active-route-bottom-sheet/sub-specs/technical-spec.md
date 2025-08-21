# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-21-active-route-bottom-sheet/spec.md

## Technical Requirements

### SwiftUI Component Enhancements

- **ActiveRouteSheetView Enhancement**: Extend existing component with SwiftUI List and native swipe actions using `.swipeActions` modifier
- **POI Context Menu**: Implement leading/trailing swipe actions with "Edit" and "Delete" buttons using iOS-native styling
- **POI Replacement Sheet**: Create modal sheet presentation for cached POI alternatives using existing swipe card interface components
- **Optimize Route Button**: Add prominent FloatingActionButton-style component with clear visual indication of pending changes
- **Unsaved Changes Modal**: Implement SwiftUI `.alert` or custom modal for change confirmation on sheet dismissal

### State Management Architecture

- **@Published cachedPOIs**: Extend HomeCoordinator to expose cached POI data from route generation
- **@State pendingChanges**: Track route modifications (replaced/added/deleted POIs) before optimization
- **@State showingOptimizeButton**: Reactive state to show/hide optimization control based on pending changes
- **@Published isOptimizing**: Loading state for TSP reoptimization process

### Service Layer Integration

- **POICacheService Integration**: Utilize existing cached POI data from initial route generation instead of new API calls
- **RouteService TSP Integration**: Reuse existing TSP optimization methods with modified POI arrays
- **Rate Limiting Compliance**: Manual optimization prevents automatic API calls on every change
- **Wikipedia Image Integration**: Maintain existing WikipediaService integration for POI images

### Data Flow Architecture

- **POI Edit Flow**: POI left swipe → "Edit" button tap → cached alternatives display → selection → pendingChanges update → optimize button visibility
- **POI Delete Flow**: POI left swipe → "Delete" button tap → remove from route → pendingChanges update → optimize button visibility
- **Add POI Flow**: "Stopp hinzufügen" tap → reuse existing swipe interface → cached POI selection → pendingChanges update
- **Optimization Flow**: "Optimize Route" tap → combine current route + pendingChanges → TSP service call → route update
- **Persistence Flow**: Changes temporary until optimization; sheet dismissal with changes triggers confirmation modal

### Performance Considerations

- **Memory Efficiency**: Reuse existing cached POI data without additional API calls or memory allocation
- **UI Responsiveness**: Async TSP operations with @MainActor UI updates and loading indicators
- **Rate Limit Compliance**: Manual optimization prevents rapid sequential API calls
- **Component Reuse**: Leverage existing RouteWaypointRowView, SwipeCardStackView, and POI selection components

### iOS SwiftUI Implementation Details

- **SwiftUI List Integration**: Convert existing POI display to native SwiftUI List with ForEach for swipe action support
- **Swipe Actions Implementation**: Use `.swipeActions(edge: .trailing)` modifier with Button components for Edit/Delete
- **Navigation**: Maintain existing sheet presentation model with potential nested sheet for POI replacement
- **Gesture Handling**: Native iOS list swipe gestures handle all interaction - no custom tap gesture needed
- **Animation**: Use SwiftUI transitions for optimize button appearance and POI replacement feedback
- **Accessibility**: Native swipe actions provide built-in VoiceOver support with appropriate action labels
- **State Restoration**: Handle proper cleanup of pendingChanges on successful optimization or cancellation
