# Location Features Implementation Plan
## Smart City Guide - Standort-basierte Funktionen

> **Wir sind der Glubb!** 🔵⚪️
> 
> Detaillierte Implementierungsschritte für Location-Permission und standort-basierte Features

---

## 📋 Übersicht

Diese TODO-Liste beschreibt die Implementierung der folgenden Location-Features:
- ✅ Location-Permission-Management
- 📍 Aktuelle Position auf der Karte anzeigen
- 🎯 Current Location als Startpunkt für Route-Planung
- 🔔 Location-basierte Benachrichtigungen beim Passieren von Route-Spots
- 📸 In-App Foto-Feature für Route-Spots mit Speicherung in Photos + Route History
- ⚙️ Location-Einstellungen in ProfileSettingsView

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

#### 3.3 ProfileSettingsView Konfiguration (Optional)
- [ ] Neue Setting-Option "Standard-Startpunkt: Mein Standort"
- [ ] Toggle in Endpoint-Options Section hinzufügen
- [ ] Default-Verhalten konfigurierbar machen

**Dateien:** 
- `ios/SmartCityGuide/Views/Profile/ProfileSettingsView.swift`
- `ios/SmartCityGuide/Models/ProfileSettings.swift`

**Verifikation:** *Optional für zukünftige Verbesserung*

---

### 4. **Location-basierte Benachrichtigungen**
*Status: ⏳ Pending*

#### 4.1 Notification Permission Setup
- [ ] UNUserNotificationCenter Permission Request
- [ ] Local Notification Templates für Route-Spots
- [ ] Background Location für Geo-Fencing (optional)

#### 4.2 Proximity Detection Service
- [ ] `ProximityService.swift` erstellen
- [ ] Distanz-Berechnung zwischen User und Route-Spots
- [ ] Threshold-Definition (z.B. 25m Radius)
- [ ] Notification-Trigger bei Annäherung

**Dateien:** `ios/SmartCityGuide/Services/ProximityService.swift`

#### 4.3 Integration mit aktiver Route
- [ ] Active Route State Management
- [ ] Spot-Visited Status Tracking
- [ ] Integration mit RouteService für aktuelle Route-Daten

**Verifikation:** Notification erscheint beim Annähern an einen Route-Spot

---

### 5. **In-App Foto-Feature für Route-Spots**
*Status: ⏳ Pending*

#### 5.1 Camera Permission & Integration
- [ ] `NSCameraUsageDescription` in Info.plist
- [ ] `NSPhotoLibraryAddUsageDescription` für Photo-Saving
- [ ] Camera-Interface mit SwiftUI (UIImagePickerController wrapper)

#### 5.2 Photo Capture Service
- [ ] `PhotoCaptureService.swift` erstellen
- [ ] Integration mit Photos Framework
- [ ] Metadata-Tagging für Route-zugehörige Fotos
- [ ] Location-Tagging in EXIF-Daten

**Dateien:** `ios/SmartCityGuide/Services/PhotoCaptureService.swift`

#### 5.3 UI Integration
- [ ] Foto-Button in aktiver Route-View
- [ ] Quick-Camera-Access während Route
- [ ] Preview und Speichern-Flow
- [ ] Spot-Assignment für Fotos

#### 5.4 Route History Integration
- [ ] Foto-Referenzen in RouteHistory-Model erweitern
- [ ] Photo-Gallery in RouteHistoryDetailView
- [ ] Photo-Display in POIDetailView

**Dateien:**
- `ios/SmartCityGuide/Models/RouteHistory.swift`
- `ios/SmartCityGuide/Views/Profile/RouteHistoryDetailView.swift`
- `ios/SmartCityGuide/Views/Components/POIDetailView.swift`

**Verifikation:** Fotos werden sowohl in Photos-App als auch in Route-History gespeichert

---

### 6. **ProfileSettingsView Location-Einstellungen**
*Status: ⏳ Pending*

#### 6.1 Location Settings Section
- [ ] Neue Form-Section "Standort-Präferenzen" hinzufügen
- [ ] Toggle: "Mein Standort als Standard-Startpunkt"
- [ ] Toggle: "Benachrichtigungen bei Route-Spots"
- [ ] Toggle: "Automatisches Foto-Tagging"

#### 6.2 Settings Model Erweiterung
- [ ] `ProfileSettings.swift` um Location-Properties erweitern
- [ ] Default-Werte definieren
- [ ] Persistence über ProfileSettingsManager

**Dateien:**
- `ios/SmartCityGuide/Models/ProfileSettings.swift`
- `ios/SmartCityGuide/Views/Profile/ProfileSettingsView.swift`

**Verifikation:** Alle Location-Settings werden korrekt gespeichert und angewendet

---

### 7. **FAQ Update (MANDATORY)**
*Status: ⏳ Pending*

#### 7.1 HelpSupportView FAQ Erweiterung
- [ ] Neue FAQ-Kategorie "Standort & Datenschutz"
- [ ] FAQ: "Warum braucht die App meinen Standort?"
- [ ] FAQ: "Wie funktionieren die Standort-Benachrichtigungen?"
- [ ] FAQ: "Werden meine Fotos automatisch geteilt?"
- [ ] FAQ: "Kann ich die App ohne Location-Permission verwenden?"

**Dateien:** `ios/SmartCityGuide/Views/Profile/HelpSupportView.swift`

**Verifikation:** FAQ enthält alle neuen Location-Features

---

### 8. **Build-Verifikation und Testing**
*Status: ⏳ Pending*

#### 8.1 Xcode MCP Build Verification
- [ ] `mcp_XcodeBuildMCP_build_sim_name_proj` für Compile-Check
- [ ] Build-Errors beheben falls vorhanden
- [ ] Simulator-Testing mit iPhone 16

#### 8.2 Permission Testing
- [ ] Permission-Flow testen (Allow/Deny scenarios)
- [ ] Graceful Degradation bei denied Permissions
- [ ] Settings-App Integration testen

#### 8.3 Feature Integration Testing
- [ ] Current Location in Route-Planning testen
- [ ] Notification-Flow simulieren
- [ ] Foto-Capture und Storage testen
- [ ] Profile-Settings persistence testen

**Verifikation:** Alle Features funktionieren korrekt und App kompiliert erfolgreich

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

- ✅ App kompiliert erfolgreich mit allen neuen Features
- ✅ Permission-Management funktioniert graceful
- ✅ Current Location wird korrekt auf Karte angezeigt
- ✅ Route-Planning nutzt Current Location als Startpunkt
- ✅ Notifications triggern bei Spot-Proximity
- ✅ Fotos werden korrekt in Photos + Route History gespeichert
- ✅ Profile-Settings für alle Location-Features verfügbar
- ✅ FAQ komplett aktualisiert
- ✅ Alle Features funktional auch ohne Location-Permission

---

**Ready für Implementation! 🚀**