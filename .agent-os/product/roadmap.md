# Product Roadmap

## Phase 0: Already Completed

Die folgenden Features wurden bereits implementiert:

- [x] **TSP-Optimierte Routengenerierung** - Mathematisch optimierte Walking-Routen zwischen POIs `L`
- [x] **POI-Discovery mit Geoapify** - Kategorie-basierte POI-Suche und Geocoding `M`
- [x] **Multi-Layer Caching System** - Memory + Disk Caching für Performance-Optimierung `M`
- [x] **Sichere API Key Verwaltung** - Certificate Pinning und sichere Konfiguration `S`
- [x] **Wikipedia-Integration** - POI-Anreicherung mit Wikipedia-Daten `M`
- [x] **SwiftUI User Interface** - Moderne iOS-UI mit Navigation und State Management `L`
- [x] **Benutzerprofile** - Profile, Einstellungen und Route-Historie `M`
- [x] **Manual Route Building** - Swipe-basierte POI-Auswahl für manuelle Routen `M`
- [x] **Rate Limiting System** - API-Call-Management und Performance-Schutz `S`
- [x] **UI-Testing Framework** - XCUITest mit Page Object Pattern `M`

## Phase 1: Priority Features & Testing

**Goal:** Restaurant-Integration, erweiterte POI-Kategorien und umfassende Tests
**Success Criteria:** Restaurants intelligent in Routen integriert, mehr POI-Kategorien verfügbar, vollständige Test-Coverage

### Features

- [ ] **Restaurant-Integration** - Intelligente Integration von Restaurants in die Route-Planung basierend auf Timing und Location `M`
- [ ] **Erweiterte POI-Kategorien** - Mehr Kategorien für vielfältigere POI-Discovery (Shopping, Nightlife, Cultural Sites) `S`
- [ ] **Unit Test Suite** - Umfassende Unit Tests für alle Services und Business Logic `L`
- [ ] **UI Test Erweiterung** - Vollständige UI Tests für alle kritischen User Flows `M`
- [ ] **Fine-Tuning bestehender Features** - Performance-Optimierung und Bug-Fixes für alle implementierten Features `S`

### Dependencies

- Geoapify Restaurant-Kategorien Integration
- Erweiterte Test-Framework-Setup

## Phase 2: Experience Enhancement

**Goal:** Verbesserte User Experience durch Quick Planning und optimierte Performance
**Success Criteria:** Reduzierte Time-to-Route und verbesserte Spontaneität

### Features

- [ ] **Quick Route Planning** - Ein-Klick Route-Generierung für spontane City Trips `M`
- [ ] **Performance Optimierung** - Verbesserung der Route-Generierungs-Geschwindigkeit `M`
- [ ] **Enhanced UX für spontane Trips** - Optimierte UI-Flows für Kurzzeit-Besucher `M`
- [ ] **Timing-aware Restaurant Integration** - Restaurants basierend auf Tageszeit in Routen einbauen `S`
- [ ] **Erweiterte Kategorie-Filter** - Mehr Granularität bei POI-Auswahl `S`

### Dependencies

- Abschluss Phase 1 Features
- Restaurant-Timing-Algorithmus

## Phase 3: App Store Readiness

**Goal:** Polish und App Store Launch-Vorbereitung  
**Success Criteria:** App Store-bereite Version mit vollständiger Test-Coverage

### Features

- [ ] **Comprehensive Error Handling** - Robuste Fehlerbehandlung für alle Edge Cases `M`
- [ ] **UI/UX Polish** - Feintuning der Benutzeroberfläche und Animationen `M`
- [ ] **App Store Vorbereitung** - Screenshots, Beschreibungen, Compliance-Check `M`
- [ ] **Performance Benchmarking** - Messbare Performance-Verbesserungen dokumentieren `S`
- [ ] **Security Audit** - Überprüfung aller Sicherheitsaspekte vor Release `S`

### Dependencies

- Abschluss Phase 2 Features
- Vollständige Test-Coverage aus Phase 1

## Phase 4: Advanced Features (Future)

**Goal:** Erweiterte Funktionalitäten basierend auf Nutzer-Feedback
**Success Criteria:** Erhöhte User Retention und erweiterte Feature-Set

### Features

- [ ] **Offline Route Support** - Funktionalität ohne Internetverbindung `L`
- [ ] **Social Features** - Route-Sharing und Community-Features `L`
- [ ] **Advanced TSP Algorithms** - Verbesserte Optimierungsalgorithmen `M`
- [ ] **Multi-City Support** - Routen zwischen verschiedenen Städten `M`
- [ ] **Cycling Routes** - Fahrrad-optimierte Routenplanung `L`

### Dependencies

- Stabiler User-Base
- Performance-Metriken aus Phase 3
- Marktvalidierung
