# UI-Testumgebung & erster User-Flow (XCUITest)

Kurz, schrittweise implementierbar und verifizierbar.

## Ziele
- UI-Flow-Tests mit XCUITest (kein Unit-Only).
- Page-Object-Pattern für wartbare Tests.
- Erster Flow: Profil öffnen → Namen ändern → speichern → neuer Name sichtbar.

## 0) Projektvorbereitung
1. Xcode: Prüfe, ob ein UI-Test-Target existiert. Falls nicht, anlegen:
   - Target: `SmartCityGuideUITests` (iOS UI Testing Bundle)
   - Scheme „SmartCityGuide“ enthält das UI-Test-Target.
2. TestPlan (optional jetzt, sonst später):
   - Datei `SmartCityGuide.xctestplan` erstellen, UI-Tests aktivieren.
3. Build verifizieren.

## 1) Test-Helfer (Common)
1. Lege im UI-Test-Target an: `Helpers/TestApp.swift`
   - Enthält `XCUIApplication`-Factory mit `launchArguments`, `launchEnvironment` (z. B. `UITEST=1`).
   - Kleine Warte-Helper (`waitForExists` auf `XCUIElement`).
2. Build verifizieren.

## 2) Page Objects
1. `Pages/ProfilePage.swift`:
   - Elemente: „Profil“ Tab/Eintrag, Name-Textfeld, Speichern-Button, Label mit sichtbarem Namen.
   - Methoden: `open()`, `setName(_:)`, `save()`, `visibleName() -> String`.
2. (Optional) `Pages/HomePage.swift` mit `openProfile()` wenn notwendig.
3. Build verifizieren.

## 3) Seed/Test-Daten
1. App im UI-Test-Modus mit einfachem lokalen Profil-Seed starten (z. B. Standardname „Max Mustermann“).
   - Per `launchEnvironment["UITEST"] = "1"` und im App-Code den Default-Usernamen überschreiben.
2. Build + Start (manuell) verifizieren.

## 4) Erster Flow-Test
1. Datei `Flows/Profile_ChangeName_Tests.swift`:
   - Arrange: App starten (UITEST-Flag), zur Profilseite öffnen.
   - Act: Namen in Textfeld ändern, Speichern tippen.
   - Assert: Sichtbarer Name wurde aktualisiert (Label/Text in Profil-Header).
2. Test laufen lassen (Xcode oder CLI), auf Grün warten.

## 5) Stabilität & Wartbarkeit
- Wartehilfen konsequent nutzen (`waitForExists` statt `sleep`).
- Accessibility-Identifiers für alle Elemente setzen (falls noch nicht vorhanden):
  - z. B. `profile.name.textfield`, `profile.save.button`, `profile.header.name.label`.
- Page-Objects sind die einzige Stelle mit Selektoren.

## 6) Snapshot/CI (ausgelagert)
Die Inhalte zu Snapshot-Tests und CI wurden ausgelagert nach `feature/11-08-2025-snapshot-ci-plan.md`.

## Verifikation je Schritt
- Nach jedem Abschnitt „Build verifizieren“ (Cmd+B oder MCP Build).
- Abschnitt 4: Test muss grün laufen.

## ToDos (konkret)
- [x] UI-Test-Target `SmartCityGuideUITests` anlegen (falls fehlt)
- [x] Helper `TestApp.swift`
- [x] Page `ProfilePage.swift`
- [x] Accessibility-IDs im App-Code setzen
- [x] Flow-Test `Profile_ChangeName_Tests.swift`
- [x] TestPlan (optional)
- [x] Snapshot/CI ausgelagert → `feature/11-08-2025-snapshot-ci-plan.md`

Hinweis: Falls beim Testlauf mehrere Simulator-"Clones" starten, liegt das an der Parallelisierung im TestPlan. Deaktivieren über Xcode TestPlan (Parallelisierung aus) oder via CLI `-parallel-testing-enabled NO`.

---
Quellen/Ideen: Page-Object-Pattern und Snapshot-Tests mit `swift-snapshot-testing` [/pointfreeco/swift-snapshot-testing].
