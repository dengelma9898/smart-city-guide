# Smart City Guide - Permission System Technical Documentation

*Erstellt: 23.08.2025*  
*Version: 1.0*  
*Autor: System Documentation*

## 📋 Übersicht

Diese Dokumentation erklärt das umfassende Permission-System der Smart City Guide App, das seit der Implementierung des vereinheitlichten Permission-UX aktiv ist. Das System kombiniert iOS-Systemberechtigungen mit App-internen Feature-Toggles für eine optimale User Experience.

## 🏗️ Architektur

### Core Components

```
PermissionsView (UI)
├── Standort-Berechtigung (LocationManagerService)
├── POI-Benachrichtigungen (ProximityService + LocationManagerService)
└── Biometrische Sicherung (BiometricAuthenticationService)
```

### Service Layer

- **LocationManagerService**: Verwaltet alle standortbezogenen Berechtigungen
- **ProximityService**: Verwaltet Benachrichtigungen und POI-Monitoring
- **BiometricAuthenticationService**: Verwaltet biometrische Authentifizierung
- **ProfileSettingsManager**: Persisitiert App-interne Permission-Einstellungen

## 🔧 Permission-Kategorien

### 1. Standort-Berechtigung (App-Nutzung)

**Zweck:** Ermöglicht Routenplanung vom aktuellen Standort und zeigt User-Position auf der Karte.

**iOS System Permission:** `CLLocationManager.requestWhenInUseAuthorization()`

**Implementation:**
```swift
// PermissionsView.swift - Standort Section
Toggle("", isOn: Binding(
    get: { locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways },
    set: { newValue in
        if newValue && locationManager.authorizationStatus == .notDetermined {
            Task { await locationManager.requestLocationPermission(.whenInUse) }
        }
    }
))
```

**Feature Impact:**
- ✅ **Aktiviert:** Automatische Standort-Erkennung, "Mein Standort" als Startpunkt
- ❌ **Deaktiviert:** Manuelle Stadteingabe erforderlich, kein blauer Punkt auf Karte

### 2. POI-Benachrichtigungen (Vereinheitlicht)

**Zweck:** Kombiniert Hintergrund-Standort + Benachrichtigungen für intelligente POI-Alerts während aktiver Routen.

**iOS System Permissions:**
- `CLLocationManager.requestAlwaysAuthorization()`
- `UNUserNotificationCenter.requestAuthorization()`

**Implementation:**
```swift
// PermissionsView.swift - POI-Benachrichtigungen Section
Toggle("", isOn: Binding(
    get: { settingsManager.settings.poiNotificationsEnabled },
    set: { newValue in
        if newValue {
            Task { await requestPOIPermissions() }
        } else {
            settingsManager.updatePOINotifications(enabled: false)
        }
    }
))

private func requestPOIPermissions() async {
    // Beide Berechtigungen parallel anfordern
    async let locationResult = locationManager.requestLocationPermission(.always)
    async let notificationResult = proximityService.requestNotificationPermission()
    
    let (locationGranted, notificationGranted) = await (locationResult, notificationResult)
    
    // App-Toggle nur aktivieren wenn beide Systemberechtigungen gewährt
    let bothGranted = locationGranted && notificationGranted
    settingsManager.updatePOINotifications(enabled: bothGranted)
}
```

**Feature Impact:**
- ✅ **Aktiviert:** Benachrichtigungen bei Annäherung an Route-POIs (~25m), Background-Monitoring
- ❌ **Deaktiviert:** Keine automatischen POI-Alerts, manueller Route-Check erforderlich

**Hybrid Toggle System:**
1. **Systemberechtigung fehlt:** Toggle triggert iOS Permission Dialog
2. **Systemberechtigung vorhanden:** Toggle fungiert als App-interner Feature-Switch
3. **Teilweise gewährt:** Feature bleibt deaktiviert bis beide Berechtigungen vorliegen

### 3. Biometrische Sicherung

**Zweck:** Schützt sensible Profilbereiche ("Deine Abenteuer", "Deine Lieblingsorte") mit Face ID/Touch ID/Optic ID.

**iOS Framework:** `LocalAuthentication.framework`

**Implementation:**
```swift
// BiometricAuthenticationService.swift
func authenticate(reason: String) async -> Bool {
    guard isAvailable else { return true }
    
    let context = LAContext()
    context.localizedReason = reason
    
    do {
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    } catch {
        return false
    }
}

// BiometricProtectedNavigationLink.swift
private func authenticateAndNavigate() async {
    guard settingsManager.isBiometricSecurityEnabled else {
        // Sicherung deaktiviert: Direkt navigieren
        isAuthenticated = true
        return
    }
    
    let success = await biometricService.authenticate(reason: authenticationMessage)
    isAuthenticated = success
}
```

**Feature Impact:**
- ✅ **Aktiviert:** Authentifizierung erforderlich vor Zugriff auf geschützte Bereiche
- ❌ **Deaktiviert:** Direkter Zugriff auf alle Profilbereiche

**Fallback-Verhalten:**
- **Biometrics nicht verfügbar:** Automatischer direkter Zugriff
- **Simulator-Umgebung:** Biometrics automatisch deaktiviert
- **Authentifizierung fehlgeschlagen:** User bleibt auf aktueller Seite, kann Zugriff wiederholen

## 🔄 Intro Flow Integration

