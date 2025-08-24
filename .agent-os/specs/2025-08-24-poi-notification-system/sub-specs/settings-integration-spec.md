# Settings Integration Specification

Diese Spezifikation beschreibt die Integration von POI-Notification-Preferences in die bestehende ProfileSettings-Architektur.

## ProfileSettings Model Extension

### Neue Properties

```swift
// In ProfileSettings struct hinzufügen:
var poiNotificationsEnabled: Bool = true
```

**Default-Verhalten:**
- Neue User: `poiNotificationsEnabled = true` (Opt-Out-Approach)
- Bestehende User: Automatische Migration mit `true` als Default
- Justification: POI-Notifications sind ein Core-Feature, daher optimistic Default

### Settings-Update-Methoden

**ProfileSettingsManager Extension:**
```swift
// Neue Methode hinzufügen:
func updatePOINotificationSetting(enabled: Bool) {
    settings.poiNotificationsEnabled = enabled
    save()
    
    // Notify ProximityService about setting change
    NotificationCenter.default.post(
        name: .poiNotificationSettingChanged,
        object: nil,
        userInfo: ["enabled": enabled]
    )
}
```

## ProximityService Settings-Integration

### Reactive Settings Monitoring

**Neue Properties:**
```swift
@Published var notificationsEnabled: Bool = true
private var settingsObserver: NSObjectProtocol?
```

**Setup in init():**
```swift
override init() {
    super.init()
    setupNotificationCenter()
    setupSettingsObserver()
    loadCurrentSettingsState()
}

private func setupSettingsObserver() {
    settingsObserver = NotificationCenter.default.addObserver(
        forName: .poiNotificationSettingChanged,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        if let enabled = notification.userInfo?["enabled"] as? Bool {
            Task { @MainActor in
                self?.notificationsEnabled = enabled
            }
        }
    }
}

private func loadCurrentSettingsState() {
    notificationsEnabled = ProfileSettingsManager.shared.settings.poiNotificationsEnabled
}
```

### Notification-Trigger-Modification

**Enhanced triggerSpotNotification:**
```swift
private func triggerSpotNotification(for waypoint: RoutePoint, distance: CLLocationDistance) async {
    // Check permission AND user settings
    guard notificationPermissionStatus == .authorized,
          notificationsEnabled else {
        if !notificationsEnabled {
            logger.info("📢 POI notification skipped - disabled in settings for \(waypoint.name)")
        } else {
            logger.info("📢 POI notification skipped - permission not granted for \(waypoint.name)")
        }
        return
    }
    
    // Rest of existing implementation...
}
```

## ProfileSettingsView UI Integration

### Settings-List-Extension

**Neue Section in ProfileSettingsView:**
```swift
Section("Benachrichtigungen") {
    Toggle("POI-Benachrichtigungen", isOn: Binding(
        get: { profileSettings.settings.poiNotificationsEnabled },
        set: { newValue in
            profileSettings.updatePOINotificationSetting(enabled: newValue)
        }
    ))
    .tint(.primary)
    
    if profileSettings.settings.poiNotificationsEnabled {
        Text("Du erhältst Benachrichtigungen, wenn du einen geplanten POI erreichst.")
            .font(.caption)
            .foregroundColor(.secondary)
    } else {
        Text("POI-Benachrichtigungen sind deaktiviert. Das Tracking läuft weiter.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

### Conditional Help-Text

**Erweiterte Info bei aktivierten Notifications:**
```swift
if profileSettings.settings.poiNotificationsEnabled && 
   locationManager.authorizationStatus != .authorizedAlways {
    HStack(alignment: .top, spacing: 8) {
        Image(systemName: "info.circle")
            .foregroundColor(.orange)
        Text("Für Benachrichtigungen im Hintergrund wird 'Immer'-Berechtigung empfohlen.")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding(.horizontal)
}
```

## Migration & Backward Compatibility

### ProfileSettings Migration

**In ProfileSettings.migrateToNewSettings():**
```swift
mutating func migrateToNewSettings() {
    // Existing migration logic...
    
    // POI Notifications Migration (immer aktiviert für bestehende User)
    // Neue User bekommen bereits true im init(), keine Migration nötig
}
```

**Secure Storage:** 
- Existierende SecureStorageService-Integration bleibt unverändert
- Neue Property wird automatisch mit gespeichert
- Keine separaten Keychain-Operations erforderlich

## Testing Considerations

### Unit Test Cases

1. **Settings-Toggle-Functionality:**
   - Settings-Update propagiert korrekt an ProximityService
   - UI-Toggle reflektiert aktuellen State korrekt

2. **Notification-Behavior:**
   - Mit enabled=true: Notifications werden getriggert
   - Mit enabled=false: Notifications werden übersprungen, aber Tracking läuft weiter

3. **Migration-Behavior:**
   - Neue User haben POI-Notifications aktiviert
   - Bestehende User behalten ihre Settings nach Update

### Integration Test Scenarios

1. **Live-Settings-Changes:**
   - Setting ändern während aktiver Route
   - ProximityService reagiert sofort auf Setting-Change

2. **Permission-Interaction:**
   - Setting aktiviert + Permission denied = Keine Notifications
   - Setting deaktiviert + Permission granted = Keine Notifications

## Notification Names

**Neue NotificationCenter Names:**
```swift
extension Notification.Name {
    static let poiNotificationSettingChanged = Notification.Name("poiNotificationSettingChanged")
}
```
