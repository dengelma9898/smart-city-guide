## Roadmap

### Phase 0 – Bestand (fertig/teilweise vorhanden)
- TSP‑Optimierung (Basis), POI‑Integration (Geoapify/HERE), Kategorie‑Filter
- Mindestabstand, Gehzeit‑Validierung, Early‑Stop, Caching via `POICacheService`
- SwiftUI UI mit Active Route Sheet, Profil, Verlauf, Einstellungen
- UI‑Tests Grundflüsse vorhanden

### Phase 1 – Navigation vereinheitlichen (hoch)
- Migrate `RoutePlanningView` auf `NavigationStack`
- Zentrales Sheet‑Routing in `ContentView` mit `SheetDestination?`
- Entfernen der Re‑Open `.onChange`‑Logik, deterministische Präsentation

### Phase 2 – Routen‑Performance (hoch)
- Parallele `MKDirections.calculate` (max 2–3 gleichzeitige Tasks) mit Rate Limiter
- Laufzeiten messen/loggen via `SecureLogger`

### Phase 3 – Cache‑Strategie (mittel)
- Cache‑Key differenzieren (city vs. city@lat,lon@radius)
- Disk‑Persistenz + TTL, Startup‑Pruning

### Phase 4 – State‑Entkopplung (mittel)
- `HomeCoordinator` als `@StateObject` in `ContentView` für Route/Sheets/Quick‑Planning
- DI für `RouteService` und optionale History‑Injection

### Phase 5 – UX Active Route (mittel)
- Fortschritt, Tap → `POIDetailView`, Aktionen „Nächster Stopp“, „Überspringen“
- Snapshot‑Tests für Sheet‑Zustände

### Phase 6 – Fehler‑Flows (mittel)
- Einheitliche Fehlerkomponente mit Retry und Support‑Link

### Phase 7 – Feature‑Flags (niedrig)
- Optional: Remote‑Konfiguration (JSON in `SecureStorageService`)


