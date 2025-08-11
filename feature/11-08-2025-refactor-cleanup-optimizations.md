## Refactor‑Plan: Code‑Cleanup, Optimierungen und iOS‑17.5+ Modernisierung

Dieser Plan ist für dich/uns als Implementierungsleitfaden optimiert. Er ist in klar überprüfbare Phasen gegliedert und referenziert das bereits erledigte Navigations‑Refactoring in `@11-08-2025-navigationstack-refactor.md`.

Ziel: Weniger Rauschen in Logs, konsequente Best Practices, Abbau von Deprecations/Warnings, bessere Stabilität der UI‑Tests, Nutzung verfügbarer iOS‑17.5+ Features – ohne Verhaltensänderung für User.

Hinweise zur Verifikation
- Alle Schritte mit sequentieller Testausführung prüfen (keine Parallel‑Clones):
  ```bash
  xcodebuild \
    -workspace ios/SmartCityGuide.xcodeproj/project.xcworkspace \
    -scheme SmartCityGuideUITests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Plus,OS=18.5' \
    -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 test
  ```
- Build‑Smoke mit mcp (optional): iOS‑App starten und UI beschreiben (siehe Projektregeln „MCP Verification“).
- Nach user‑sichtbaren Änderungen: FAQ in `HelpSupportView.swift` aktualisieren (Pflichtregel).

Voraussetzungen
- Bezug auf `@11-08-2025-navigationstack-refactor.md` (NavigationStack bereits aktiv).
- Ziel iOS ≥ 17.5 ist gesetzt (Projektvorgabe).

---

### Phase 0 – Basis‑Stabilität (nur Konfiguration)
- Sequentielle Tests als Standard für lokale Läufe dokumentieren (siehe Befehl oben).
- Simulator vor Läufen manuell öffnen/booten (vermeidet Clones). Optional per mcp.
- UITEST‑Environment: belassen; System‑Prompts werden in Tests abgefangen.

Verifikation
- Ein kompletter Testlauf: sollte ohne Simulator‑Klone starten, auch wenn einzelne Flows noch flaky sind.

---

### Phase 1 – Logging & Rauschen reduzieren
- Einheitliche Nutzung von `os.Logger` mit Kategorien; Debug‑Logs über `#if DEBUG`/`UITEST` bedingen.
- Entferne/abstuft: `print`/exzessive Logs in Services und Views, insbesondere während Routenberechnung.
- Sensitive Daten (API Keys) werden nicht geloggt; bestätigt durch Info.plist‑Konfiguration.

Akzeptanzkriterien
- Keine „Chatty“ Logs mehr bei normalen Flows; nur sinnvolle Info/Warn/Error.
- Build ohne neue Warnings.

Verifikation
- App lokal starten, eine automatische Route generieren; Xcode‑Console: keine Log‑Spams.

---

### Phase 2 – Deprecations/Best Practices (SwiftUI 17)
- `onChange(of:)` neue Signatur verwenden (aktuell warnt z. B. `LocationSearchField`):
  - Alt: `onChange(of: value, perform: old)` (deprecated)
  - Neu: `onChange(of: value) { old, new in ... }` oder `onChange(of: value) { new in ... }`
- `NavigationLink` deprecated Inits auf `navigationDestination` bzw. moderne `NavigationLink(value:)` migrieren, falls noch Altstellen bestehen (Referenz: NavigationStack‑Refactor‑Dokument).

Akzeptanzkriterien
- 0 Deprecation‑Warnings für betroffene Stellen.

Verifikation
- Build mit Xcode; Prüfen der Warnungs‑Panes und CLI‑Log: keine Deprecations mehr für die genannten APIs.

---

### Phase 3 – Accessibility & Testbarkeit konsolidieren
- Audit aller Chips/CTAs/Textfelder auf stabile `accessibilityIdentifier` (Pattern bereits in `ProfileSettingsView`, `HorizontalFilterChips`, `LocationSearchField`, `RouteBuilderView`).
- Einheitliche Benennungs‑Konvention: `section.option.value` (z. B. `Maximale Gehzeit.90min`).
- Für ausgewählte Chips zusätzlich `accessibilityValue = selected/not-selected` setzen (bereits begonnen in `HorizontalFilterChips`).

