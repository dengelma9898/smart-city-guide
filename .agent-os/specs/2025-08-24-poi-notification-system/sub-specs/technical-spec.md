# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-24-poi-notification-system/spec.md

## Technical Requirements

### Existing Implementation Analysis

**✅ Already Implemented:**
- `ProximityService.swift` - Vollständige POI-Proximity-Detection (25m Radius)
- Background Location Monitoring mit "Always" Permission
- UNUserNotificationCenter Integration mit Delegate-Pattern
- Basic Notification Tap Handling (Log-Only, kein App-Opening)
- Visited Spots Tracking (verhindert doppelte Notifications)
- Integration mit LocationManagerService für GPS-Updates

**🚫 Missing Features (Gap Analysis):**
1. Settings-Integration: ProximityService respektiert keine User-Preferences
2. Route-Completion-Detection: Keine Logik für "alle POIs besucht"
3. Route-Completion-Notification: Keine spezielle Erfolgs-Benachrichtigung  
4. App-Opening via Notification: Nur Logging, keine Navigation zur Karte
5. Settings-Reaktivität: Keine Live-Updates wenn Settings während aktiver Route geändert werden

### Technical Implementation Details

#### 1. ProfileSettings Extension

Erweitere `ProfileSettings.swift`:
```swift
// Neue Property hinzufügen
var poiNotificationsEnabled: Bool = true

// Update-Methode erweitern
func updatePOINotificationSetting(enabled: Bool) {
    poiNotificationsEnabled = enabled
    // Trigger ProximityService Settings-Update
}
```

#### 2. ProximityService Enhancement

**Settings-Integration:**
- Neue `@Published var notificationsEnabled: Bool` Property
- Observer für ProfileSettingsManager Changes
- Settings-Check in `triggerSpotNotification()` vor Notification-Trigger

**Route-Completion-Detection:**
- Neue `checkRouteCompletion()` Methode nach jedem POI-Visit
- Logic: `visitedSpots.count == activeRoute.waypoints.count`
- Einmalige Route-Completion-Notification mit spezieller Identifier

#### 3. Enhanced Notification Handling

**App-Opening-Logic:**
- `didReceive response` Delegate-Methode erweitern
- NotificationCenter.post für Navigation-Trigger zur Hauptkarte
- HomeCoordinator Integration für Sheet-Dismissal und Map-Focus

**Notification-Types:**
- POI-Notifications: "spot_[name]_[timestamp]" Identifier
- Route-Completion: "route_completed_[timestamp]" Identifier  
- Unterschiedliche userInfo-Payloads für Type-Detection

#### 4. UI Integration Points

**ProfileSettingsView:**
- Toggle für "POI-Benachrichtigungen" in Settings-List
- Live-Binding an ProfileSettingsManager
- Info-Text über Background-Location-Requirement

**HomeCoordinator:**
- Notification-Observer für App-Opening-Events
- Sheet-Management: Dismiss aktive Sheets beim Notification-Tap
- Map-State-Reset auf aktive Route

### Performance Considerations

- Settings-Observer nur während aktiver Routes aktivieren
- Route-Completion-Check nur bei POI-Visits, nicht kontinuierlich  
- Notification-Permission-Status cachen statt wiederholte Abfragen
- Background-App-Refresh-Status berücksichtigen für Battery-Optimization

### Error Handling & Edge Cases

- Route-Wechsel während aktiver Proximity-Monitoring
- Settings-Updates während Background-App-State
- Notification-Permission-Widerruf während aktiver Route
- App-Kill während Proximity-Monitoring (Background-Continuation)
- Doppelte Route-Completion bei schnellen POI-Visits

### Security & Privacy

- Keine sensitiven Location-Daten in Notification-Payloads
- User-Control über alle Notification-Features
- Graceful Degradation bei Permission-Denial
- Opt-in für Background-Location (nicht automatisch)
