# Quick Route Planning – Drei Start-Buttons inkl. „Schnell“-Modus

## Kontext & Ziel
Aktuell gibt es auf dem Startbildschirm einen einzelnen großen Button, der zur `RoutePlanningView` führt. Wir möchten stattdessen drei klar verständliche, Daumen‑freundliche Primäraktionen direkt auf dem Startscreen:
- **Automatisch planen**: führt zur bestehenden `RoutePlanningView` mit Modus „automatic“.
- **Manuell auswählen**: führt zur bestehenden `RoutePlanningView` mit Modus „manual“.
- **Schnell planen**: startet sofort eine Routenplanung aus dem aktuellen Standort mit festen Parametern, zeigt nur einen Ladezustand und öffnet anschließend direkt die Karte mit der fertigen Route.

Best‑Practice‑Leitplanken (aus Mobile‑UX‑Richtlinien):
- **Klarheit & Konsistenz**: Primäraktionen deutlich benennen und mit eindeutigen Icons versehen; konsistente Bildsprache.
- **Touch‑freundliche Gestaltung**: Buttons groß genug, mit ausreichendem Abstand und in der „Thumb‑Zone“ positioniert.
- **Minimale, kontextuelle Navigation**: Der Schnell‑Button überspringt unnötige Zwischenschritte und visualisiert nur einen kurzen Ladezustand.

## Akzeptanzkriterien (High‑Level)
- Drei sichtbare Primäraktionen am Startscreen, klar beschriftet und mit Icons/Bildern.
- „Schnell planen“:
  - Start‑ und Endpunkt = aktueller Standort (Rundreise).
  - Max. POIs = 8.
  - Maximale Gehzeit = keine Begrenzung.
  - Mindestabstand zwischen POIs = kein Minimum.
  - Suchradius nur für Schnell‑Planung: 2000 m.
  - Keine `RoutePlanningView`/`RouteBuilderView` dazwischen – direktes Anzeigen/Starten der Route auf der Karte.
  - Ladeindikator mit freundlichem Text während der Planung.
- Fehlerfälle (keine Standortfreigabe, kein GPS‑Fix, keine POIs gefunden) werden freundlich und stabil behandelt.
- Barrierefreiheit: Labels, Hints, ausreichende Zielgröße, UI‑Tests.
- FAQ in `HelpSupportView.swift` ergänzen.

---

## Phase 1 – Branch & Aufräumen
- [x] Feature‑Branch `feature/quick-route-planning` erstellt.
- [x] Alte Notiz `feature/13-08-2025-route-priority-start-city.md` entfernt.
- [ ] Dieser Plan gemerged.

Verifikation: Branch existiert; Datei entfernt; Plan liegt in `feature/`.

---

## Phase 2 – UI‑Konzept Startscreen (3 Buttons)
Änderungspunkte: `ContentView.swift` (Startscreen mit Karte) bzw. Ort des heutigen „Los, planen wir!“-Buttons.

Tasks:
1. Drei Primäraktionen in einer vertikalen Gruppe im unteren Safe‑Area‑Bereich (Thumb‑Zone) platzieren.
   - Beschriftungen: „Automatisch“, „Manuell“, „Schnell“.
   - Icons/Images: `sparkles` (automatisch), `hand.point.up.left` (manuell), `bolt.circle` (schnell) – Platzhalter, optional durch Assets ersetzen.
   - States: Enabled immer, aber „Schnell“ fordert Standortrecht on‑demand an.
2. Accessibility: `accessibilityIdentifier` pro Button, klare Labels/Hints.
3. Visuelle Spezifikation: mind. 44×44pt hit area, 12–16pt vertikaler Abstand, adaptives Layout für kleine Geräte.

Verifikation: Sichtprüfung im Simulator, VoiceOver liest sinnvolle Labels; Buttons sind gut erreichbar.

---

