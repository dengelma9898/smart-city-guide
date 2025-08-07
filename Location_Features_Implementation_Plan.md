# Location Features Implementation Plan
## Smart City Guide - Standort-basierte Funktionen

> **Wir sind der Glubb!** 🔵⚪️
> 
> Detaillierte Implementierungsschritte für Location-Permission und standort-basierte Features

---

## 📋 Übersicht

Diese TODO-Liste beschreibt die Implementierung der **Core Location-Features**:
- ✅ Location-Permission-Management
- ✅ Aktuelle Position auf der Karte anzeigen
- ✅ Current Location als Startpunkt für Route-Planung
- ✅ Location-basierte Benachrichtigungen beim Passieren von Route-Spots
- ⏳ FAQ Update für alle Location-Features (MANDATORY)

**Zukünftige Features** sind in [`Future_Location_Features.md`](./Future_Location_Features.md) dokumentiert:
- 📸 In-App Foto-Feature für Route-Spots
- ⚙️ Erweiterte Location-Einstellungen

---

## 🛠️ Implementation Steps

### 1. **Location-Permission-Management** 
*Status: ✅ Completed*

#### 1.1 Info.plist Konfiguration
- [x] `NSLocationWhenInUseUsageDescription` in Info.plist hinzufügen
- [x] `NSLocationAlwaysAndWhenInUseUsageDescription` für Background-Location hinzufügen
- [x] Friendly German text für Permission-Dialoge

**Dateien:** `ios/SmartCityGuide/Permissions.xcconfig`

**Verifikation:** ✅ Permission-Dialog erscheint beim ersten Start mit deutschen Texten

#### 1.2 LocationManager Service erstellen
- [x] `LocationManagerService.swift` in `Services/` Ordner erstellen
- [x] CLLocationManager mit `@MainActor` implementieren
- [x] Permission-Status Management (denied, authorized, notDetermined)
- [x] Delegate-Pattern für Location-Updates (separater LocationDelegate)
- [x] Error-Handling für Location-Services

**Dateien:** `ios/SmartCityGuide/Services/LocationManagerService.swift`

**Verifikation:** ✅ Service kann Permission-Status korrekt abfragen und verwalten (getestet: Nürnberg 49.4521, 11.0767)

---

### 2. **Current Location auf Karte anzeigen**
*Status: ✅ Completed*

#### 2.1 MapView Integration
- [x] MKMapView um Current Location erweitern (ContentView.swift)
- [x] Blue Dot für User-Position aktivieren (UserAnnotation())
- [x] Location-Permission-Check vor Map-Anzeige
- [x] Fallback-Verhalten bei verweigerter Permission

**Dateien:** `ios/SmartCityGuide/ContentView.swift`

**Verifikation:** ✅ Blaues Punkt-Icon zeigt User-Position auf der Karte

#### 2.2 Permission UI Integration
- [x] Permission-Request-Button in Map-Interface (smart top-right button)
- [x] Informative Messages bei denied/notDetermined Status (color-coded icons)
- [x] Settings-Link bei permanently denied Permission (alert dialog)

**Verifikation:** ✅ Graceful UI-Handling für alle Permission-States (orange→blue button, centering function)

---

### 3. **Current Location als Route-Startpunkt**
*Status: ✅ Completed*

#### 3.1 RouteService Erweiterung
- [x] `RouteService.swift` um Current Location Funktionalität erweitern (StartingLocation enum)
- [x] Current Location als optionalen Startpunkt implementieren (neue generateRoute Überladung)
- [x] Integration mit bestehender TSP-Route-Optimierung (generateRouteInternal refactoring)

**Dateien:** `ios/SmartCityGuide/Services/RouteService.swift`

#### 3.2 UI Integration in RoutePlanningView
- [x] "Meinen Standort verwenden" Button/Toggle (conditional rendering)
- [x] X-Icon zum Entfernen der Current Location (in Current Location Display)
- [x] LocationSearchField erweitern für Current Location Display (smart switching)
- [x] Visual feedback bei aktivierter Current Location (coordinates display)

**Dateien:** 
- `ios/SmartCityGuide/Views/RoutePlanning/RoutePlanningView.swift`
- `ios/SmartCityGuide/Views/RoutePlanning/RouteBuilderView.swift`

**Verifikation:** ✅ User kann Current Location als Startpunkt auswählen und wieder entfernen

#### 3.3 ProfileSettingsView Konfiguration
- [x] Neue Setting-Option "Standard-Startpunkt: Mein Standort" (useCurrentLocationAsDefault)
- [x] Toggle in neue "Startpunkt-Präferenzen" Section hinzugefügt
- [x] Default-Verhalten konfigurierbar (auto-aktiviert Current Location wenn eingestellt)

**Dateien:** 
- `ios/SmartCityGuide/Views/Profile/ProfileSettingsView.swift`
- `ios/SmartCityGuide/Models/ProfileSettings.swift`
- `ios/SmartCityGuide/Views/RoutePlanning/RoutePlanningView.swift`

