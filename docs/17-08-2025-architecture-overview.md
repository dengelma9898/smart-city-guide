## Smart City Guide – Architekturübersicht (Stand: 17.08.2025)

### Kontext & Ziel
- **Zweck**: iOS‑App (SwiftUI) zur smarten Multi‑Stop‑Fußgänger‑Routenplanung in Städten, basierend auf POI‑Discovery und TSP‑Optimierung.
- **Technik**: SwiftUI, MapKit, CoreLocation, Geoapify (ex HERE), Async/Await, @MainActor, Services als Singletons, Feature Flags.
- **Scope dieses Dokuments**: Überblick über Architektur, Datenflüsse, Navigation/UX, Stärken/Schwächen und konkrete Optimierungen mit Priorisierung.

### High‑Level Überblick
```mermaid
flowchart LR
  User((User))
  subgraph UI[SwiftUI Views]
    CV[ContentView (Root, Map, Sheets)]
    RPV[RoutePlanningView (Auto/Manuell)]
    ARS[ActiveRouteSheetView]
    PV[ProfileView (+ Unterseiten)]
  end

  subgraph Services[@MainActor Services]
    RS[RouteService]
    GEO[GeoapifyAPIService]
    LOC[LocationManagerService]
    CACHE[POICacheService]
    PROX[ProximityService]
  end

  subgraph Models[Models]
    RP[RoutePoint]
    GR[GeneratedRoute]
    PC[PlaceCategory]
    POI[POI]
  end

  User --> CV
  CV <-- push/sheet --> RPV
  CV <-- sheet --> ARS
  CV <-- push --> PV

  RPV --> RS
  CV --> RS
  RS --> GEO
  RS --> LOC
  GEO <--> CACHE
  RS -->|MKDirections| GR
  RS --> RP
  PROX --> LOC
  PROX -->|Benachrichtigungen| CV
  RS --> GR
  GR --> ARS
```

### Layering & Verantwortlichkeiten
- **Views (`ios/SmartCityGuide/Views/…`)**: Präsentation, Interaktion, State via `@State`/`@StateObject`. Beispiele: `ContentView`, `RoutePlanningView`, `ActiveRouteSheetView`, `ProfileView`.
- **Services (`ios/SmartCityGuide/Services/…`)**: Geschäftslogik, IO, Integrationen. Wichtig: `RouteService` (@MainActor), `GeoapifyAPIService` (Zugriff + Pinning), `POICacheService` (In‑Memory Cache), `LocationManagerService` (Permissions/Updates), `ProximityService` (Notifications/Proximity).
- **Models (`ios/SmartCityGuide/Models/…`)**: Domänenmodelle wie `RoutePoint`, `GeneratedRoute`, `PlaceCategory`, `POI`.
- **Utilities**: `FeatureFlags`, `RateLimiter`, `SecureLogger`, `NetworkSecurityManager`.

### Datenflüsse (vereinfacht)
1) User startet Planung in `ContentView` → `.sheet` zeigt `RoutePlanningView`.
2) `RoutePlanningView` sammelt Parameter → triggert `RouteService.generateRoute(…)`.
3) `RouteService` nutzt `GeoapifyAPIService` (POIs) + `MKDirections` (Wege) + Filter (Mindestabstand, Gehzeit) → `GeneratedRoute`.
4) `ContentView` setzt `activeRoute` → Darstellung auf Map + `ActiveRouteSheetView`.
5) `ProximityService` überwacht Position und triggert bei Annäherung Benachrichtigungen.

### Navigation & UX‑Flow
- Root: `ContentView` in `NavigationStack` (Map fullscreen, Toolbar/Statusbar hidden). Oben links Profil‑Button (`NavigationLink` → `ProfileView`).
- Planung: Start via `.sheet(isPresented:)` → `RoutePlanningView` (aktuell `NavigationView`).
- Aktive Route: `.sheet` mit `ActiveRouteSheetView` via `FeatureFlags.activeRouteBottomSheetEnabled`.
- Manuell vs. Automatisch: Modus‑Preset via NotificationCenter (`PresetPlanningMode`).