## Phase 3 – Navigation & Wiring
Tasks:
1. Button „Automatisch“ öffnet `RoutePlanningView` mit `planningMode = .automatic` (bestehende Logik bleibt).
2. Button „Manuell“ öffnet `RoutePlanningView` mit `planningMode = .manual` (bestehende Logik bleibt).
3. Button „Schnell“ startet neuen Quick‑Flow (siehe Phase 4) ohne Navigationssprung.

Verifikation: Tippen auf die Buttons führt reproduzierbar in die jeweiligen Flows (bzw. startet Quick‑Flow).

---

## Phase 4 – Quick‑Planning Flow (ohne Zwischenansichten)
Änderungspunkte: `Services/RouteService.swift`, `Services/LocationManagerService.swift`, Startscreen‑View (Overlay/Loader), optional `Utilities/`.

Ziel: Direkt aus dem Startscreen eine Route erzeugen und starten.

Feste Parameter:
- Start = aktueller Standort; Endpunkt = Start (Rundreise).
- `maximumStops = 5`.
- `maximumWalkingTime = nil` (keine Begrenzung; Service berücksichtigt nur, wenn Wert vorhanden ist).
- `minimumPOIDistance = .none` (0 m; ggf. neue Enum‑Ausprägung).

Tasks:
1. Standort holen:
   - Wenn nicht autorisiert → On‑Demand Anfrage; bei Ablehnung: freundlicher Alert + Option, normale Planung zu öffnen.
   - Wenn kein Fix verfügbar → kurzer Retry (z. B. 1–2 s); danach Fallback‑Hinweis.
2. POIs laden (Geoapify): `fetchPOIs(at: currentCoordinate, cityName: nil, categories: PlaceCategory.geoapifyEssentialCategories)`.
3. Service‑API ergänzen:
   - Neue Methode in `RouteService`: `generateRoute(fromCurrentLocation:maximumStops:endpointOption:customEndpoint:maximumWalkingTime:minimumPOIDistance:availablePOIs:)` existiert bereits für Current‑Location – nutzen.
   - „Unbegrenzt“: Parameter `maximumWalkingTime: MaximumWalkingTime?` (optional) – wenn `nil`, keine Gehzeit‑Reduktion anwenden.
   - `MinimumPOIDistance` um `.none` erweitern (0 m) – Validierung anpassen.
4. UI‑Overlay:
   - Halbtransparenter Hintergrund + `ProgressView` + Text „Wir basteln deine Route!“.
   - Sperrt Interaktion während Quick‑Flow.
5. Erfolg:
   - Route direkt an die Map‑Ansicht übergeben (wie heute `onRouteGenerated(GeneratedRoute)`), `ProximityService` starten.
6. Fehlerbehandlung:
   - Freundliche Alerts (Deutsch), Logging via `SecureLogger`.

Verifikation: Schnell‑Button erzeugt ohne weitere Screens eine Route und zeigt sie direkt auf der Karte; bei Fehlern erscheinen verständliche Hinweise.

---

## Phase 5 – Datenmodelle & Enums
Tasks:
1. `MaximumWalkingTime` auf optional im Quick‑Flow verwenden (Service: only‑if‑let).
2. `MinimumPOIDistance` um Wert `.none` (0 m) ergänzen; Mapping zu Metern prüfen.
3. Keine Änderungen an gespeicherten Profile‑Defaults nötig.

Verifikation: Kompiliert; Quick‑Flow übergibt `nil` bzw. `.none` ohne Crashes; Unit‑Checks der Umrechnung.

---

## Phase 6 – Telemetrie & Logging
Tasks:
1. UI‑Click‑Events für alle drei Start‑Buttons loggen.
2. Quick‑Flow: Dauer für „POI‑Fetch“, „TSP‑Optimierung“, „Gesamtzeit“ loggen.
3. Fehlerfälle mit Kategorie `.error` versehen; keine sensiblen Daten loggen.

Verifikation: Logs im Xcode‑Konsolen‑Output sichtbar; keine PII.

---

## Phase 7 – Barrierefreiheit & Texte
Tasks:
1. Deutsche, freundliche UI‑Texte (Style beibehalten: „Wir basteln deine Route!“).
2. Accessibility‑Labels/Hints für Start‑Buttons und Loader.
3. Dynamische Schriftgrößen testen.

