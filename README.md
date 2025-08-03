# Smart City Guide 🏙️

Eine iOS SwiftUI-App für intelligente Multi-Stop-Walking-Routen in Städten mit TSP-Optimierung.

## 🚀 Features

- **Intelligente Routenplanung**: TSP-optimierte Walking-Routen zwischen Sehenswürdigkeiten
- **HERE API Integration**: POI-Discovery mit Kategorie-basierter Auswahl  
- **MapKit Integration**: Präzise Walking-Directions mit 0.2s Rate Limiting
- **Friendly German UI**: "Los, planen wir!" - Conversational User Experience
- **Caching & Performance**: POI-Caching für optimale Performance

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
# MCP Build Test
cd ios
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide build
```

### Simulator Testing
```bash
# Launch in iPhone 16 Simulator
open -a Simulator
xcodebuild -project SmartCityGuide.xcodeproj -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' run
```

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