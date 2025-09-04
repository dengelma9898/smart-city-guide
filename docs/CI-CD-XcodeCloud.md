## CI/CD Setup: GitHub Actions (CI) + Xcode Cloud (CD)

Diese Doku beschreibt den kombinierten Ansatz aus CI in GitHub Actions und CD über Xcode Cloud für `SmartCityGuide`.

### CI (GitHub Actions)
- Workflow: `.github/workflows/ci.yml`
- Läuft auf PRs und Pushes auf allen Branches (für Testzwecke), schreibt Tags nach erfolgreichem Build.
- Jobs:
  - Xcode-Setup (16.2), SPM-Resolve, Build + Unit-Tests, optional UI-Tests, Artefakte-Upload (`.xcresult`, IPA).
- Tagging: Automatisches Tag-Schema `ci-<branch>-<yyyymmdd-hhmmss>-<sha>`; für Produktion kann die Bedingung auf `main` beschränkt werden (`if: github.ref == 'refs/heads/main'`).

### CD (Xcode Cloud)
1. In Xcode > Einstellungen > Accounts: Apple-ID/Team verbinden.
2. Im Projekt `ios/SmartCityGuide.xcodeproj` sicherstellen:
   - Scheme `SmartCityGuide` ist shared (unter `Manage Schemes…` aktivieren).
   - Bundle ID: `de.dengelma.smartcity-guide`.
   - Automatic Signing: aktiv.
3. Xcode Cloud aktivieren (Xcode oder App Store Connect):
   - Repository verbinden (GitHub).
   - Workflow anlegen: Trigger `Tag v*` oder Push auf `main`.
   - Actions: Build → Tests (optional) → Archive → Distribute to TestFlight.
   - Devices: z. B. `iPhone 16 (iOS 17.5)`.
4. Environment:
   - Keine Secrets nötig, wenn Automatic Signing genutzt wird (Zertifikate/Profiles verwaltet Xcode Cloud).

### Projektkonventionen (aus Repo-Rules)
- @MainActor bei UI-nahen Services, async/await, Rate Limiting, Fehlertoleranzen beachten.
- Pflicht-Checks vor Freigabe: Build- und UI-Ergebnisse prüfen (in CI durch Testpläne und Artefakte abgedeckt).
- Keine Commit-Automatik: Änderungen werden vorbereitet, Commits erfolgen nur manuell durch den User.

### Nächste Schritte
- Optional: Tag-Autocreate nur auf `main` aktivieren, sobald getestet.
- Optional: Separater `ui-tests`-Job ohne `continue-on-error` wenn Flakes behoben sind.

