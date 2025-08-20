# Single-Sheet Route Flow: Direkter Karten-Preview + einheitliches Aktives-Routen-Sheet

## Motivation
Aktuell entsteht eine Sheet-über-Sheet-Situation: Nach der manuellen Planung wird die generierte Route in einem zweiten Sheet gezeigt; beim Start der Route erscheint ein weiteres Sheet für die aktive Route. Das widerspricht den HIG-Empfehlungen (nur ein Sheet gleichzeitig) und erzeugt potenziell verwirrende Modal-Stacks.

Ziel ist ein klarer, einheitlicher Flow: Nach der Generierung wird das Planungssheet geschlossen und die Route direkt auf der Karte angezeigt. Es existiert nur ein einziges Sheet für die aktive Route, in dem auch das Editieren/Hinzufügen von POIs stattfindet.

## Ziele
- Nur ein Sheet gleichzeitig (HIG-konform; bessere UX).
- Sofortige Sichtbarkeit der generierten Route auf der Hauptkarte (kein Zwischensheet).
- Ein einheitliches „Aktive Route“-Sheet als einziger Modal-Container für:
  - Vorschau/Details der generierten Route
  - Editieren/Hinzufügen/Löschen von POIs
  - Start/Stop der aktiven Route
  - Wikipedia/Infos, falls relevant
- Nahtlose Transition: Planung → Schließen → Route auf Karte + Aktive-Route-Sheet

## Nicht-Ziele
- Kein Redesign der manuellen Planungsschritte selbst (UI bleibt inhaltlich gleich).
- Keine Änderung der TSP-/Routenlogik in `RouteService`.

## UX-Flow (High-Level)
1. Nutzer startet die manuelle Planung → Planung erfolgt (Sheet A: `RoutePlanningView`).
2. Nutzer löst „Route generieren“ aus → `RouteService` erzeugt `GeneratedRoute`.
3. Sheet A wird geschlossen.
4. Hauptkarte (`ContentMapView`) zeigt sofort die generierte Route (Overlays/Annotations).
5. Ein einziges Sheet B („Aktive Route“) wird geöffnet (`EnhancedActiveRouteSheetView`):
   - Tabs/Abschnitte: Vorschau, Bearbeiten (POIs hinzufügen/entfernen), Wikipedia/Details.
   - Aktion „Route starten“ wechselt in aktiven Modus, bleibt im gleichen Sheet.
6. Während die Route aktiv ist, bleibt nur Sheet B im Einsatz (keine zusätzlichen Sheets).

## State-Machine und Präsentation
Zentralisierung im `HomeCoordinator` (oder `ContentView`) mit einem einzigen Sheet-State:

```swift
enum PresentedSheet: Identifiable, Equatable {
    case planning
    case activeRoute(GeneratedRoute)

    var id: String {
        switch self {
        case .planning: return "planning"
        case .activeRoute: return "activeRoute"
        }
    }
}

// Pseudocode im Coordinator/Root-View
@State private var presentedSheet: PresentedSheet?

.sheet(item: $presentedSheet) { sheet in
    switch sheet {
    case .planning:
        RoutePlanningView(onGenerated: { route in
            // 1) Planungssheet schließen
            presentedSheet = nil
            // 2) Route sofort auf Karte anzeigen (via shared state)
            // 3) Danach einziges Aktive-Route-Sheet öffnen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                presentedSheet = .activeRoute(route)
            }
        })
    case .activeRoute(let route):
        EnhancedActiveRouteSheetView(route: route, onClose: {
            presentedSheet = nil
        })
    }
}
```

Hinweise:
- Die Karte liest den aktuellen `GeneratedRoute`-State aus einem zentralen Store/Service (`RouteService` bzw. ViewModel), sodass die Route unmittelbar sichtbar ist, unabhängig vom Sheet.
- Die minimale Verzögerung beim Umschalten (≈150 ms) verhindert Präsentationskonflikte.

## Technische Änderungen
1. `HomeCoordinator.swift`/`ContentView.swift`:
   - Ein einziger `.sheet(item:)`-Presenter mit `PresentedSheet`.
   - Transitionslogik: Planung → `nil` → aktives Routen-Sheet.
2. `RoutePlanningView`:
   - Exponiert `onGenerated: (GeneratedRoute) -> Void`.
   - Entfernt direkte Selbst-Präsentation eines zweiten Sheets.
3. Kartenintegration (`ContentMapView`):
   - Liest den aktuell generierten/aktiven `GeneratedRoute` aus Shared State (z. B. `@EnvironmentObject`/`@StateObject`), um die Route sofort darzustellen.
