## CI/CD Setup: GitHub Actions (CI) + Xcode Cloud (CD)

Diese Doku beschreibt den kombinierten Ansatz aus CI in GitHub Actions und CD über Xcode Cloud für `SmartCityGuide`.

### CI (GitHub Actions)
- Workflow: `.github/workflows/ci.yml`
- Läuft auf PRs und Pushes (aktuell auf allen Branches zum Testen), erstellt Auto-Tags nach erfolgreichem Build.
- Schritte: Xcode-Setup (16.2), SPM-Resolve, Build + Unit-Tests, optional UI-Tests, Artefakt-Upload (`.xcresult`).
- Tipp: Nach dem Test die Auto-Tag-Bedingung auf `main` einschränken.

### CD (Xcode Cloud) – Clean Flow ohne Skripte
1. In Xcode > Einstellungen > Accounts: Apple-ID/Team verbinden.
2. Projektvoraussetzungen:
   - Scheme `SmartCityGuide` ist shared.
   - Bundle ID: `de.dengelma.smartcity-guide`.
   - Automatic Signing aktiv.
3. Xcode Cloud Workflow anlegen (keine Pre-/Post-Skripte):
   - Trigger: Push auf `main` oder Tag `v*`.
   - Build – iOS: Aktion „Build“ (Simulator oder Generic iOS Device). Keine zusätzlichen Skripte.
   - Archive – iOS: Aktion „Archive“ mit Distribution → TestFlight.
   - Devices: z. B. `iPhone 16 (iOS 17.5)` (nur für Build/Tests relevant; Archive nutzt Generic Device).
4. Secrets/Environment:
   - Für Geoapify: Build Setting/Environment `GEOAPIFY_API_KEY` setzen (wird in `Info.plist` injiziert).

### Projektkonventionen (aus Repo-Rules)
- @MainActor bei UI-nahen Services, async/await, Rate Limiting, Fehlertoleranzen beachten.
- Pflicht-Checks vor Freigabe: Build- und UI-Ergebnisse prüfen (in CI durch Testpläne und Artefakte abgedeckt).
- Keine Commit-Automatik: Änderungen werden vorbereitet, Commits erfolgen nur manuell durch den User.

### Nächste Schritte
- Optional: Tag-Autocreate nur auf `main` aktivieren, sobald getestet.
- Optional: Separater `ui-tests`-Job ohne `continue-on-error` wenn Flakes behoben sind.

