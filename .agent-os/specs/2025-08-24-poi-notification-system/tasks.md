# Spec Tasks

## Tasks

- [ ] 1. ProfileSettings Integration für POI-Notification-Kontrolle
  - [ ] 1.1 Write tests for ProfileSettings POI-notification toggle functionality
  - [ ] 1.2 Extend ProfileSettings model with `poiNotificationsEnabled: Bool` property
  - [ ] 1.3 Add `updatePOINotificationSetting(enabled: Bool)` method to ProfileSettingsManager
  - [ ] 1.4 Create NotificationCenter event for settings changes (.poiNotificationSettingChanged)
  - [ ] 1.5 Add POI-Notifications toggle section to ProfileSettingsView UI
  - [ ] 1.6 Implement conditional help text for background location requirements
  - [ ] 1.7 Verify all tests pass

- [ ] 2. ProximityService Settings-Integration und Enhancement
  - [ ] 2.1 Write tests for ProximityService settings-reactive behavior
  - [ ] 2.2 Add `@Published var notificationsEnabled: Bool` property to ProximityService
  - [ ] 2.3 Implement settings observer for ProfileSettingsManager changes
  - [ ] 2.4 Add `loadCurrentSettingsState()` method to sync initial settings
  - [ ] 2.5 Enhance `triggerSpotNotification()` with settings check
  - [ ] 2.6 Add route completion detection with `checkRouteCompletion()` method
  - [ ] 2.7 Implement `routeCompletionNotificationSent` flag and reset logic
  - [ ] 2.8 Verify all tests pass

- [ ] 3. Route-Completion-Notification und Enhanced Notification Handling
  - [ ] 3.1 Write tests for route completion notification triggering and handling
  - [ ] 3.2 Implement `triggerRouteCompletionNotification()` with enhanced userInfo payload
  - [ ] 3.3 Enhance UNUserNotificationCenterDelegate with notification type detection
  - [ ] 3.4 Add separate handlers for POI and route completion notification taps
  - [ ] 3.5 Create NotificationCenter events for HomeCoordinator integration
  - [ ] 3.6 Implement notification observers in HomeCoordinator for app opening logic
  - [ ] 3.7 Add `dismissActiveSheets()` method for clean navigation
  - [ ] 3.8 Verify all tests pass

- [ ] 4. RouteSuccessView Implementation mit Tour-Statistiken
  - [ ] 4.1 Write tests for RouteCompletionStats model and formatting methods
  - [ ] 4.2 Create `RouteCompletionStats` struct with distance/time formatting
  - [ ] 4.3 Implement RouteSuccessView with celebratory header and animated success icon
  - [ ] 4.4 Build statistics grid with StatCardView components (distance, time, POIs)
  - [ ] 4.5 Add motivational farewell message and "Bis bald!" button
  - [ ] 4.6 Implement staggered entry animations (icon → message → stats → button)
  - [ ] 4.7 Integrate RouteSuccessView sheet presentation in ContentView
  - [ ] 4.8 Verify all tests pass

- [ ] 5. Map-Focus Enhancement für POI-Notifications
  - [ ] 5.1 Write tests for map region calculation and focus functionality
  - [ ] 5.2 Add NotificationCenter observer for `focusMapOnRoute` in ContentView
  - [ ] 5.3 Implement `calculateRegionFor(coordinates:)` method with error handling
  - [ ] 5.4 Add animated map region updates for route highlighting
  - [ ] 5.5 Integrate map focus functionality with POI notification handling
  - [ ] 5.6 Add validation for invalid coordinates and fallback behavior
  - [ ] 5.7 Verify all tests pass
