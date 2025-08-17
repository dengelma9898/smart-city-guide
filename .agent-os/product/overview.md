## Smart City Guide – Produktüberblick

**Zweck**: iOS‑App (SwiftUI) zur smarten Multi‑Stop‑Fußgänger‑Routenplanung in Städten, basierend auf POI‑Discovery und TSP‑Optimierung.

**Kernfunktionen**
- Automatische Routenplanung über Sehenswürdigkeiten (POIs) mit Mindestabstand und Gehzeit‑Validierung
- Manuelle Routenplanung (Stops hinzufügen/entfernen, Edit‑Flow)
- Aktive Route mit Sheet‑UI, Fortschritt und POI‑Details
- Profilbereich mit Einstellungen, Verlauf, Avatar/Quick Actions, AGB/Datenschutz/Impressum

**Architektur (High‑Level)**
- UI: SwiftUI Views (`ContentView`, `RoutePlanningView`, `ActiveRouteSheetView`, `ProfileView`)
- Services (@MainActor): `RouteService`, `GeoapifyAPIService`, `LocationManagerService`, `POICacheService`, `ProximityService`
- Models: `RoutePoint`, `GeneratedRoute`, `PlaceCategory`, `POI`
- Utilities: `FeatureFlags`, `RateLimiter`, `SecureLogger`, `NetworkSecurityManager`

**Wesentliche Implementierungsdetails**
- POI‑Suche via Geoapify/HERE, Filterung und Caching, Mindestabstand (≥200m)
- TSP‑Optimierung mit realen Geh‑Distanzen (MapKit `MKDirections`) und Early‑Stop‑Heuristik
- Async/Await, Rate Limiting (~0.2s) für MapKit‑Routenberechnungen
- Fehlerbehandlung: deutschsprachig, nutzerfreundlich, graceful degradation

**Sicherheit & Privacy**
- API‑Keys aus Plist, Zertifikat‑Pinning, Input‑Validierung, begrenztes Logging
- Standort‑Permissions und Benachrichtigungen mit klaren Flows

**Stärken (Auszug)**
- Saubere Service‑Trennung, @MainActor für UI‑relevante Logik
- Deutschsprachige, freundliche UI‑Texte und konsistente Accessibility‑IDs
- Gute Basis an UI‑Tests (XCTest) und Feature‑Flags

**Risiken/Optimierung**
- Uneinheitliche Navigation (`NavigationStack` vs. `NavigationView`), mehrere `.sheet`‑Modifier
- Sequenzielle `MKDirections`‑Berechnungen erhöhen Latenz bei vielen Stopps
- Cache‑Key‑Granularität und fehlende Persistenz, Kopplung via NotificationCenter

Siehe `docs/17-08-2025-architecture-overview.md` für Diagramme, Flows und priorisierte Verbesserungen.


