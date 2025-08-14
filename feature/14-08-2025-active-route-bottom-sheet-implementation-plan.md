## Feature: Map – Aktive Route als 3-stufiges Bottom Sheet

Quelle: `brainstorming/14-08-2025-ui-ux-profile-and-active-route-bottom-sheet.md` (Abschnitt „Map-Screen (Aktive Route)“)

Ziel: Das bisherige untere Banner wird durch ein draggables Bottom Sheet mit drei Zuständen (Collapsed/Medium/Large) ersetzt. Inhalte im Large-Detent re-usen Abschnitte aus `RouteBuilderView`. Gesten priorisieren die Karte, alle Aktionen bleiben jederzeit zugänglich.

---

### Phasenübersicht
1. Baseline & Container-Setup (Collapsed-Detent, Feature-Parität)
2. Medium-Detent & Interaktionen (Kurzliste, CTAs, State-Verhalten)
3. Large-Detent & Content-Reuse (Abschnitte aus `RouteBuilderView`, Lazy Loading)
4. Gesten-Interop mit Map, Safety & Haptik
5. A11y, Visual Polish, Lokalisierung
6. State-Maschine & Persistenzverhalten
7. Tests & MCP-Verifikation (Pflicht)
8. FAQ-Update & Rollout-Strategie

---

### Phase 1 – Baseline & Container-Setup
Verifizierbares Ziel: Banner entfernt/deaktiviert; neues `ActiveRouteSheetView` erscheint als Sheet über der Karte mit Collapsed-Detent, Handle sichtbar, Kernaktionen erreichbar.

- [x] Neues View `ActiveRouteSheetView.swift` unter `ios/SmartCityGuide/Views/RoutePlanning/` anlegen
  - [x] Collapsed-Inhalte: `Distanz • Zeit • Stopps` + Button „Tour beenden“ (rot)
  - [x] `accessibilityIdentifier` setzen: `activeRoute.sheet.collapsed`, `activeRoute.action.end`
- [x] Präsentation in der Map-Ansicht (`ContentView`) integrieren
  - [x] `.sheet` mit `.presentationDetents([.height(84), .fraction(0.5), .large])`
  - [x] `.presentationDragIndicator(.visible)`
  - [x] `.interactiveDismissDisabled(true)` + `.presentationBackgroundInteraction(.enabled)`
- [x] Bestehendes Banner per Feature-Flag deaktiviert (Legacy-Fallback vorhanden)
- [x] „Tour beenden“ mit Bestätigungsdialog
- [x] MCP Build (iPhone 16 Simulator) grün

Abnahme-Kriterien
- [ ] Beim Start einer aktiven Route erscheint ein Sheet im Collapsed-Detent mit Handle
- [ ] Distanz/Zeit/Stopps werden korrekt angezeigt (Dummy ok, wenn Service noch nicht liefert)
- [ ] Buttons „Tour beenden“/„Anpassen“ sichtbar und tap-bar

---

### Phase 2 – Medium-Detent & Interaktionen
Verifizierbares Ziel: Medium-Detent (~50% Höhe) mit Kurzliste der Stopps, Mini-Segmenten, CTAs „+ Stopp“/„Anpassen“; State bleibt bei Re-Optimierung stabil.

- [x] `.presentationDetents` enthält `.fraction(0.5)`
- [x] Medium-Content (Basis): Kurzliste der nächsten Stopps (max. 6) + CTA „Stopp hinzufügen“ (Placeholder‑Action)
- [x] `accessibilityIdentifier`: `activeRoute.sheet.medium` (implizit über Struktur), `activeRoute.list.stops` (Liste), `activeRoute.action.addStop`
- [ ] Re-Optimierung/Neuberechnung via `RouteService` behält den aktuellen Detent bei (kein Auto-Kollaps)
- [x] Rate Limiting für MapKit bleibt unverändert (zentral)

Abnahme-Kriterien
- [ ] Drag von Collapsed → Medium funktioniert flüssig; Map-Pan kollidiert nicht
- [ ] Kurzliste und CTAs sind sichtbar, tappbar und korrekt beschriftet
- [ ] Nach Re-Optimierung bleibt der Medium-Detent erhalten

---

### Phase 3 – Large-Detent & Content-Reuse
Verifizierbares Ziel: Large-Detent übernimmt Abschnitte aus `RouteBuilderView` (Waypoints, WalkingRows, optionale Wikipedia-Snippets), performantes Lazy Loading.

- [ ] Reusable-Komponenten aus `RouteBuilderView` extrahieren nach `Views/Components/` sofern nötig
- [ ] Large-Content:
  - [ ] Detaillierte Waypoint-Abschnitte (gleiche visuelle Sprache wie im Builder)
  - [ ] WalkingRows mit Zeit/Distanz je Segment
  - [ ] Wikipedia-Snippets (erst ab Medium/Large laden), Placeholder & Caching via bestehendem `WikipediaService`
- [ ] `accessibilityIdentifier` ergänzen: `activeRoute.sheet.large`
- [ ] Performance: `LazyVStack`, asynchrone Bilder, Caching (`POICacheService`) nutzen

Abnahme-Kriterien
- [ ] Large-Detent zeigt umfangreiche, scrollbare Inhalte (Builder-Parität)
- [ ] Wikipedia/Inhalte werden erst in Medium/Large nachgeladen
- [ ] Kein Jank bei Scroll & Drag auf iPhone 14–16, Dark/Light ok

---

