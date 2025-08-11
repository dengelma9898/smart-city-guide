## Snapshot-Tests und CI-Plan für UI-Tests

Kurz und umsetzbar. Ausgelagert aus `test-implementations/10-08-2025-ui-test-env-and-first-flow.md`.

### Ziele
- Stabil visuelle Regressionen erkennen (Snapshots)
- Reproduzierbare, flake-arme CI-Läufe für UI-Tests

### Snapshot-Tests (später aktivieren)
- Bibliothek: pointfreeco `swift-snapshot-testing` (als SPM)
- Geräte/Presets: iPhone 16 (iOS 17.5+), Light/Dark Mode
- Determinismus:
  - Animations-Disable in Tests (`UIView.setAnimationsEnabled(false)`, SwiftUI: `withTransaction`/`CATransaction`), ggf. per `launchArgument("-UITEST_DISABLE_ANIMATIONS", "1")`
  - Feste Locale/Zeitzone: `de_DE`, `Europe/Berlin`
  - Feste Schriftgröße: `--ui_testing_content_size=medium`
  - Stabile Datenquellen: `launchEnvironment["UITEST"] = "1"` und Seeds (POIs, Profil)
- Naming: `<View>_<State>_<Appearance>.snap`
- Erste Kandidaten:
  - Profil-Header nach Save
  - Routenkarte mit Start (Polyline sichtbar)

### CI-Plan
- Ziel: Eine verlässliche Test-Pipeline für iOS Simulator „iPhone 16“
- Runner: Xcode Cloud oder selbstgehostet (Fastlane)
- Build/Test Befehle (Beispiel):
  - Lokal/CI (xcodebuild):
    - `xcodebuild test -scheme SmartCityGuide -destination 'platform=iOS Simulator,name=iPhone 16' -parallel-testing-enabled NO`
  - Vermeide parallele UI-Tests für Stabilität (TestPlan/CLI)
- Artefakte:
  - Speichere Screenshots/Snapshots und `xcresult`
  - Berichte in CI (JUnit/XCResultBundle)
- Flake-Reduktion:
  - Wartehilfen statt `sleep`, Retry bei transienten Netzwerkfehlern optional
  - Rate Limiting respektieren (MapKit/HERE); für CI bevorzugt Caching/Seeds

### Gating & Metriken
- PR-Gate: UI-Flow-Smoke muss grün sein
- Snapshots dienen als „Changes approved“ Signal bei UI-Änderungen

### Offene ToDos
- SPM-Abhängigkeit einführen (wenn Snapshots starten)
- TestPlan-Artefakt-Upload in CI verankern
- Snapshot-Baselines initialisieren und reviewen