Akzeptanzkriterien
- Alle UI‑Elemente, die in Flows genutzt werden (1–4), sind per ID deterministisch adressierbar.

Verifikation
- Flow‑Tests 1–4 nacheinander ausführen; keine „not found“‑Fehler aufgrund fehlender IDs.

---

### Phase 4 – Leistungs‑/Nebenläufigkeits‑Feinschliff
- Services mit `@MainActor` für UI‑kritische Pfade bestätigen (RouteService, Edit‑Flows) und auf Cancellation achten:
  - Long‑running Tasks abbrechen, wenn der View verschwindet/State wechselt.
- Rate Limiting MapKit (0.2s) beibehalten; prüfen, ob `Task.sleep`/Debounce an zentraler Stelle kapselbar ist.
- Optional: Distanz‑Cache (geplant) als eigener Schritt dokumentieren, noch nicht implementieren.

Akzeptanzkriterien
- Keine sichtbaren Hänger/Spins in UI bei schnellen State‑Wechseln.

Verifikation
- Mehrfaches Start/Abbrechen in der Planung ohne Hänger; CPU‑Spitzen in Xcode Instruments unauffällig.

---

### Phase 5 – Warnings & Sauberkeit
- Alle aktuellen Warnings in folgenden Dateien beseitigen (Beispiele, Stand zuletzt):
  - `ManualRoutePlanningView.swift`: alte `NavigationLink`‑Init
  - `LocationSearchField.swift`: `onChange`‑Warnung
  - Services: nicht genutzte Variablen/try‑catch, die nichts werfen
- Unnötige Imports entfernen; `private` Sichtbarkeit dort, wo machbar.

Akzeptanzkriterien
- xcodebuild‑Build ohne Warnings (so weit realistisch, mindestens die genannten einsammeln).

Verifikation
- `Cmd+B` in Xcode bzw. `xcodebuild build` ohne neue Warnings.

---

### Phase 6 – Test‑Stabilisierung (Happy Path)
- Flow 1: Assertion akzeptiert ausgewählten Zustand per Trait oder `accessibilityValue` (eingebaut).
- Flow 4: Start‑Stadt setzen; Edit‑Button iterativ/hittable suchen; Overlay „Route wird erstellt…“ mit Wartefenster behandeln.
- Optional (später): UITEST‑Fast‑Path für Edit‑Recalc in `RouteEditService`, analog zu `ManualRouteService`.

Akzeptanzkriterien
- Alle vier Happy‑Path‑Flows bestehen lokal in Xcode; CLI sequentiell sollte stabil sein.

Verifikation
- Sequentieller `xcodebuild`‑Run; anschließend eine manuelle mcp‑Session zur Sichtprüfung (Builder‑Screen, Start‑CTA).

---

### Phase 7 – Aufräumen & Doku
- Entferne obsolet gewordene Fallback‑Pfade/Comments nach Stabilisierung.
- Aktualisiere FAQ in `HelpSupportView.swift` (Regel), wenn Nutzer‑sichtbare Texte/IDs hinzugekommen sind.
- Verweise in `docs/` ergänzen (kurzer Changelog der Refactor‑Phasen).

Akzeptanzkriterien
- Doku entspricht dem realen Stand; Entwickler können Flows anhand der IDs unmittelbar nachbauen.

Verifikation
- Kurzer manueller Check der FAQ/Docs in der App/Xcode.

---

### Checkliste „Done“
- [ ] Build ohne relevante Warnings/Deprecations
- [ ] Logs reduziert, konsistent, keine sensiblen Daten
- [ ] Alle Happy‑Path‑Flows grün (Xcode) und stabil im sequentiellen CLI‑Run
- [ ] FAQ/Docs aktualisiert; neue IDs dokumentiert