Verifikation: VoiceOver‑Durchlauf; große Schrift skaliert ohne Layout‑Brüche.

---

## Phase 8 – FAQ & Hilfe aktualisieren
Änderungspunkt: `Views/Profile/HelpSupportView.swift`.

Tasks:
1. Neuer FAQ‑Eintrag: „Was ist Schnell‑Planung?“ mit kurzer Erklärung (Rundreise vom aktuellen Standort, bis zu 8 Orte, Suchradius 2000 m nur für diesen Modus, „Open End“ Gehzeit, kein Mindestabstand, sofortige Karte).
2. Hinweis zu Standortfreigabe.

Verifikation: Eintrag sichtbar; Rechtschreibung; Links/Text stimmen.

---

## Phase 9 – Tests & MCP‑Verifikation
Tasks:
1. Build‑Verifikation (iPhone 16) via Xcode MCP.
2. UI‑Tests:
   - Neuer Flow `Route_Quick_Generate_And_Start_Tests`:
     - Tappe „Schnell“ → Ladeoverlay sichtbar → Karte zeigt Route; keine `RoutePlanningView`/`RouteBuilderView` wird präsentiert.
     - Fehlerpfad ohne Standortrecht: Alert erscheint, Test quittiert.
3. Bestehende Flows nicht brechen (Regression: Automatisch/Manuell unverändert).

Verifikation: Grüner Build; UI‑Tests grün; manuelle Sichtprüfung.

---

## Phase 10 – Rollout & Toggle (optional)
Tasks:
1. Optionales Feature‑Flag `QuickRoutePlanningEnabled` (Default: an).
2. Analytics‑Vergleich: Klick‑Raten der drei Buttons.

Verifikation: Flag aus/anmachbar; Metriken erfassbar.

---

## Technische Notizen (Kurzreferenz)
- Startscreen: vorhandene CTA ersetzen durch V‑Stack aus drei Buttons im unteren Bereich; identische Breiten, klare Hierarchie.
- Quick‑Flow nutzt vorhandene Services (`LocationManagerService`, `GeoapifyAPIService`, `RouteService`, `ProximityService`, `SecureLogger`).
- Keine Vorschau‑Liste: `RouteBuilderView` wird für Quick‑Flow nicht verwendet.
- Wikipedia‑Enrichment kann wie heute asynchron im Hintergrund nachgezogen werden, aber der Flow blockiert nicht.

## Datei‑Touchliste (geplant)
- `ios/SmartCityGuide/ContentView.swift` (oder Startscreen‑View mit Map): UI‑Buttons, Overlay, Quick‑Trigger.
- `ios/SmartCityGuide/Services/RouteService.swift`: Optional‑Parameter für `maximumWalkingTime`; Handling `.none`‑Distance.
- `ios/SmartCityGuide/Models/RouteModels.swift` (falls Enum‑Erweiterungen nötig: `MaximumWalkingTime?`, `MinimumPOIDistance.none`).
- `ios/SmartCityGuide/Views/Profile/HelpSupportView.swift`: FAQ‑Update.
- `ios/SmartCityGuideUITests/Route_Quick_Generate_And_Start_Tests.swift`: neuer UI‑Test.

## Nicht‑Ziele (Out of Scope)
- Erweiterte TSP‑Algorithmen, Fahrradrouten, Offline‑Speicher – bleiben wie geplant „Future Work“.

---

## Checkliste (Kurz)
- [ ] Phase 2 UI fertig
- [ ] Phase 3 Navigation
- [ ] Phase 4 Quick‑Flow Implementierung
- [ ] Phase 5 Enums/Service‑Anpassungen
- [ ] Phase 6 Logging
- [ ] Phase 7 A11y/Texte
- [ ] Phase 8 FAQ
- [ ] Phase 9 Tests + MCP‑Build
- [ ] Phase 10 Flag (optional)

---
