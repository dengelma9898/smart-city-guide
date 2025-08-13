# Smart City Guide 🏙️

Eine iOS SwiftUI-App für intelligente Multi-Stop-Walking-Routen in Städten mit TSP-Optimierung.

## 🚀 Features

- **Intelligente Routenplanung**: TSP-optimierte Walking-Routen zwischen Sehenswürdigkeiten
- **HERE API Integration**: POI-Discovery mit Kategorie-basierter Auswahl  
- **MapKit Integration**: Präzise Walking-Directions mit 0.2s Rate Limiting
- **Friendly German UI**: "Los, planen wir!" - Conversational User Experience
- **Caching & Performance**: POI-Caching für optimale Performance
- **Manuelles Hinzufügen von POIs**: Über die `+`-Schaltfläche in der Detailansicht per Swipe (nehmen/überspringen)
- **Einzelne POIs löschen**: Swipe-Action „Löschen“ in der Routenliste; beim letzten Zwischenstopp zurück zur Planung
- **Vollständige Reoptimierung**: CTA „Jetzt optimieren“ ordnet neue Stopps intelligent an (Start/Ziel fix)

## 🔧 Setup & Installation

### Voraussetzungen
- **Xcode 15.0+**
- **iOS 17.5+**
- **HERE Developer Account** für API-Zugang

### 1. Repository klonen
```bash
git clone [your-repo-url]
cd smart-city-guide
```

### 2. HERE API Key konfigurieren

⚠️ **WICHTIG**: Diese App benötigt einen HERE API Key für POI-Discovery.

1. **HERE Developer Account erstellen**: https://developer.here.com/
2. **Neuen API Key generieren** mit folgenden Berechtigungen:
   - HERE Search API
   - HERE Geocoding API
3. **APIKeys.plist erstellen**:
   ```bash
   # Erstelle ios/SmartCityGuide/APIKeys.plist
   touch ios/SmartCityGuide/APIKeys.plist
   ```
4. **API Key eintragen**:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>HERE_API_KEY</key>
       <string>DEIN_HERE_API_KEY</string>
   </dict>
   </plist>
   ```
5. **Datei zu Xcode hinzufügen**:
   - Rechtsklick auf "SmartCityGuide" → "Add Files to 'SmartCityGuide'"
   - APIKeys.plist auswählen → "Add to target: SmartCityGuide" ✅

### 3. App builden und starten

Empfohlen (MCP, siehe `.cursorrules`):
- Build gegen iPhone 16 Simulator mit Xcode MCP (siehe in Editor integrierte Commands)

Fallback (xcodebuild):
```bash
cd ios
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 🔒 Security Notes

### ⚠️ SECURITY ADVISORY
**Datum**: 2025-08-03  
**Betroffene Versionen**: Commits vor `83996a9`  
**Problem**: HERE API Key war hardcodiert im Source Code  
**Status**: ✅ **BEHOBEN** - API Key jetzt sicher konfiguriert  

**Maßnahmen**:
- ✅ Hardcodierter API Key entfernt
- ✅ Alter API Key widerrufen 
- ✅ Sichere APIKeys.plist Konfiguration implementiert
- ✅ .gitignore für sensitive Dateien erstellt
- ✅ Comprehensive Security Plan erstellt

**Für Entwickler**: Falls du eine Version vor `83996a9` verwendest, **erstelle sofort einen neuen HERE API Key** und widerrufe den alten.

### Best Practices
- ✅ **APIKeys.plist** ist in `.gitignore` - wird nicht committed
- ✅ **Sichere Konfiguration** über Bundle.main
- ✅ **Error Handling** für fehlende API Keys
- ⚠️ **Niemals API Keys in Code committen**

## 📱 App Architecture

### Core Services
1. **RouteService (@MainActor)**: TSP-optimierte Route-Generierung
2. **HEREAPIService**: POI-Discovery mit Caching via POICacheService  
3. **MapKit Integration**: Walking routes mit MKDirections

### Project Structure
```
ios/SmartCityGuide/
├── Services/           # RouteService, HEREAPIService, POICacheService
├── Models/            # RouteModels, PlaceCategory, OverpassPOI
├── Views/
│   ├── RoutePlanning/ # Route creation flows
│   ├── Profile/       # User profile, history, settings
│   └── Components/    # Reusable UI components
└── Utilities/         # Extensions
```

## 🧪 Testing

### Build Verification
```bash
# MCP Build Test (empfohlen)
# Verwende die in der IDE verfügbare Xcode MCP Aktion für den iPhone 16 Simulator
# (siehe .cursorrules Konfiguration)

# Alternativ (Fallback):
cd ios
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide build
```

### Simulator Testing
```bash
# Launch in iPhone 16 Simulator
open -a Simulator
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' run
```

## 🧪 UI-Tests (XCUITest)

