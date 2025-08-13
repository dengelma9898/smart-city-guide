## RouteBuilder: Manuelles Hinzufügen und Löschen einzelner POIs

Dieser Plan beschreibt inkrementelle Phasen mit klar abhakbaren Aufgaben, die jeweils unabhängig getestet und freigegeben werden können. Fokus: Erweiterungen an `RouteBuilderView.swift` für manuelles Hinzufügen von bereits gefundenen POIs zur geplanten Route und das Löschen einzelner POIs aus der Route.

### Annahmen
- „POIs“ meint die Zwischenstopps zwischen Start und Ziel. Start/Ziel sind nicht löschbar.
- „Letzter POI“ meint: Es ist nur noch genau 1 Zwischenstopp vorhanden. Wird dieser entfernt, navigieren wir zurück zur Planungsansicht (Dismiss).
- Neue POIs kommen aus `discoveredPOIs` (bereits vom Geoapify-Load vorhanden); keine zusätzlichen Netzaufrufe nötig.
- Bei Einfügen wird zunächst ein einfacher, deterministischer Heuristik-Ansatz umgesetzt: Insert vor dem Ziel; optional kann später ein „Best Placement“-Heuristik ergänzt werden.
- Re-Routing nach Änderungen geschieht wie beim Ersetzen: MKDirections mit Rate-Limit 200ms.
- Beim Hinzufügen per Swipe bleibt das Sheet geöffnet; Nutzer kann mehrere POIs nacheinander hinzufügen.

### Nicht-Ziele (vorerst)
- Kein Re-Discovery neuer POIs außerhalb der bereits geladenen Stadt/Koordinaten.
- Kein Drag&Drop-Reordering der POIs (separates Feature).

---

### Phase 1: Technische Vorbereitungen und API der View
- [ ] UI-Flags/Status ergänzen, falls nötig (z. B. Sheet-State für „POI hinzufügen“)
- [ ] Öffentliche, klar benannte Methoden in `RouteBuilderView` für Insert/Delete:
  - [ ] `insertPOI(_ poi: POI, at index: Int?)` (Index optional → Default: vor Ziel einfügen)
  - [ ] `deletePOI(at index: Int)` (nur Zwischenstopps erlaubt)
- [ ] Re-Routing-Funktion wiederverwenden: `recalculateWalkingRoutes(for:)` (bereits vorhanden)
- [ ] Duplikate verhindern: `isAlreadyInRoute(_:)` nutzen/erweitern
- [ ] Fehlerbehandlung: Nutzerfreundliche Fehlermeldung wie beim Ersetzen

Verifikation (Build):
- [ ] Projekt baut erfolgreich für Simulator „iPhone 16“

---

### Phase 2: UI „POI hinzufügen“ (Swipe/Tinder-Style)
- [ ] Toolbar-Button „+“ anzeigen, wenn eine Route existiert: `navigationBarTrailing`
- [ ] Sheet präsentieren: „POI per Swipe auswählen“ (kein Suchfeld)
  - [ ] Kandidatenquelle: `discoveredPOIs` gefiltert auf „nicht bereits in Route“
  - [ ] Umsetzung mit bestehenden Komponenten: `SwipeCardStackView`/`SpotSwipeCardView` (wie in Edit-/Manuell-Flow)
  - [ ] Aktionen: Rechts-Swipe = „Hinzufügen“; Links-Swipe = „Überspringen“; Info-Button zeigt Detail (falls vorhanden)
  - [ ] On-Like → `insertPOI(_:at:)` ausführen, Karte aus dem Deck entfernen, Sheet bleibt geöffnet (Mehrfach-Hinzufügen möglich)
- [ ] Einfüge-Strategie v1: vor Ziel (Index: `route.waypoints.count - 1`)
- [ ] Re-Routing + Ladezustände analog „Ersetzen“
- [ ] Accessibility:
  - [ ] Add-Button: `accessibilityIdentifier("route.add-poi.button")`
  - [ ] Sheet: `accessibilityIdentifier("route.add-poi.sheet.swipe")`
  - [ ] Like/Skip Controls: `accessibilityIdentifier("route.add-poi.swipe.like")`, `accessibilityIdentifier("route.add-poi.swipe.skip")`

Verifikation (Funktion):
- [ ] UI-Elemente sichtbar, Sheet öffnet korrekt und bleibt beim Hinzufügen offen
- [ ] Rechts-Swipe (Like) fügt den POI hinzu; neuer Stopp erscheint zwischen letztem POI und Ziel; nächster Kandidat wird angezeigt

---