4. Aktive Route Sheet (`EnhancedActiveRouteSheetView`):
   - Einziger Modal-Ort für Vorschau, Start, Bearbeitung (Add/Delete POIs), Wiki-Anreicherung.
   - Nutzung bestehender Services: `RouteEditService`, `RouteBuilder`-Komponenten, `RouteWikipediaService`.
5. Fehlerfälle:
   - Scheitert die Generierung, bleibt Planungssheet offen und zeigt `UnifiedErrorView`/Fehlertext.

## Auswirkungen auf bestehende Views/Services
- `Views/RoutePlanning/RouteBuilderView.swift`: Wird nicht mehr als zweites Sheet präsentiert, sondern als Abschnitt/Funktionalität innerhalb des Aktive-Route-Sheets nutzbar (sofern benötigt) oder als interner Flow in `EnhancedActiveRouteSheetView`.
- `Views/RoutePlanning/EnhancedActiveRouteSheetView.swift`: Wird zur zentralen, einzigen modalen Oberfläche für Routenvorschau/-bearbeitung/-start.
- `Services/RouteService.swift` & `RouteEditService.swift`: Unverändert in Logik, aber sicherstellen, dass State für Karte und Sheet synchron bleibt (@MainActor, `@Published`).

## Daten- und Threading-Überlegungen
- `@MainActor` im UI-nahen State (`RouteService`/ViewModels), da Karte und Sheet synchronisiert werden.
- Rate-Limiting (MapKit/HERE) bleibt unverändert.
- Caching (`POICacheService`) unverändert.

## Test & QA
- UI-Tests anpassen:
  - Entferne Assertions, die ein Zwischen-Sheet nach Planung erwarten.
  - Ergänze Tests: Nach Generierung ist die Route auf der Karte sichtbar und genau ein Sheet (Aktive Route) präsent.
  - Betroffene Dateien: `SmartCityGuideUITests/Route_*`, `Sheet_Navigation_Tests.swift`.
- Manuelle QA: Fokus auf Dismiss/Presents (keine doppelte Präsentation), Fehlerpfade, schnelle Re-Try der Generierung.

## Aufgabenpakete
1) Coordinator-State vereinheitlichen (ein `.sheet`) und Enum hinzufügen.
2) `RoutePlanningView` Callback `onGenerated` integrieren; alte Doppel-Präsentation entfernen.
3) Karten-Overlay für `GeneratedRoute` sicher auf Shared State umstellen/prüfen.
4) `EnhancedActiveRouteSheetView` als einziger Modal-Container finalisieren (Add/Edit POIs, Wikipedia, Start/Stop sicherstellen).
5) Fehlerdarstellung konsolidieren (kein zusätzliches Sheet).
6) UI-Tests refactoren; Flows aktualisieren.
7) FAQ-Eintrag in `Views/Profile/HelpSupportView.swift` ergänzen (neuer Flow erklärt) – Pflichtregel.

## Akzeptanzkriterien
- Nach Generierung der Route ist keine zweite Sheet-Ebene sichtbar; Planungssheet ist geschlossen.
- Die Route ist sofort auf der Karte sichtbar.
- Es existiert nur ein Sheet: das Aktive-Route-Sheet, das Vorschau, Edit/Add/Delete von POIs und Start/Stop vereint.
- Keine SwiftUI-Runtime-Warnung bzgl. multipler Sheets („Currently, only presenting a single sheet is supported …“).
- Bestehende Services funktionieren unverändert; keine Regressionen in TSP/Generierung.

## Risiken & Mitigation
- Präsentations-Race: Mit kleinem Delay (oder `withAnimation` + `Transaction`) beim Umschalten mitigieren.
- Zustandssynchronität zwischen Karte und Sheet: Zentraler, beobachtbarer State und `@MainActor` erzwingen.
- UI-Tests, die alte Annahmen verwenden: frühzeitig aktualisieren, um Flakiness zu vermeiden.

## Rollout & Rollback
- Feature-Flag (optional) in `Utilities/FeatureFlags.swift` für kontrollierten Rollout.
- Rollback: Zurück auf alte Doppel-Sheet-Logik (nur wenn notwendig), indem im Enum wieder getrennte Präsentationspunkte aktiviert werden.

## Bezüge zur bestehenden Doku
- `feature/17-08-2025-navigation-unification.md` – Zentralisierte Präsentation passt zur Navigations-Unifizierung.
- `feature/14-08-2025-active-route-bottom-sheet-implementation-plan.md` – Dieses Dokument wird zur primären Modal-Interaktion erweitert.
- `docs/17-08-2025-architecture-overview.md` – Ein einziger Sheet-State im `HomeCoordinator`/Root passt zur beschriebenen Architektur.
- `test-implementations/11-08-2025-happy-path-ui-test-flows.md` – Test-Cases entsprechend anpassen.

---

Autor: @create-spec.mdc
Datum: 20.08.2025