Dieser Abschnitt beschreibt den geplanten, schrittweisen UI-Test-Ansatz gemäß `test-implementations/10-08-2025-ui-test-env-and-first-flow.md`.

### Ziele
- UI-Flow-Tests mit XCUITest (kein Unit-only)
- Page-Object-Pattern für wartbare Tests
- Erster Flow: Profil öffnen → Namen ändern → speichern → neuer Name sichtbar

### Schritt 0: UI-Test-Target anlegen
1. Xcode öffnen → Projekt `SmartCityGuide.xcodeproj`
2. File → New → Target… → iOS → Testing → "UI Testing Bundle"
   - Name: `SmartCityGuideUITests`
   - Host Application: `SmartCityGuide`
   - Add to Project: `SmartCityGuide`
3. Scheme prüfen: `Product → Scheme → Manage Schemes…` → `SmartCityGuide` sollte `SmartCityGuideUITests` enthalten
4. Build verifizieren

Empfohlene (MCP) Build-Verifikation:
```bash
# Xcode MCP (gemäß .cursorrules) – führe den Build gegen iPhone 16 Simulator aus
# Beispiel-Command-Name: mcp_XcodeBuildMCP_build_sim_name_proj (siehe .cursorrules Konfiguration)
```

Falls MCP lokal nicht verfügbar ist, alternativ:
```bash
cd ios
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Nächste Schritte (Kurzüberblick)
- Helper `TestApp.swift` im UI-Test-Target (Launch-Args/-Env + `waitForExists`)
- Page Objects (zuerst `ProfilePage.swift`)
- Accessibility-IDs im App-Code (`profile.name.textfield`, `profile.save.button`, `profile.header.name.label`, `home.profile.button`)
- Seed/Test-Daten via `launchEnvironment["UITEST"] = "1"`
- Flow-Test `Profile_ChangeName_Tests.swift`

#### Neue Accessibility-IDs (Routen-Features)
- `route.add-poi.button`
- `route.add-poi.sheet.swipe`
- `route.add-poi.swipe.like`, `route.add-poi.swipe.skip`
- `route.add-poi.cta.optimize`
- `route.delete-poi.action.{index}`

Weitere Details stehen in `test-implementations/10-08-2025-ui-test-env-and-first-flow.md`.

### Referenzen (Context7)
- XCTest: `/swiftlang/swift-corelibs-xctest`
- XCUITest (Beispielprojekt/Pattern): `/dino-su/clean-scalable-xcuitest`
- SwiftUI Grundlagen: `/zhangyu1818/swiftui.md`

## 📋 Development Guidelines

### Code Style
- **SwiftUI best practices** mit @State, @StateObject, @Published
- **Async/await** statt completion handlers
- **@MainActor** für UI-relevante Services
- **German comments** und friendly UI-Texte

### Security
- 🔴 **NIEMALS** API Keys im Code
- ✅ **Immer** sichere Konfiguration verwenden
- ✅ **Sensitive Dateien** in .gitignore
- ⚠️ **Regular Security Audits**

## 📚 Documentation

- [`Smart_City_Guide_Security_Plan.md`](Smart_City_Guide_Security_Plan.md) - Comprehensive Security Analysis
- [`.cursorrules`](.cursorrules) - AI Development Guidelines
- **HERE API Docs**: https://developer.here.com/documentation

## ✨ How-To: Neue Stopps hinzufügen & löschen

### Neue Stopps hinzufügen
1. In der Routen-Detailansicht oben rechts auf **+** tippen
2. Im Swipe-Deck: links = **nehmen** (✅), rechts = **überspringen** (❌)
3. Mehrere POIs nacheinander hinzufügen (Sheet bleibt offen)
4. **Jetzt optimieren** tippen → Route wird vollständig neu berechnet (Start/Ziel bleiben fix)

### Stopps löschen
1. In der Routenliste einen Zwischenstopp nach links wischen
2. **Löschen** tippen → Route wird neu berechnet
3. Wenn es der letzte Zwischenstopp war → automatische Rückkehr zur Planung

## 🔄 Contributing

1. **Fork** das Repository
2. **Feature Branch** erstellen (`git checkout -b feature/amazing-feature`)
3. **Sichere Entwicklung** - keine hardcodierten Secrets!
4. **Commit** deine Änderungen (`git commit -m 'Add amazing feature'`)
5. **Push** zum Branch (`git push origin feature/amazing-feature`)
6. **Pull Request** erstellen

## 📄 License

[Deine License hier]

## 📞 Support

Bei Fragen oder Problemen:
- **Issues**: GitHub Issues verwenden
- **Security**: Private Security-Probleme an [security@yourcompany.com]
- **HERE API**: HERE Developer Support

---

**⚠️ WICHTIG**: Diese App ist für Bildungs- und Demonstrationszwecke. Für Production-Einsatz weitere Security-Audits durchführen!