Empfohlene Zielarchitektur Navigation:
- Einheitlich `NavigationStack` + `navigationDestination` für Pushes.
- Ein zentrales Sheet‑Routing über `enum SheetDestination?` statt mehrerer `.sheet`‑Modifier.

### Stärken
- **Klare Service‑Trennung**: `RouteService` (@MainActor), `GeoapifyAPIService` (Pinning, Input‑Validierung), `POICacheService` (Filter/Scoring), `LocationManagerService` (async Permissions), `ProximityService` (Notifications).
- **Sicherheit/Robustheit**: Zertifikat‑Pinning, API‑Keys aus Plist, Eingabevalidierung, strukturierte Fehler.
- **UX‑Details**: Deutschsprachige, freundliche Texte, Accessibility‑IDs, konsistentes Map‑Overlay, Feature‑Flags.
- **Routing‑Logik**: Mindestabstand‑Filter, Gehzeit‑Validierung, einfache TSP‑Heuristik, geografische Verteilung.
- **Test‑Fundament**: UITest‑Flows vorhanden, IDs konsistent.

### Schwächen / Risiken
- **Mixed Navigation APIs**: `ContentView` nutzt `NavigationStack`, `RoutePlanningView` noch `NavigationView` → inkonsistentes Back‑Behavior, höhere Komplexität bei verschachtelten Präsentationen.
- **Mehrere `.sheet`‑Modifier** in `ContentView` (`RoutePlanningView` und `ActiveRouteSheetView`) und Re‑Präsentationslogik via `.onChange` → potenzielle Race‑Conditions/Jank.
- **State‑Ballung im Root**: Viele `@State` in `ContentView` (Route‑State, Quick‑Planning, Location Alerts). Fehlt ein dedizierter Coordinator/ViewModel.
- **Sequenzielle Routenberechnung**: `generateRoutesBetweenWaypoints` berechnet `MKDirections` strikt nacheinander → Latenz steigt mit Stopps.
- **Cache‑Key‑Granularität**: `POICacheService` cached nach Stadtname; bei Quick‑Planning (`"Mein Standort"`) kann derselbe Key trotz unterschiedlicher Koordinaten genutzt werden.
- **Volatile Cache**: In‑Memory ohne Persistenz; App‑Relaunch invalidiert Daten.
- **Kopplung via NotificationCenter**: Modus‑Preset aus `ContentView` zu `RoutePlanningView` per Notification → schwächer typisiert als Binding/Environment.

### Konkrete Optimierungen (priorisiert)
1) Navigation vereinheitlichen (hoch)
   - Migrire `RoutePlanningView` auf `NavigationStack` und nutze `navigationDestination` anstelle verschachtelter `NavigationLink`‑Fallbacks.
   - Ersetze mehrere `.sheet` durch eine zentrale `@State var presentedSheet: SheetDestination?` in `ContentView`:
     ```swift
     enum SheetDestination: Identifiable { case planning, activeRoute; var id: String { String(describing: self) } }
     ```
     → `.sheet(item: $presentedSheet) { switch $0 { case .planning: RoutePlanningView(…) case .activeRoute: ActiveRouteSheetView(…) } }`

2) Präsentations‑Koordination (hoch)
   - Entferne `.onChange` Re‑Open‑Logik. Stelle deterministisch sicher: Nach Schließen der Planung, wenn `activeRoute != nil`, setze `presentedSheet = .activeRoute` mit kleinem Dispatch.

3) Routen‑Performance (hoch)
   - Parallelisiere `MKDirections.calculate` in `RouteService.generateRoutesBetweenWaypoints` kontrolliert (z. B. max 2–3 gleichzeitige Tasks) und behalte `RateLimiter` bei.
   - Frühabbruch beibehalten, aber echte Laufzeit messen und loggen (bereits teilweise vorhanden via `SecureLogger`).

4) Cache‑Strategie (mittel)
   - Cache‑Key erweitern: Stadt‑basierte Abfragen → `city`; koordinaten‑basierte Abfragen → `city@lat,lon@radius`.
   - Disk‑Persistenz (z. B. JSON in `ApplicationSupport/Cache/pois.json`) + TTL; Startup‑Pruning für abgelaufene Einträge.

