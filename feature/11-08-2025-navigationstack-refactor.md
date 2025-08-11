## Refactor: Wechsel von NavigationView zu NavigationStack

### Kontext
- Zielbild: Stabilere, deterministische Navigation in SwiftUI für iOS 17+.
- Problem: In `ManualRoutePlanningView` traten sporadische Präsentations-Races bei der Anzeige des `RouteBuilderView` auf (fullScreenCover vs. gleichzeitige State-Änderungen). Zudem ist die bisherige API `NavigationView` veraltet und liefert u. U. weniger vorhersagbares Navigationsverhalten in verschachtelten Präsentationsfällen.

### Änderung
- `ManualRoutePlanningView` wurde von `NavigationView` → `NavigationStack` migriert.
- Zusätzlich wurde ein versteckter `NavigationLink` als deterministischer Push‑Fallback eingeführt, um den `RouteBuilderView` sicher anzuzeigen (neben item‑basiertem und boolschem fullScreenCover). Der bestehende Nutzer‑Flow bleibt unverändert.

### Warum ist das besser?
- `NavigationStack` ist der moderne Nachfolger von `NavigationView` und bietet robustere Zustandsverwaltung, besonders bei programmgesteuerten Pushes.
- Der Push‑Fallback vermeidet Race Conditions zwischen mehreren Präsentationswegen (Cover vs. gleichzeitige State‑Updates) und erhöht die Test‑Stabilität.
- In Kombination mit einem Completion‑Anker und klaren Accessibility‑IDs wird die UI für XCUITests zuverlässiger erkennbar.

### Betroffene Bereiche
- `ios/SmartCityGuide/Views/RoutePlanning/ManualRoutePlanningView.swift`
  - Container: `NavigationView` → `NavigationStack`
  - Versteckter `NavigationLink` als Fallback‑Push
  - Beibehaltener Flow (POI‑Auswahl → Route erstellen → Builder)

### Kompatibilität
- iOS 17.5+ (Projektziel): `NavigationStack` ist vollständig unterstützt.

### Risiken / Mitigation
- Potenziell neue Warnungen bei älteren Initializern von `NavigationLink`; mitigiert durch spätere Umstellung auf `navigationDestination` im nächsten Schritt.
- Präsentationslogik wurde explizit mit drei redundanten Pfaden abgesichert (item‑cover, bool‑cover, push).


