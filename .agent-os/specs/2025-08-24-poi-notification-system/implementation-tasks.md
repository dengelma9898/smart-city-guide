# Implementation Tasks Checklist

Diese Datei enthält eine detaillierte Task-Liste für die Implementierung des POI-Notification-System-Features basierend auf der Spezifikation.

## Phase 1: ProfileSettings Integration

### 1.1 ProfileSettings Model Extension
- [ ] `poiNotificationsEnabled: Bool = true` Property zu ProfileSettings hinzufügen
- [ ] `updatePOINotificationSetting(enabled: Bool)` Methode in ProfileSettingsManager implementieren
- [ ] NotificationCenter-Event für Settings-Changes hinzufügen
- [ ] Migration-Logic für bestehende User testen

### 1.2 ProfileSettingsView UI Integration  
- [ ] "Benachrichtigungen"-Section in ProfileSettingsView hinzufügen
- [ ] Toggle für "POI-Benachrichtigungen" implementieren
- [ ] Conditional Help-Text für Background-Location-Hinweis
- [ ] UI-Tests für Settings-Toggle

## Phase 2: ProximityService Enhancement

### 2.1 Settings-Integration
- [ ] `@Published var notificationsEnabled: Bool` Property hinzufügen
- [ ] Settings-Observer für ProfileSettingsManager-Changes
- [ ] `loadCurrentSettingsState()` Methode implementieren
- [ ] Settings-Check in `triggerSpotNotification()` erweitern

### 2.2 Route-Completion-Detection
- [ ] `routeCompletionNotificationSent: Bool` Flag hinzufügen
- [ ] `checkRouteCompletion()` Methode implementieren
- [ ] Integration in `checkProximityToSpots()` nach POI-Visit
- [ ] Reset-Logic in `startProximityMonitoring()`

### 2.3 Route-Completion-Notification
- [ ] `triggerRouteCompletionNotification()` Methode implementieren
- [ ] Spezielle Notification-Content für Route-Completion
- [ ] Unique Identifier für Route-Completion-Notifications
- [ ] UserInfo-Payload mit Route-Statistiken

## Phase 3: Enhanced Notification Handling

### 3.1 Notification-Type-Detection
- [ ] Enhanced `didReceive response` Delegate-Methode
- [ ] `handlePOINotificationTap()` Methode
- [ ] `handleRouteCompletionNotificationTap()` Methode
- [ ] NotificationCenter-Events für HomeCoordinator

### 3.2 HomeCoordinator App-Opening-Logic
- [ ] Notification-Observer für POI- und Route-Completion-Taps
- [ ] `dismissActiveSheets()` Methode implementieren
- [ ] `focusOnActiveRoute()` Methode implementieren
- [ ] `showRouteCompletionSuccess()` für Success-Message

## Phase 4: RouteSuccessView Implementation

### 4.1 RouteCompletionStats Model
- [ ] `RouteCompletionStats` Struct mit Formatierungs-Methoden
- [ ] Distanz/Zeit-Formatierung (km vs. m, h vs. min)
- [ ] Validation für extreme Werte

### 4.2 RouteSuccessView UI
- [ ] Celebratory Header mit animiertem Success-Icon
- [ ] Statistics-Grid mit StatCardView-Components
- [ ] Motivational farewell message ("Danke, dass du mit uns die Stadt erkundet hast!")
- [ ] Single "Bis bald!" Action-Button zurück zur Map
- [ ] Staggered Entry-Animations (Icon → Message → Stats → Button)

### 4.3 ContentView Integration
- [ ] RouteSuccessView Sheet-Presentation in ContentView
- [ ] HomeCoordinator Published Properties für Success-State
- [ ] Map-Focus-Functionality für POI-Notifications
- [ ] `calculateRegionFor(coordinates:)` Methode implementieren

## Phase 5: Testing & Quality Assurance

### 5.1 Unit Tests
- [ ] Settings-Toggle-Functionality
- [ ] Route-Completion-Detection-Logic
- [ ] Notification-Trigger-Behavior mit Settings
- [ ] Double-Completion-Prevention

### 5.2 Integration Tests
- [ ] Live-Settings-Changes während aktiver Route
- [ ] POI-Notification → App-Opening → Map-Focus
- [ ] Route-Completion-Notification → RouteSuccessView-Display
- [ ] Sheet-Dismissal bei Notification-Tap
- [ ] RouteSuccessView "Bis bald!" Button (zurück zur Karte)

### 5.3 UI Tests
- [ ] Cold-Start via Notification
- [ ] Background-Recovery via Notification
- [ ] Settings-UI-Interaction
- [ ] RouteSuccessView-Animations und Statistics-Display
- [ ] Map-Focus-Accuracy

## Phase 6: Documentation & Cleanup

### 6.1 Code Documentation
- [ ] SwiftDoc-Comments für neue Methoden
- [ ] Logger-Messages für Debugging
- [ ] Error-Handling-Documentation

### 6.2 User Documentation  
- [ ] FAQ-Updates in HelpSupportView.swift
- [ ] Settings-Erklärungen für POI-Notifications
- [ ] Background-Location-Explanation

## Implementation Priority

**High Priority (MVP):**
- Phase 1: ProfileSettings Integration
- Phase 2.1: Settings-Integration in ProximityService
- Phase 3.1: Basic Notification Handling

**Medium Priority:**
- Phase 2.2 & 2.3: Route-Completion-Feature
- Phase 3.2: HomeCoordinator App-Opening
- Phase 4.1 & 4.2: RouteSuccessView Implementation

**Low Priority (Polish):**
- Phase 4.3: Map-Focus für POI-Notifications
- Phase 5: Comprehensive Testing
- Phase 6: Documentation

## Definition of Done

**Feature Complete when:**
1. ✅ User kann POI-Notifications in Settings deaktivieren
2. ✅ Settings werden live von ProximityService respektiert
3. ✅ Route-Completion-Notifications erscheinen bei vollständiger Route
4. ✅ POI-Notification-Tap öffnet App auf Karten-Ansicht mit hervorgehobener Route
5. ✅ Route-Completion-Notification-Tap öffnet RouteSuccessView mit Tour-Statistiken
6. ✅ RouteSuccessView zeigt animierte Zusammenfassung: Distanz, Gehzeit, besuchte Spots
7. ✅ "Bis bald!" Button in RouteSuccessView führt zurück zur Karte
8. ✅ Keine doppelten Notifications pro Route/POI
9. ✅ Graceful Degradation bei Permission-Denial

## Risk Mitigation

**Potential Issues:**
- Background-Location-Permission-Complexity → Graceful fallback auf Foreground
- Notification-Permission-Denial → Clear user communication
- Route-Changes während Proximity-Monitoring → Proper state reset
- Map-Region-Calculation-Errors → Fallback auf current region

**Testing-Strategy:**
- Real-Device-Tests für Background-Notifications
- Simulator-Tests für UI-Interaction
- Edge-Case-Tests für Permission-States
- Performance-Tests für Battery-Impact