### Vereinheitlichter Permission Screen

**Vorher:** Separate Screens für "Location Always" und "Notification Permission"
**Jetzt:** Ein kombinierter "POI-Benachrichtigungen" Screen

```swift
// IntroModels.swift
case .poiNotifications:
    return .finished

func requestPOINotificationPermissions() async {
    async let locationResult = locationManager.requestLocationPermission(.always)
    async let notificationResult = proximityService.requestNotificationPermission()
    
    let _ = await (locationResult, notificationResult)
    // Keine App-Toggle-Logik im Intro - wird in PermissionsView verwaltet
}
```

**UX Benefits:**
- Ein Feature = Ein Permission Screen
- Klare Kommunikation der verbundenen Funktionalität
- Reduzierte Intro-Länge und -Komplexität

## 💾 Data Persistence

### ProfileSettings

```swift
struct ProfileSettings: Codable {
    // Standard App Settings
    var defaultNumberOfPlaces: Int
    var useCurrentLocationAsDefault: Bool
    
    // Permission-related Settings
    var poiNotificationsEnabled: Bool  // App-Toggle für POI-Benachrichtigungen
    var biometricSecurityEnabled: Bool? // Optional für Backwards-Compatibility
}
```

**Migration Strategy:**
- `biometricSecurityEnabled` als Optional mit Default `true`
- Automatic Migration in `ProfileSettingsManager.loadSettings()`
- Backwards-kompatibel zu existierenden Installationen

### Secure Storage

```swift
// Alle Service-Initialisierungen verwenden skipAutoLoad oder promptMessage: nil
UserProfileManager(skipAutoLoad: true)
ProfileSettingsManager.shared // mit promptMessage: nil in load()
RouteHistoryManager(skipAutoLoad: true)
```

**Security Considerations:**
- Keine automatischen Face ID Prompts beim App-Start
- Biometric Authentication nur bei explizitem User-Intent
- Services können ohne Face ID initialisiert werden

## 🎯 Feature Interaction Matrix

| Feature | Standort (App) | POI-Benachrichtigungen | Biometrische Sicherung |
|---------|----------------|------------------------|------------------------|
| **Route Planning** | Optional (ermöglicht "Mein Standort") | Nicht erforderlich | Nicht erforderlich |
| **Navigation** | Empfohlen (zeigt Position) | Nicht erforderlich | Nicht erforderlich |
| **POI Alerts** | Nicht erforderlich | **Erforderlich** | Nicht erforderlich |
| **Profile Access** | Nicht erforderlich | Nicht erforderlich | Optional (für "Abenteuer"/"Lieblingsorte") |
| **Background Monitoring** | Nicht erforderlich | **Erforderlich** | Nicht erforderlich |

## 🚨 Error Handling

### Permission Denial

```swift
// Automatische Weiterleitung zu iOS Settings bei verweigerter Berechtigung
if locationManager.authorizationStatus == .denied {
    await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
}
```

### Biometric Authentication Failure

```swift
// Graceful Fallback ohne App-Crash
guard biometricService.isAvailable else {
    // Simulator oder keine Biometrics: Direkter Zugriff
    isAuthenticated = true
    return
}

// Authentication failed: User bleibt auf aktueller Seite
if !success {
    authenticationError = "Zugriff verweigert. Authentifizierung erforderlich."
    showingAuthenticationError = true
}
```

## 🔍 Debugging & Monitoring

### Logging Categories

```swift
// LocationManagerService
Logger(subsystem: "de.dengelma.smartcity-guide", category: "Location")

// ProximityService  
Logger(subsystem: "de.dengelma.smartcity-guide", category: "Proximity")

// BiometricAuthenticationService
Logger(subsystem: "de.dengelma.smartcity-guide", category: "BiometricAuth")
```

### Key Log Points

- Permission Request Initiation
- System Permission Dialog Results
- App-Toggle State Changes
- Biometric Authentication Attempts
- Background POI Monitoring Status

## 📊 Testing Strategy

### Unit Tests

- [ ] Permission State Transitions
- [ ] Hybrid Toggle Logic
- [ ] Biometric Availability Detection
- [ ] Settings Persistence/Migration

### Integration Tests

- [ ] Complete Permission Flow (Intro → Settings)
- [ ] POI Notification Delivery
- [ ] Biometric Authentication Flow
- [ ] Permission Denial Handling

### Manual Testing Scenarios

1. **Fresh Install:** Intro Flow → Permission Granting → Feature Verification
2. **Permission Denial:** Deny in iOS Settings → App Behavior Verification
3. **Mixed States:** Grant one, deny other → Hybrid Toggle Behavior
4. **Biometric Scenarios:** Face ID Success/Fail/Unavailable

## 🔮 Future Considerations

### Planned Enhancements

- **Permission Analytics:** Track permission grant/denial rates
- **Smart Permission Prompting:** Context-aware permission requests
- **Enhanced Biometric Options:** App-specific passcode fallback
- **Permission Education:** Interactive tutorials for complex permissions

### Migration Path

- Maintain backwards compatibility for minimum 2 major versions
- Graceful degradation for older iOS versions
- Clear migration messaging for breaking changes

---

## 📞 Support & Maintenance

**Primary Maintainer:** System Documentation  
**Technical Contact:** development@smartcityguide.de  
**Last Updated:** 23.08.2025  
**Next Review:** Bei nächstem Permission-System Update