### Phase 3: UI „POI löschen“ (Einzelstopp)
- [ ] Swipe-Action „Löschen“ an `waypointRow` für Zwischenstopps (nicht Start/Ziel)
- [ ] Tap auf „Löschen“ → `deletePOI(at:)` → Re-Routing
- [ ] Spezialfall: Es ist nur noch 1 Zwischenstopp vorhanden → Löschen triggert `dismiss()` zurück zur Planung
- [ ] Accessibility:
  - [ ] Delete-Action: `accessibilityIdentifier("route.delete-poi.action.")` mit Index-Suffix

Verifikation (Funktion):
- [ ] Löschen eines beliebigen Zwischenstopps aktualisiert Route (Anzahl Stopps, Distanzen, Zeiten)
- [ ] Löschen des letzten Zwischenstopps navigiert zurück

---

### Phase 4: UX/Heuristik-Verbesserungen (Optional, separat abhakbar)
- [ ] „Best Placement“-Heuristik beim Insert: Evaluierung mehrerer Insert-Positionen und Wahl minimaler Mehrkosten
  - [ ] Hard-Limit (z. B. höchstens 4–5 Evaluierungen), 200ms Rate-Limit respektieren
- [ ] Mini-Loading-Indikator nur im betroffenen Bereich (lokaler Scope)

Verifikation:
- [ ] Messbar geringere zusätzliche Distanzzeit gegenüber „vor Ziel“-Heuristik bei einfachen Fällen

---

### Phase 5: FAQ & Texte, Logging, Stabilität
- [ ] `HelpSupportView.swift` um FAQ-Einträge erweitern:
  - [ ] „Wie füge ich neue Stopps zu meiner Tour hinzu?“
  - [ ] „Wie lösche ich einzelne Stopps?“ (inkl. Hinweis zum letzten Stopp → Navigation zurück)
- [ ] Deutsche UI-Texte: konsistent, freundlich, kurz
- [ ] Logging via `SecureLogger` (Info/Warning an sinnvollen Stellen)
- [ ] UI-Tests (happy path):
  - [ ] Add-Flow: Route generieren → „+“ → auswählen → neuer Stopp sichtbar
  - [ ] Delete-Flow: Route generieren → Zwischenstopp löschen → Liste aktualisiert
  - [ ] Last-POI-Delete: Bei einem Stopp → löschen → zurück in Planung

Verifikation (Build & Basic Run):
- [ ] Projekt baut erfolgreich
- [ ] Smoke-Test auf Simulator: UI-Elemente vorhanden, keine Crashes

---

### Technische Details (Umsetzungshinweise)
- Insert:
  - Erzeuge `RoutePoint(from: poi)` und füge in `generatedRoute.waypoints` an gewünschter Position ein.
  - Rufe `recalculateWalkingRoutes(for:)` auf, erstelle neue `GeneratedRoute` (wie beim Ersetzen) und setze `routeService.generatedRoute`.
  - Wikipedia-Enrichment erneut für betroffene Route starten: `enrichRouteWithWikipedia(route:)`.
- Delete:
  - Prüfe Index in `1..<(waypoints.count - 1)`.
  - Entferne Waypoint, re-kalkuliere Routen und Metriken identisch zur Replace-Logik.
  - Wenn dadurch keine Zwischenstopps mehr übrig sind → `dismiss()`.
- Deduplizierung:
  - Bereits vorhandene Route-POIs via `isAlreadyInRoute(_:)` ausschließen.
- States & UX:
  - Globale Ladezustände (`routeService.isGenerating`) wie beim Ersetzen verwenden; keine Flicker-Effekte.
  - Identifiers hinzufügen, damit UI-Tests robust sind.

---

### Akzeptanzkriterien (für jede Phase separat prüfbar)
- Phase 1: Builds ohne Fehler; keine UI-Regression.
- Phase 2: Nutzer kann über „+“ einen vorhandenen POI aus Liste auswählen; neuer Stopp erscheint vor dem Ziel; Re-Routing korrekt; keine Duplikate.
- Phase 3: Nutzer kann jeden Zwischenstopp löschen; Routenmetrik aktualisiert; Löschen des letzten Zwischenstopps führt zurück.
- Phase 4: Optionale Heuristik reduziert Mehrkosten beim Insert; keine spürbaren Hänger (Rate-Limit beachtet).
- Phase 5: FAQ-Einträge vorhanden; deutsche UI-Texte konsistent; Smoke-Tests grün.

---

### Hinweise auf vorhandene Dokumente
- Siehe `Route_Planning_Refactor_Plan.md` für Navigations-/Planungsfluss.
- Siehe `Route_Edit_Tinder_Implementation_Plan.md` für Austausch-/Alternativen-Logik (kann für Insert/Delete wiederverwendet werden).
- Siehe `current.md`/`CLAUDE.md` für Gesamtüberblick (falls vorhanden/aktuell).

---

### Rückfallstrategie
- Bei Fehlern im Insert/Delete Flow: Fallback zu „nur Ersetzen“ beibehalten; Feature-Flags können UI-Buttons ausblenden.


