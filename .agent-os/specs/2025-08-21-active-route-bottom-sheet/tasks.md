# Spec Tasks

## Tasks

- [x] 1. Implement SwiftUI List with Native Swipe Actions
  - [x] 1.1 Write UI tests for POI swipe gestures in ActiveRouteSheetView
  - [x] 1.2 Convert existing POI display to SwiftUI List with ForEach structure
  - [x] 1.3 Add `.swipeActions(edge: .trailing)` modifier with Edit and Delete buttons
  - [x] 1.4 Implement proper button styling and SF Symbols for native iOS appearance
  - [x] 1.5 Add haptic feedback for swipe actions using UIImpactFeedbackGenerator
  - [x] 1.6 Verify all UI tests pass for swipe interaction

- [x] 2. Implement POI Edit Flow with Cached Alternatives
  - [x] 2.1 Write tests for POI replacement functionality and cached data access
  - [x] 2.2 Extend HomeCoordinator to expose cachedPOIs from route generation
  - [x] 2.3 Create POI replacement sheet modal using existing swipe card components
  - [x] 2.4 Implement Edit button action to present cached POI alternatives
  - [x] 2.5 Add POI selection handling with pendingChanges state tracking
  - [x] 2.6 Integrate with existing Wikipedia image display for alternatives
  - [x] 2.7 Verify all tests pass for POI replacement flow

- [ ] 3. Implement POI Delete Functionality
  - [ ] 3.1 Write tests for POI deletion and route state management
  - [ ] 3.2 Implement Delete button action with immediate POI removal
  - [ ] 3.3 Add confirmation dialog for destructive delete action
  - [ ] 3.4 Update route state to reflect deleted POI with pendingChanges tracking
  - [ ] 3.5 Handle edge cases (deleting last POI, start/end point protection)
  - [ ] 3.6 Verify all tests pass for deletion functionality

- [ ] 4. Add Manual Route Optimization Control
  - [ ] 4.1 Write tests for optimization button state and TSP integration
  - [ ] 4.2 Create prominent "Optimize Route" FloatingActionButton component
  - [ ] 4.3 Implement pendingChanges state to show/hide optimization button
  - [ ] 4.4 Add manual optimization trigger with existing TSP service integration
  - [ ] 4.5 Implement loading state during route reoptimization
  - [ ] 4.6 Handle optimization errors and rate limiting gracefully
  - [ ] 4.7 Verify all tests pass for manual optimization flow

- [ ] 5. Implement Unsaved Changes Protection
  - [ ] 5.1 Write tests for unsaved changes detection and modal warnings
  - [ ] 5.2 Add sheet dismissal interception when pendingChanges exist
  - [ ] 5.3 Create confirmation modal with "Save Changes" and "Discard" options
  - [ ] 5.4 Implement proper state cleanup on save or discard actions
  - [ ] 5.5 Add accessibility support for modal dialogs and warnings
  - [ ] 5.6 Verify all tests pass for unsaved changes protection