5) State‑Entkopplung (mittel)
   - `ContentView` verschlanken: Ein `HomeCoordinator` als `@StateObject` verwaltet `activeRoute`, `presentedSheet`, Quick‑Planning‑Status.
   - `RouteService` per DI in Views einspeisen (weiterhin @MainActor), History optional injizierbar.

6) UX‑Erweiterungen Active Route (mittel)
   - In `ActiveRouteSheetView` Fortschritt anzeigen (besuchte Stopps aus `ProximityService`) und Tap → `POIDetailView`.
   - Aktionen: „Zum nächsten Stopp navigieren“, „Stop überspringen“ (reordert Waypoints nur UI‑seitig).

7) Fehler‑Flows (mittel)
   - Einheitliche Fehlerdarstellungskomponente (Retry, Support‑Link) für Geoapify/MapKit/Location.

8) Tests (mittel)
   - UI‑Tests für: Sheet‑Koordination, Quick‑Planning ohne Location‑Permission, Active‑Route‑Fortschritt.
   - Snapshot‑Tests für `ActiveRouteSheetView` (collapsed/medium/large).

9) Feature‑Flags (niedrig)
   - Optional: Remote‑konfigurierbar machen (z. B. per JSON in `SecureStorageService`) für A/B‑Tests.

### Praktische Beispiele (Ausschnitte)
- Zentralisiertes Sheet‑Routing in `ContentView`:
  ```swift
  @State private var presentedSheet: SheetDestination?
  
  .sheet(item: $presentedSheet) { sheet in
    switch sheet {
    case .planning:
      RoutePlanningView(onRouteGenerated: { route in activeRoute = route; presentedSheet = .activeRoute })
    case .activeRoute:
      if let route = activeRoute { ActiveRouteSheetView(route: route, onEnd: { activeRoute = nil; presentedSheet = nil }, onAddStop: { /* open manual edit */ }) }
    }
  }
  ```

- Parallele Wegberechnung mit Limit:
  ```swift
  let semaphore = AsyncSemaphore(maxConcurrent: 3)
  await withThrowingTaskGroup(of: MKRoute.self) { group in
    for pair in pairs { await semaphore.acquire(); group.addTask { defer { semaphore.release() }; return try await calc(pair) } }
    for try await route in group { routes.append(route) }
  }
  ```

### Dateien/Komponenten (Referenzen)
- Root/App: `SmartCityGuideApp.swift`, `ContentView.swift`
- Planung: `Views/RoutePlanning/RoutePlanningView.swift`, `RouteBuilderView.swift`, `ManualRoutePlanningView.swift`
- Active Route: `Views/RoutePlanning/ActiveRouteSheetView.swift`
- Services: `Services/RouteService.swift`, `Services/GeoapifyAPIService.swift`, `Services/POICacheService.swift`, `Services/LocationManagerService.swift`, `Services/ProximityService.swift`
- Models: `Models/RouteModels.swift`, `Models/PlaceCategory.swift`, `Models/POI.swift`
- Utilities: `Utilities/FeatureFlags.swift`, `Utilities/RateLimiter.swift`

### Security & Privacy
- API‑Keys aus `APIKeys.plist` (nicht hardcodiert), Zertifikat‑Pinning, minimaler Logging‑Scope, Validierung von Nutzereingaben.
- Standort & Notifications: Klarer Permission‑Flow, Option für „Always“ nur für Background‑Proximity.

### Offene Punkte / Backlog
- Distanz‑Cache zwischen POIs für schnellere TSP‑Optimierung (Memoization).
- Offline‑Modus (zuletzt gecachte POIs/Route laden).
- Erweiterte Kategorien (Geoapify) mit stabilen Mappings und UI‑Filter.
- Konsistenter Use‑Case‑basierter Logger‑Kontext (Correlations‑ID pro Planung).

---
Diese Dokumentation ergänzt die bestehenden Spezifikationen unter `feature/` und die technischen Analysen in `CLAUDE.md`. Für neue, Nutzer‑sichtbare Features bitte die FAQs in `Views/Profile/HelpSupportView.swift` aktualisieren (siehe Projektregeln).


