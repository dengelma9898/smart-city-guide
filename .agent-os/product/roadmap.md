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

## Phase 1: Current Development

**Goal:** Finalisierung der Active Route Management Features
**Success Criteria:** Vollständig funktionsfähige Bottom Sheet mit POI-Interaktion

### Features

- [ ] **Active Route Bottom Sheet Finalisierung** - Vollständige Implementierung der POI-Interaktion (Edit/Delete) `M`
- [ ] **Add POIs to Active Route** - Funktionalität zum Hinzufügen neuer POIs zu laufenden Routen `S`
- [ ] **POI Management in Active Routes** - Bearbeitung und Löschung von POIs in aktiven Routen `M`
- [ ] **Code Cleanup nach Refactoring** - Entfernung von ungenutztem Code aus jüngstem Refactoring `S`

### Dependencies

- Abschluss der Bottom Sheet UI-Komponenten
- Integration der bestehenden POI-Services

## Phase 2: Pre-Release Optimization

**Goal:** App-Store-bereite Version mit polierter User Experience
**Success Criteria:** Stabile App ohne kritische Bugs, optimierte Performance

### Features

- [ ] **Performance Optimierung** - Verbesserung der Route-Generierungs-Geschwindigkeit `M`
- [ ] **Error Handling Verbesserung** - Robuste Fehlerbehandlung für Edge Cases `S`
- [ ] **UI/UX Polish** - Feintuning der Benutzeroberfläche und Animationen `M`
- [ ] **Comprehensive Testing** - Vollständige Test-Coverage für alle kritischen Pfade `L`
- [ ] **App Store Vorbereitung** - Screenshots, Beschreibungen, Compliance-Check `M`

### Dependencies

- Abschluss Phase 1 Features
- Vollständige QA-Tests

## Phase 3: Release & Feedback Integration

**Goal:** Erfolgreicher App Store Launch und erste Nutzer-Feedback Integration
**Success Criteria:** Live App im App Store mit positiven Reviews

### Features

- [ ] **App Store Submission** - Einreichung und Approval-Prozess `S`
- [ ] **User Feedback System** - In-App Feedback und Review-Requests `S`
- [ ] **Analytics Integration** - Nutzungsmetriken und Performance-Monitoring `M`
- [ ] **Crash Reporting** - Automatische Crash-Detection und Reporting `S`
- [ ] **A/B Testing Framework** - Testing verschiedener UI/UX Varianten `M`

### Dependencies

- Erfolgreiche Phase 2 Completion
- App Store Approval
- Erste Nutzer-Basis

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
