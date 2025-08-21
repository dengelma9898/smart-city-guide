# Tech Stack

## Context

Global tech stack defaults for Agent OS projects, overridable in project-specific `.agent-os/product/tech-stack.md`.

# Smart City Guide - Technologie-Stack

Eine allgemeine Übersicht über die verwendeten Technologie-Konzepte im Smart City Guide Projekt.

## Plattform & Core Technologies
- iOS 17.5+ als Deployment Target
- Swift 5.0 Programmiersprache
- SwiftUI als primäres UI-Framework
- Foundation Framework für Basis-Funktionalitäten
- MapKit für Kartenintegration
- CoreLocation für Standortdienste

## Architecture Patterns
- MVVM (Model-View-ViewModel) Pattern
- Coordinator Pattern für Navigation-Management
- Singleton Pattern für shared Services
- Protocol-Oriented Programming für Dependency Injection
- Clean Architecture mit Service Layer

## State Management
- SwiftUI State Management (@State, @StateObject, @Published)
- ObservableObject für reactive Data Binding
- Environment Objects für app-weite State-Verteilung

## Data Management & Persistence
- Multi-Layer Caching Strategy (Memory + Disk)
- Secure Storage für sensitive Daten
- UserDefaults für App-Konfiguration
- File System für Cache-Persistierung

## Security & Privacy
- Certificate Pinning für Man-in-the-Middle Schutz
- Secure API Key Management
- OWASP-konforme Security-Implementierung
- Input Validation und Sanitization
- Structured Logging mit Privacy-Schutz

## Performance Optimization
- Traveling Salesman Problem (TSP) Algorithmus für Route-Optimierung
- Async/Await Concurrency für Thread-Safety
- Rate Limiting für API-Calls
- Lazy Loading für Services
- Geographic Distribution Algorithmen

## Testing Framework
- XCUITest für UI-Automation
- Page Object Pattern für wartbare Tests
- Mock Services für isolierte Tests
- Accessibility IDs für Test-Identifikation

## Development Tools
- Xcode als primäre Entwicklungsumgebung
- Feature Flags für dynamische Feature-Kontrolle
- Build Configuration Management
- Asset Management für Icons und Ressourcen

## Concurrency & Threading
- Modern Swift Concurrency (async/await)
- MainActor für UI-Thread-Safety
- Background Task Processing
- Asynchrone Service-Kommunikation

## UI/UX Framework
- SwiftUI Komponenten und Navigation
- Native Animation und Gesture Recognition
- Accessibility Support (VoiceOver, Dynamic Type)
- Modal Presentation (Sheets, Overlays)

## Localization & Internationalization
- Deutsche Lokalisierung als Standard
- Nutzerfreundliche Fehlermeldungen
- Regional API-Integration
