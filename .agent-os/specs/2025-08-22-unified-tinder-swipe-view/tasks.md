# Spec Tasks

## Tasks

- [x] 1. Create Flow Configuration and Service Architecture
  - [x] 1.1 Write tests for SwipeFlowConfiguration enum
  - [x] 1.2 Implement SwipeFlowConfiguration with Manual/Add vs Edit flow settings
  - [x] 1.3 Write tests for UnifiedSwipeService
  - [x] 1.4 Implement UnifiedSwipeService extending POISelectionCardService functionality
  - [x] 1.5 Add flow-specific POI filtering logic (exclude route POIs for Edit flow)
  - [x] 1.6 Implement card recycling logic (rejected cards to back of stack)
  - [x] 1.7 Verify all configuration and service tests pass

- [x] 2. Build Unified Swipe Component
  - [x] 2.1 Write tests for UnifiedSwipeView component
  - [x] 2.2 Create UnifiedSwipeView SwiftUI component
  - [x] 2.3 Integrate Tinder-style gestures (left=accept/green, right=reject/red)
  - [x] 2.4 Implement manual action buttons with identical animations to swipes
  - [x] 2.5 Add flow-adaptive UI elements (POI counter, confirm button)
  - [x] 2.6 Integrate with existing SwipeCard models and Wikipedia enrichment
  - [x] 2.7 Verify all unified component tests pass

- [x] 3. Integrate Manual and Add POI Flows
  - [x] 3.1 Write tests for Manual flow integration in ManualRoutePlanningView
  - [x] 3.2 Replace POISelectionStackView with UnifiedSwipeView in manual planning
  - [x] 3.3 Configure Manual flow with POI counter and confirm button
  - [x] 3.4 Write tests for Add POI flow integration in RouteBuilderView
  - [x] 3.5 Replace AddPOISheetView swipe logic with UnifiedSwipeView
  - [x] 3.6 Maintain sheet presentation and selectedPOIs array integration
  - [x] 3.7 Verify all Manual and Add flow tests pass

- [ ] 4. Integrate Edit POI Flow
  - [ ] 4.1 Write tests for Edit flow integration in ActiveRouteSheetView
  - [ ] 4.2 Replace POIAlternativesSheetView with UnifiedSwipeView
  - [ ] 4.3 Configure Edit flow with auto-confirm and immediate close behavior
  - [ ] 4.4 Implement POI filtering to exclude active route POIs and replaced POI
  - [ ] 4.5 Integrate with HomeCoordinator replacePOI method
  - [ ] 4.6 Verify all Edit flow tests pass

- [ ] 5. Update Tests and Clean Legacy Code
  - [ ] 5.1 Update existing UI tests for backward compatibility with unified component
  - [ ] 5.2 Add new test cases for flow-specific behaviors
  - [ ] 5.3 Verify all existing accessibility IDs work with new implementation
  - [ ] 5.4 Remove obsolete POISelectionCardStackView and POISelectionStackView
  - [ ] 5.5 Clean up unused parts of SpotSwipeCardView if fully replaced
  - [ ] 5.6 Update imports and remove unused POISelectionCardService methods
  - [ ] 5.7 Verify all tests pass and no regressions exist