### Phase 4 – Gesten-Interop mit Map, Safety & Haptik
Verifizierbares Ziel: Drag-Gesten kollidieren nicht mit Map-Pan/Zoom; Beenden-Flow ist sicher; dezente Haptik verfeinert den Wechsel der Detents.

- [ ] Drag nur im Header/Handle aktivieren (`highPriorityGesture` auf Handle-Zone)
- [ ] Map-Pan/Zoom unter dem Sheet bleibt funktional (Hit-Testing korrekt)
- [ ] „Tour beenden“: Bestätigungsdialog (2-Step) mit klaren deutschen Texten
- [ ] Haptics: leichte Taps beim Wechsel der Detents (optional, iOS 17+)
- [ ] Edge-Cases: Minimale Drag-Distanz verhindert zufälliges Schließen

Abnahme-Kriterien
- [ ] Map-Interaktion fühlt sich natürlich an, kein versehentliches Sheet-Schließen
- [ ] Bestätigung verhindert unabsichtliches Beenden zuverlässig

---

### Phase 5 – A11y, Visual Polish, Lokalisierung
Verifizierbares Ziel: Vollständige Accessibility und UI-Feinschliff gemäß HIG.

- [ ] VoiceOver: sinnvolle Labels/Traits für Handle, Titel, Listen, CTAs
- [ ] Dynamische Schriftgrößen testen (Medium/Large)
- [ ] Schatten, Dimming der Karte unterhalb des Sheets ab Medium/Large (leicht)
- [ ] Deutsche UI-Texte im Stil des Projekts („Wir basteln deine Route!“ bleibt konsistent)
- [ ] Farben/Contrast prüfen (Light/Dark)

Abnahme-Kriterien
- [ ] VoiceOver liest Titel/Back korrekt; Fokus-Reihenfolge stimmig
- [ ] Keine abgeschnittenen Texte bei großen Schriftgrößen

---

### Phase 6 – State-Maschine & Persistenzverhalten
Verifizierbares Ziel: Klare Zustandsmaschine; Detent-Auswahl bleibt über Aktionen hinweg erhalten.

- [ ] Interner State: `collapsed | medium | expanded` (vom aktiven Detent abgeleitet)
- [ ] Start der Route → `collapsed`
- [ ] Aktionen („Anpassen“, Re-Optimierung, `+ Stopp`) verändern den Detent nicht automatisch
- [ ] Optionale Wiederherstellung des letzten Detents bei App-Resume (wenn sinnvoll)

Abnahme-Kriterien
- [ ] Detent bleibt stabil während typischer Edit/Add/Optimize-Flows

---

### Phase 7 – Tests & MCP-Verifikation (Pflicht)
Verifizierbares Ziel: UI-Absicherung und Simulator-Verifikation gemäß Projektregeln.

- [ ] UI-Tests unter `ios/SmartCityGuideUITests/` ergänzen/aktualisieren:
  - [ ] Sichtbarkeit der Aktionen in allen Detents via `accessibilityIdentifier`
  - [ ] Drag-Wechsel zwischen Detents; keine Kollisionen mit Map-Pan
  - [ ] Beenden-Flow: Bestätigungsdialog, Cleanup über `RouteService`
  - [ ] „Anpassen“/„+ Stopp“ öffnet Edit/Add korrekt
- [ ] MCP Build (iPhone 16 Simulator) erfolgreich
- [ ] UI-Verifikation: View-Hierarchie via MCP `describe_ui`; `activeRoute.*`-IDs vorhanden
- [ ] Screenshots (optional) Dark/Light, iPhone 14–16

Abnahme-Kriterien
- [ ] Alle UI-Tests grün
- [ ] MCP-Build grün; UI-Hierarchie zeigt erwartete Elemente

---

### Phase 8 – FAQ-Update & Rollout-Strategie
Verifizierbares Ziel: Nutzer-Doku aktuell; kontrollierter Rollout mit Feature Flag.

- [ ] `HelpSupportView.swift` aktualisieren (FAQ):
  - [ ] „Wie bediene ich das neue Routen-Sheet?“ (Detents, Handle, Aktionen)
  - [ ] „Wie beende ich eine Tour sicher?“ (Bestätigung)
  - [ ] „Warum sehe ich Wikipedia-Infos erst im erweiterten Sheet?“
- [ ] Feature Flag in `Utilities/FeatureFlags.swift` hinzufügen: `activeRouteBottomSheetEnabled`
  - [ ] Default: enabled; Möglichkeit für A/B oder schrittweisen Rollout

Abnahme-Kriterien
- [ ] FAQ-Einträge enthalten klare Erklärungen und deutsche UI-Texte
- [ ] Flag lässt sich einfach toggeln; kein Dead Code nach Rollout

---

### Notizen zur Implementierung
- SwiftUI, iOS 17+: `presentationDetents`, `presentationDragIndicator`
- Services: `RouteService` liefert Laufstatus, Wegpunkte, Zeiten, Distanzen; UI-Thread-Safety via `@MainActor`
- Caching: `POICacheService` und `WikipediaService` nutzen; Bilder verzögert laden
- Fehlerfälle: Sanfte Degradation bei API-Fehlern, freundliche deutsche Fehlermeldungen
- Architektur: `ActiveRouteSheetView` kapselt Inhalte und Zustandslogik; Komponenten aus `RouteBuilderView` maximal re-usen
- Sicherheit: Keine sensiblen Daten im Log; `SecureLogger` verwenden


