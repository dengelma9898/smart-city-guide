## Happy-Path UI-Testflows (XCUITest)

Optimiert für schnelle Umsetzung mit Page Objects und stabilen Selektoren. Zielgerät: iPhone 16 (iOS 17.5+).

### Voraussetzungen
- `Helpers/TestApp.swift` mit `launchEnvironment["UITEST"] = "1"`
- Deterministische Seeds im App-Code, wenn `UITEST == 1` (Profil-Defaults, POI-Cache)
- Accessibility Identifiers (falls fehlend, ergänzen):
  - Profil: `tab.profile`, `profile.name.textfield`, `profile.save.button`, `profile.header.name.label`, `profile.default.distance.picker`, `profile.default.categories.chips`
  - Planung: `tab.plan`, `route.city.textfield`, `route.mode.automatic.button`, `route.mode.manual.button`, `route.generate.button`, `route.start.button`, `route.edit.button`
  - Manuelle POI-Auswahl: `poi.select.card`, `poi.select.confirm.button`
  - Suche/Ersetzen: `poi.search.field`, `poi.search.result.cell.0`, `route.edit.replace-poi.button`
  - Map/Result: `route.summary.stops.label`, `map.polyline`

### Konventionen
- Page Objects sind einzige Selektor-Quelle (`Pages/…`) 
- Wartehilfen: `waitForExists(timeout:)` statt `sleep`
- Tests starten App mit `UITEST`

---

### Flow 1: Default-Settings wirken in der Planung
Ziel: Geänderte Defaults im Profil werden in der Routenplanung übernommen.

Schritte:
1. Öffne Profil (`tab.profile`)
2. Setze Distanzlimit (z. B. 15 km) über `profile.default.distance.picker`
3. Aktiviere Kategorien (z. B. `museum`, `park`) über `profile.default.categories.chips`
4. Speichere (`profile.save.button`) und verifiziere sichtbaren Namen bleibt gesetzt (`profile.header.name.label`)
5. Wechsle zu Planung (`tab.plan`)
6. Prüfe, dass Distanzlimit und Kategorien vorausgewählt sind

Assertions:
- Voreinstellungen in Planung entsprechen Profil-Defaults

---

### Flow 2: Automatische Routen-Erstellung und Start
Ziel: Route automatisch erzeugen, im Builder sehen und auf Karte starten.

Schritte:
1. Öffne Planung (`tab.plan`)
2. Setze Stadt ggf. aus Seed oder tippe in `route.city.textfield` (z. B. „Nürnberg“)
3. Wähle `route.mode.automatic.button`
4. Tippe `route.generate.button`
5. Warte auf Ergebnis: `route.summary.stops.label` vorhanden, > 0 Stops
6. Tippe `route.start.button`
7. Verifiziere Karte mit Polyline `map.polyline`

Assertions:
- Stops > 0, Start möglich, Polyline sichtbar

---

### Flow 3: Manuelle Routen-Erstellung und Start
Ziel: POIs manuell auswählen, Route erzeugen, starten.

Schritte:
1. Planung öffnen (`tab.plan`), Stadt setzen falls nötig
2. Wähle `route.mode.manual.button`
3. Wähle mehrere POIs über Karten/Stack (`poi.select.card`), bestätige (`poi.select.confirm.button`)
4. Tippe `route.generate.button`
5. Warte auf `route.summary.stops.label`, > 0
6. Tippe `route.start.button` und verifiziere `map.polyline`

Assertions:
- Ausgewählte POIs in Summary enthalten, Polyline sichtbar

---

### Flow 4: Einzelnen POI in geplanter Route ersetzen
Ziel: Automatisch erzeugte Route ändern, einen POI ersetzen und Route erneut starten.

Schritte:
1. Erzeuge Route wie in Flow 2 (bis Step 5)
2. Öffne Edit (`route.edit.button`)
3. Starte Ersetzen (`route.edit.replace-poi.button`) für einen Stop
4. Suche neuen POI (`poi.search.field`), wähle erstes Ergebnis (`poi.search.result.cell.0`)
5. Bestätige, erzeuge aktualisierte Route (`route.generate.button`)
6. Verifiziere Summary aktualisiert, tippe `route.start.button`, prüfe `map.polyline`

Assertions:
- Ersetzter Stop unterscheidet sich vom ursprünglichen, Start weiterhin möglich

---

### Optionale weitere Happy-Paths (später)
- Route in Verlauf gespeichert und aus `RouteHistoryView` erneut öffnen
- POI-Detail aus Route öffnen (`POIDetailView` sichtbar)

### Ausführung (Hinweise)
- Xcode: Testplan ohne Parallelisierung
- CLI (Beispiel):
  - `xcodebuild test -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' -parallel-testing-enabled NO`
- MCP: Projekt-Build vor Lauf prüfen (iPhone 16 Simulator)


