### SwiftUI-Fehler: „Invalid sample AnimatablePair … with time 0.0 > last time …“

Kurzbeschreibung
- Bedeutung: SwiftUI meldet, dass eine Animation ein Sample bei t = 0.0 liefert, obwohl der letzte Sample‑Zeitpunkt bereits größer war. Effektiv laufen zwei Animations-Zeitachsen für dieselbe Animationsgröße gegeneinander („Zeit springt zurück“).
- Häufige Ursache: Dieselbe animierbare Eigenschaft (z. B. Offset/Rotation/Scale) wird in derselben Render‑Transaktion mehrfach und konkurrierend animiert (implizit via `.animation(_:value:)` und explizit via `withAnimation { … }` bzw. über Gestenupdates). `matchedGeometryEffect` kann das Problem verstärken, wenn IDs/Phasen in einem Frame inkonsistent wechseln.

Warum es bei Tinder‑Swipe‑UIs oft auftritt
- Während einer Drag‑Geste wird der `offset`/die Rotation kontinuierlich aktualisiert (animatableData). Wenn zusätzlich eine übergeordnete View dieselben Properties implizit animiert, entstehen konkurrierende Animator‑Instanzen. Wird eine Animation neu gestartet, bevor die vorherige „weiterlaufen“ kann, meldet SwiftUI die oben genannte Warnung.

Was wir bereits umgesetzt haben
- Gestensteuerung auf `@GestureState` migriert; keine direkten Bindings‑Mutationen während laufender Animationen.
- Entfernen globaler `.animation(…)`‑Modifikatoren auf Karten/Stack; nur gezielte `withAnimation`‑Blöcke für Exit/Bounce‑Back.
- Manuelle Aktionen (Überspringen/Nehmen) entkoppelt; Stack‑Fortschritt wird per `NotificationCenter` ausgelöst, um konkurrierende Animationen zu vermeiden.

Schnelle To‑Do‑Liste (für das zukünftige Fixing)
1) Trigger‑Value‑Pattern verwenden
   - Animationen nur beim Wechsel eines expliziten, `Equatable` Triggers starten (statt globaler `.animation`).
   - Referenz: „Trigger value pattern in SwiftUI“ ([swiftwithmajid.com](https://swiftwithmajid.com/2024/04/02/trigger-value-pattern-in-swiftui/)).

2) Einzige Quelle je animierbarer Eigenschaft
   - `offset`/Rotation/Scale entweder durch die Geste ODER durch die Abschlussanimation steuern – nicht parallel im selben Frame.
   - Keine zusätzliche `.animation(…, value: …)` auf dem gleichen View‑Pfad, wenn bereits `withAnimation` verwendet wird.

3) Transaktionen sauber halten
   - In `updating(_:)` der Geste ggf. `transaction.animation = nil` oder gezielt setzen, damit „Live‑Versatz“ nicht implizit animiert.
   - State‑Übergänge (BounceBack/Exit) mit genau einem `withAnimation`‑Block pro Aktion kapseln.

4) `matchedGeometryEffect` isoliert testen
   - Testweise entfernen/deaktivieren. Verschwindet die Warnung, IDs/Phasen prüfen: Ein Element darf nicht „gleichzeitig“ in zwei Zuständen mit derselben ID existieren.

5) Single‑Flight‑Guards
   - Beim Auto‑Complete ein `isCompleting`‑Flag setzen, damit keine zweite Animation im selben Frame startet (z. B. BounceBack + Exit).

6) Diagnose‑Hooks
   - Logging einbauen, falls in einem Frame sowohl `performSwipeAction` als auch `bounceBack` getriggert würden; eine Seite abbrechen.

Weiterführende Quellen (konkret hilfreich)
- Trigger‑Value‑Pattern für datengesteuerte Effekte und Animationen: [swiftwithmajid.com](https://swiftwithmajid.com/2024/04/02/trigger-value-pattern-in-swiftui/)
- Deterministische Nebenwirkungen über Bindings/`onChange` (Prinzipbeispiel): [dev.to/maeganwilson_](https://dev.to/maeganwilson_/how-to-call-a-function-when-a-slider-changes-in-swiftui-2i88)
- SwiftUI‑/Combine‑Datenfluss sauber trennen (State nicht unnötig während Animation mutieren): [rhonabwy.com](https://rhonabwy.com/2021/02/07/integrating-swiftui-bindings-and-combine/)

Notizen für den schnellen Start (wenn „GO“ kommt)
- [ ] In `SpotSwipeCardView` sicherstellen, dass in Exit/BounceBack ausschließlich der persistente `viewOffset` wirkt und die Gestenquelle auf 0 steht.
- [ ] `matchedGeometryEffect` kurzfristig deaktivieren und prüfen, ob die Warnung verschwindet; anschließend IDs/Phasen bereinigen.
- [ ] Einen `animationTrigger` (Equatable) einführen und Abschlussanimationen daran binden (Trigger‑Value statt globaler `.animation`).
- [ ] „Single‑flight“-Flag einbauen, damit pro Aktion nur eine Abschlussanimation läuft.