**Verifikation:** ✅ Toggle in Settings funktioniert, RoutePlanningView wendet Setting automatisch an

---

### 4. **Location-basierte Benachrichtigungen**
*Status: ✅ Completed*

#### 4.1 Notification Permission Setup
- [x] UNUserNotificationCenter Permission Request
- [x] Local Notification Templates für Route-Spots
- [x] Background Location für Geo-Fencing mit UIBackgroundModes

#### 4.2 Proximity Detection Service
- [x] `ProximityService.swift` erstellen
- [x] Distanz-Berechnung zwischen User und Route-Spots
- [x] Threshold-Definition (25m Radius)
- [x] Notification-Trigger bei Annäherung

**Dateien:** `ios/SmartCityGuide/Services/ProximityService.swift`

#### 4.3 Integration mit aktiver Route
- [x] Active Route State Management
- [x] Spot-Visited Status Tracking
- [x] Integration mit RouteService für aktuelle Route-Daten
- [x] Background Location Updates mit Always Permission
- [x] Significant Location Changes für iOS Background

**Verifikation:** ✅ Notification erscheint beim Annähern an einen Route-Spot (Tested on Real Device)

---

### 5. **FAQ Update (MANDATORY)**
*Status: ✅ Completed*

#### 5.1 HelpSupportView FAQ Erweiterung
- [x] Neue FAQ-Kategorie "Standort & Datenschutz"
- [x] FAQ: "Warum braucht die App meinen Standort?"
- [x] FAQ: "Wie funktionieren die Standort-Benachrichtigungen?"
- [x] FAQ: "Kann ich die App ohne Location-Permission verwenden?"
- [x] FAQ: "Wie kann ich meinen Standort als Standard-Startpunkt setzen?"
- [x] Bestehende Datenschutz-FAQs aktualisiert
- [x] Neue Kategorie "Rechtliches" für rechtliche Informationen

**Dateien:** `ios/SmartCityGuide/Views/Profile/HelpSupportView.swift`

**Verifikation:** ✅ FAQ enthält alle neuen Location-Features mit benutzerfreundlichen Erklärungen

---

### 6. **Build-Verifikation und Testing**
*Status: ✅ Completed*

#### 6.1 Xcode MCP Build Verification
- [x] `mcp_XcodeBuildMCP_build_sim_name_proj` für Compile-Check
- [x] Build-Errors beheben falls vorhanden (2 Warnings behoben)
- [x] Simulator-Testing mit iPhone 16

#### 6.2 Permission Testing
- [x] Permission-Flow testen (Allow/Deny scenarios)
- [x] Graceful Degradation bei denied Permissions
- [x] Settings-App Integration testen

#### 6.3 Feature Integration Testing
- [x] Current Location in Route-Planning testen
- [x] Background Notification-Flow testen (Real Device)
- [x] Profile-Settings persistence testen
- [x] Code Review & Polish (Documentation, Performance, Memory Safety)

**Verifikation:** ✅ Alle Features funktionieren korrekt, App kompiliert warning-free, Performance optimiert

---

## 📝 Wichtige Hinweise

### Security & Privacy
- **Privacy-first Approach**: Alle Location-Features funktional auch ohne Permission
- **Transparent Communication**: Klare Erklärung warum Location-Access benötigt wird
- **Data Minimization**: Nur notwendige Location-Daten verwenden

### Performance Considerations
- **Battery Optimization**: Efficient Location-Updates, nicht kontinuierlich
- **Background Activity**: Minimal Background-Location-Usage
- **Caching**: Location-Daten intelligent cachen

### Architecture Notes
- **@MainActor**: LocationManager muss @MainActor sein für UI-Thread-Safety
- **Async/await**: Alle Location-Operations mit modern async patterns
- **Error Handling**: Graceful error handling für alle Location-Services

### Testing Scenarios
1. **First Launch**: Permission-Request-Flow
2. **Permission Denied**: App funktional ohne Location
3. **Permission Granted**: Alle Location-Features verfügbar
4. **Permission Revoked**: Graceful handling wenn User Permission zurückzieht
5. **Background**: Notification-Testing wenn App im Hintergrund
6. **Offline**: Photo-Capture ohne Internet-Verbindung

---

## 🎯 Success Criteria

- ✅ App kompiliert erfolgreich mit allen Core Location Features
- ✅ Permission-Management funktioniert graceful
- ✅ Current Location wird korrekt auf Karte angezeigt
- ✅ Route-Planning nutzt Current Location als Startpunkt
- ✅ Notifications triggern bei Spot-Proximity (Real Device tested)
- ✅ FAQ komplett aktualisiert für alle implementierten Features
- ✅ Alle Features funktional auch ohne Location-Permission

---

**Ready für Implementation! 🚀**