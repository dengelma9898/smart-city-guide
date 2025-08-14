## Feature: Profil – Push-Navigation wie iOS "Einstellungen"

Quelle: `brainstorming/14-08-2025-ui-ux-profile-and-active-route-bottom-sheet.md` (Abschnitt „Profil“)

Ziel: Profil und alle Profil-Unterseiten werden als echte Pushes im `NavigationStack` dargestellt. Sheets werden nur für kleine Quick-Actions (z. B. Avatar ändern) verwendet.

### Phasenübersicht
1. Baseline & Navigation-Refactor (Push-Struktur herstellen)
2. UI/UX-Feinschliff (Titel, Back-Labels, A11y, State)
3. Quick-Actions via Sheet (nur kleine, reversible Tasks)
4. Tests & Verifikation (UI-Tests, manuelle Abnahme)

---

### Phase 1 – Baseline & Navigation-Refactor
Verifizierbares Ziel: Profil-Hauptseite und alle Unterseiten öffnen als **Push**, keine Unterseite als Sheet.

- [x] Audit: Identifizieren aller Eintrittspunkte ins Profil (Avatar-Button o. ä.).
- [x] Einstieg: `NavigationLink`/`navigationDestination` für `ProfileView` herstellen.
- [x] Unterseiten auflisten: `AGBView`, `DatenschutzerklaerungView`, `ProfileSettingsView`, `RouteHistoryView`, `RouteHistoryDetailView`.
- [x] Für jede Unterseite: Präsentation von Sheet → Push umstellen.
- [x] Entfernen/Deaktivieren aller `.sheet`-Präsentationen, die Unterseiten zeigen.
- [x] NavigationStack-Integrität prüfen: Kein Doppel-Push, keine Modaldopplungen.
- [x] Build läuft grün (MCP Build auf iPhone 16 Simulator).

Abnahme-Kriterien
- [ ] Jede genannte Unterseite öffnet sichtbar via Push mit Back-Button.
- [ ] Swipe-to-dismiss schließt keine Unterseite mehr.

---

### Phase 2 – UI/UX-Feinschliff
Verifizierbares Ziel: Konsistente Titel/Back-Labels, Accessibility und State-Verhalten.

- [x] Navigationstitel setzen: `ProfileView` und Unterseiten mit prägnanten Titeln.
 - [x] Back-Button-Label (falls abweichend sinnvoll), kürzen/lokalisieren.
- [x] A11y: `accessibilityIdentifier` für Haupt-Buttons/Listen/Screens ergänzt (`profile.*.screen`).
- [ ] Deeplink-Kompatibilität: Öffnen einer Unterseite via Push funktioniert (NavigationStack-Pfad).
- [x] Persistenz: Re-Entry ins Profil erhält den zuletzt aktiven Zustand nicht (immer frischer Einstieg) – sofern gewünscht.
- [ ] Design-Check: Spacing/Grouping konsistent zu iOS Einstellungen.

Abnahme-Kriterien
- [ ] VoiceOver liest Titel/Back-Button korrekt vor.
- [ ] Navigationsfluss ist konsistent (kein ungewollter Sheet-Style mehr).

---

### Phase 3 – Quick-Actions via Sheet
Verifizierbares Ziel: Nur kleine, reversible Aufgaben laufen als Sheet.

- [x] Avatar ändern: Kleines Sheet mit `.presentationDetents([.medium])` (Kamera/Album).
- [x] Bestätigungs-/Fehlerfälle: Saubere Dismiss-Logik, keine NavigationStack-Kopplung.
- [x] Keine Unterseite (AGB/DSGVO/Settings/History) nutzt Sheets.

Abnahme-Kriterien
- [x] Avatar-Flow funktioniert in Isolation; Zurück kehrt exakt zur Profilseite zurück.

---

### Phase 4 – Tests & Verifikation
Verifizierbares Ziel: Automatisierte UI-Absicherung + manuelle Checks.

- [ ] UI-Tests ergänzen/aktualisieren:
  - `Profile_DefaultName_Tests.swift` / `Profile_ChangeName_Tests.swift` – Navigationspfade prüfen.
  - Neue Tests: „Profil öffnet als Push“, „Unterseiten öffnen als Push“, „Avatar-Sheet erscheint separat“.
- [ ] Manuelle Checks: Dark/Light, iPhone 14–16, Rotation.
- [ ] MCP iOS Build (Simulator iPhone 16) grün.

Abnahme-Kriterien
- [ ] Alle UI-Tests grün.
- [ ] Manuelle Checkliste abgearbeitet.

---

### Notizen zur Implementierung
- NavigationStack zentral halten (Start in `SmartCityGuideApp`/`ContentView`).
- Keine doppelten Präsentationswege: Entweder `NavigationLink`/`navigationDestination` oder `.sheet` – nicht beides für die gleiche Route.
- Lokalisierung (de-de) für Titel/Labels beachten.

### Folge-Tasks (optional)
- Ein „Einstellungen“-ähnliches Gruppierungs-Layout (Sektionen, Beschriftungen) für `ProfileSettingsView`.
- Deeplink-Routen für bestimmte Profil-Unterseiten (z. B. `smartcity://profile/history`).


