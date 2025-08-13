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
- [x] UI-Flags/Status ergänzen, falls nötig (z. B. Sheet-State für „POI hinzufügen“)
- [x] Öffentliche, klar benannte Methoden in `RouteBuilderView` für Insert/Delete:
  - [x] `insertPOI(_ poi: POI, at index: Int?)` (Index optional → Default: vor Ziel einfügen)
  - [x] `deletePOI(at index: Int)` (nur Zwischenstopps erlaubt)
- [x] Re-Routing-Funktion wiederverwenden: `recalculateWalkingRoutes(for:)` (bereits vorhanden)
- [x] Duplikate verhindern: `isAlreadyInRoute(_:)` nutzen/erweitern
- [x] Fehlerbehandlung: Nutzerfreundliche Fehlermeldung wie beim Ersetzen

Verifikation (Build):
- [x] Projekt baut erfolgreich für Simulator „iPhone 16“

---

### Phase 2: UI „POI hinzufügen“ (Swipe/Tinder-Style)
- [x] Toolbar-Button „+“ anzeigen, wenn eine Route existiert: `navigationBarTrailing`
- [x] Sheet präsentieren: „POI per Swipe auswählen“ (kein Suchfeld)
  - [x] Kandidatenquelle: `discoveredPOIs` gefiltert auf „nicht bereits in Route“
  - [x] Umsetzung mit bestehenden Komponenten: `SwipeCardStackView`/`SpotSwipeCardView` (wie in Edit-/Manuell-Flow)
  - [x] Aktionen: Rechts-Swipe = „Hinzufügen“; Links-Swipe = „Überspringen“; Info-Button zeigt Detail (falls vorhanden)
  - [x] On-Like → Karte entfernen, Auswahl sammeln; Sheet bleibt geöffnet (Mehrfach-Hinzufügen möglich)
- [x] Einfüge-Strategie v1: vor Ziel (intern ersetzt durch vollständige Optimierung)
- [x] CTA „Jetzt optimieren“ triggert vollständige Reoptimierung (TSP-light) via `generateManualRoute`
- [x] Accessibility:
  - [x] Add-Button: `accessibilityIdentifier("route.add-poi.button")`
  - [x] Sheet: `accessibilityIdentifier("route.add-poi.sheet.swipe")`
  - [x] Like/Skip Controls: `accessibilityIdentifier("route.add-poi.swipe.like")`, `accessibilityIdentifier("route.add-poi.swipe.skip")`
  - [x] CTA: `accessibilityIdentifier("route.add-poi.cta.optimize")`

Verifikation (Funktion):
- [ ] UI-Elemente sichtbar, Sheet öffnet korrekt und bleibt beim Hinzufügen offen
- [ ] Rechts-Swipe (Like) fügt den POI hinzu; neuer Stopp erscheint zwischen letztem POI und Ziel; nächster Kandidat wird angezeigt

---

### Phase 3: UI „POI löschen“ (Einzelstopp)
- [x] Swipe-Action „Löschen“ an `waypointRow` für Zwischenstopps (nicht Start/Ziel)
- [x] Tap auf „Löschen“ → `deletePOI(at:)` → Re-Routing
- [x] Spezialfall: Es ist nur noch 1 Zwischenstopp vorhanden → Löschen triggert `dismiss()` zurück zur Planung
- [x] Accessibility:
  - [x] Delete-Action: `accessibilityIdentifier("route.delete-poi.action.")` mit Index-Suffix

Verifikation (Funktion):
- [ ] Löschen eines beliebigen Zwischenstopps aktualisiert Route (Anzahl Stopps, Distanzen, Zeiten)
- [ ] Löschen des letzten Zwischenstopps navigiert zurück

---

### Future Features (verschoben aus Phase 4)
- „Best Placement“-Heuristik beim Insert mit Evaluierung mehrerer Insert-Positionen (Rate-Limit beachten)
- Mini-Loading-Indikator nur im betroffenen Bereich (lokaler Scope)

---

### Phase 5: FAQ & Texte, Logging, Stabilität
- [x] `HelpSupportView.swift` um FAQ-Einträge erweitern:
  - [x] „Wie füge ich neue Stopps zu meiner Tour hinzu?“
  - [x] „Wie lösche ich einzelne Stopps?“ (inkl. Hinweis zum letzten Stopp → Navigation zurück)
- [ ] Deutsche UI-Texte: konsistent, freundlich, kurz
- [ ] Logging via `SecureLogger` (Info/Warning an sinnvollen Stellen)
- [ ] UI-Tests (happy path):
  - [ ] Add-Flow: Route generieren → „+“ → auswählen → neuer Stopp sichtbar
  - [ ] Delete-Flow: Route generieren → Zwischenstopp löschen → Liste aktualisiert
  - [ ] Last-POI-Delete: Bei einem Stopp → löschen → zurück in Planung

Verifikation (Build & Basic Run):
- [x] Projekt baut erfolgreich
- [ ] Smoke-Test auf Simulator: UI-Elemente vorhanden, keine Crashes

#### Manuelle Testschritte (UI-Schnellcheck)
- [ ] Profil → Hilfe & Support öffnen, Suchfeld sichtbar
- [ ] Kategorie „Routenplanung“ expandieren
- [ ] FAQ „Wie füge ich neue Stopps zu meiner Route hinzu?“ öffnen, Text zu Swipe + „Jetzt optimieren“ sichtbar
- [ ] FAQ „Wie lösche ich einzelne Stopps?“ öffnen, Hinweis zum letzten Stopp (zurück zur Planung) sichtbar

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


