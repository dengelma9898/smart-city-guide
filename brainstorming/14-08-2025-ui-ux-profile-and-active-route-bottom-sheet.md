## UI/UX Brainstorming – Profil-Navigation und aktive Route als Bottom Sheet

### Überblick & Ziele
- **Klarere Navigations-Hierarchie**: Profil als echte Seite mit Verlauf/Back-Button statt temporärem Overlay.
- **Bessere Karten-Erfahrung**: Banner ersetzen durch ein **draggables Bottom Sheet** mit Handle (Apple-Maps-Pattern), das zwischen kompakten und detaillierten Zuständen wechselt.
- **Wiederverwendbarkeit**: Inhalte aus `ios/SmartCityGuide/Views/RoutePlanning/RouteBuilderView.swift` in den Expanded-State übernehmen.

**TL;DR**
- **Profil**: Regulärer Push in den `NavigationStack`. **Alle Profil-Unterseiten strikt als Push** (wie in der iOS-App „Einstellungen“), keine Unterseite als Sheet. Nur kleine Quick-Actions (z. B. Profilbild ändern) als Sheet.
- **Aktive Route**: Banner ersetzen durch 3-stufiges **Bottom Sheet** (Collapsed/Medium/Large) mit Handle. „Tour beenden“/„Anpassen“ sind stets erreichbar.

### Profil
#### Aktueller Zustand
- Einstieg wirkt aktuell wie ein temporäres Overlay (Sheet) mit Swipe-to-Dismiss.
- Unterseiten existieren (`AGBView`, `DatenschutzerklaerungView`, `ProfileSettingsView`, Historie).

#### Beobachtungen/Probleme
- Erwartungshaltung: Nutzer kennen vom iOS-„Einstellungen“-Pattern eine **Push-Navigation** mit Back-Button.
- Sheets erschweren Deep Links und Navigations-Hierarchie.

#### Zielbild
- Profil als **reguläre Seite** im `NavigationStack` mit klarer Hierarchie.
- Unterseiten werden **immer** per Push geöffnet (kein Sheet für Unterseiten).

#### Entscheidung
- Strikter Push-Ansatz für Profil und alle Profil-Unterseiten.
- Sheets nur für **kleine Quick-Actions** (Avatar aufnehmen/auswählen) mit `.presentationDetents([.medium])`.

#### Umsetzung (High-Level)
- Avatar-Button → `NavigationLink` zu `ProfileView`.
- Unterseiten via `navigationDestination` – **keine Sheets** für Unterseiten.
- Optionales kleines Sheet nur für Mini-Aufgaben (z. B. Kameradialog für Avatar).

#### Risiken & Gegenmaßnahmen
- Längere Navigationsketten → Klare Titel/Back-Labels setzen.
- Modale Flows (z. B. Auth) sauber vom Profil trennen.

#### Tests/Abnahme
- UI-Tests: Push-Verhalten vorhanden, Back-Button sichtbar, Unterseiten nicht als Sheet präsentiert.
- Manuell: Verlauf prüfen, Deeplinks verifizieren.

### Map-Screen (Aktive Route)
#### Aktueller Zustand
- Unteres Banner verdeckt Karte, eingeschränkte Interaktion; wenige Zustände.

#### Zielbild
- **Draggables Bottom Sheet** mit Handle, 3 Zustände und progressiver Informationsdichte.
- Inhalte aus `RouteBuilderView` im Expanded-State wiederverwenden.

#### Zustände (Detents)
- **Collapsed (~90–120 pt)**: „Deine Tour läuft“, `Distanz • Zeit • Stopps`, Buttons: „Tour beenden“ (rot), „Anpassen“.
- **Medium (~40–60% Höhe)**: Kurzliste der Stopps, Mini-Segmente (Zeit/Distanz), CTA „+ Stopp“, „Anpassen“.
- **Large (fullscreen/large)**: Detaillierte Ansicht analog `RouteBuilderView` (Waypoints, WalkingRows, Wikipedia-Snippets, Optimierungs-CTA).

#### Interaktion
- Sichtbarer **Handle** (Grabber) oben; Drag wechselt Zustände.
- Tap auf kompakte Info → expandiert.
- Kein automatisches Schließen bei leichtem Herunterziehen (Fehlbedienungsschutz).

#### Technische Skizze (SwiftUI, iOS 17+)
- Container: neues `ActiveRouteSheetView` als Sheet über der Karte.
- Detents: `.presentationDetents([.height(100), .fraction(0.5), .large])`, `.presentationDragIndicator(.visible)`.
- State: `RouteService` (`@EnvironmentObject`) liefert Laufstatus, Distanzen, Zeiten, Stopps.
- Inhalte: Komponenten aus `RouteBuilderView` übernehmen.
- Gesten: Drag nur am Header/Handle; Map-Pan darunter priorisieren (`highPriorityGesture`).

#### Statusmaschine
- `collapsed | medium | expanded` (vom Detent abgeleitet).
- Start → collapsed; User-Drag/Tip → medium/expanded.
- Nach Re-Optimierung Zustand beibehalten (kein Auto-Kollaps).

#### Risiken & Gegenmaßnahmen
- Gesten-Konflikte mit Map → Drag-Zone klar, Schwellen sauber.
- Performance bei Bildern/Wikipedia → Lazy-Loading, Caching, Platzhalter.
- „Tour beenden“ versehentlich → Bestätigungsdialog oder Double-Tap.

#### Test- und Abnahmeplan
- UI-Tests (`ios/SmartCityGuideUITests/`):
  - Sichtbarkeit der Aktionen in allen Detents (`accessibilityIdentifier`).
  - Drag-Wechsel zwischen Detents; keine Kollision mit Map-Pan.
  - Beenden-Flow: Bestätigung, Cleanup via `RouteService`.
  - „Anpassen“/„+ Stopp“ öffnet Edit/Add korrekt.
- Manuelle Checks: iPhone 14–16, Dark/Light, Landscape; Wikipedia-Inhalte erst ab Medium/Large.

#### Inkrementelle Umsetzungsschritte
1. Banner entfernen, **Collapsed-Sheet** mit Handle (Feature-Parität).
2. **Medium-Detent** mit Kurzliste/CTAs.
3. **Large-Detent** mit `RouteBuilderView`-Sektionen.
4. Haptics, A11y, Feinheiten (Dim, Shadows), iPad/Multitasking.
5. UI-Tests erweitern, Stabilität sichern.

### Verweise (Design-Guidelines & Patterns)
- Apple Human Interface Guidelines – Modality & Navigation (Sheets vs. Push).
- Material Design – Bottom Sheets (persistent vs. modal, Zustände & Handles).
- Pattern-Inspiration: Apple Maps/Google Maps Bottom Sheet mit Handle.
- SwiftUI APIs: `presentationDetents`, `presentationDragIndicator` (iOS 16+), optional Libraries wie „UBottomSheet“.

### Offene Punkte
- Sollen Map-Taps das Sheet temporär kollabieren (Auto-Fokus auf Karte)?
- Live-Progress im Medium-State (aktueller/nächster Stopp)?
- „Tour beenden“: immer Dialog oder nur im Collapsed-Detent?

