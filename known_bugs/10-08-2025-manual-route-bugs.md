# Manual Route – Offene Bugs (10-08-2025)

Diese Datei sammelt konkrete Bugs, die im manuellen Routen-Flow beobachtet wurden. Sie ist so strukturiert, dass wir sie später effizient abarbeiten können.

## BUG-001: Keine Bilder in der Routen-Vorschau, obwohl sie im Swipe vorhanden sind
- Status: Open
- Bereich: `RouteBuilderView`, Wikipedia-Enrichment / Image Binding
- Beobachtung:
  - In der POI-Auswahl (Swipe) sind Bilder sichtbar.
  - In der daraus erzeugten Routen-Vorschau fehlen diese Bilder bei denselben POIs.
- Reproduktion:
  1. Start/Ziel wählen, manuell POIs swipen (mind. 3–5).
  2. Route erstellen → Preview öffnen.
  3. In der Liste der Stopps fehlen Bilder.
- Erwartet: Dieselben verfügbaren Wikipedia/POI-Bilder werden auch in der Preview angezeigt.
- Hypothese:
  - Enriched-Daten (mit Image-URL) werden im Manual-Flow nicht (oder nicht rechtzeitig) in `RouteBuilderView` gemappt.
  - Unterschiedliche Datenquellen: Swipe nutzt `WikipediaEnrichedPOI` direkt, Preview nutzt `RoutePoint` ohne Image-Feld.
- Diagnoseideen:
  - Loggen, ob `enrichedPOIs[poi.id]?.wikipediaImageURL` in Preview verfügbar ist.
  - Prüfen, ob `RoutePoint` eine Image-URL trägt oder ob die Preview konsequent `enrichedPOIs` nutzt.
- Lösungsansatz:
  - Vereinheitlichen: Preview nutzt dieselbe `WikipediaEnrichedPOI`-Quelle (Dictionary) und fallbacks.
  - Optional: Image-URL in `RoutePoint` kopieren, wenn vorhanden.
- Akzeptanzkriterien:
  - Für POIs mit Bild im Swipe ist in der Preview dasselbe Bild sichtbar.

## BUG-002: Beim Editieren eines einzelnen POI werden unnötig Wikipedia-Daten für andere POIs geladen
- Status: Open
- Bereich: `RouteEditView` / Enrichment-Strategie
- Beobachtung:
  - Ohne neue Discovery oder neue Route wird beim Editieren eines einzelnen POI die Wikipedia-Anreicherung breit erneut angestoßen.
- Reproduktion:
  1. Route generieren (manuell oder automatisch).
  2. Einen Stopp öffnen und Edit starten.
  3. Logs zeigen paralleles/erneutes Enrichment für mehrere POIs.
- Erwartet: Beim Edit nur die relevanten Alternativen/der neue POI werden angereichert (On-Demand), kein Full-Re-Enrichment.
- Hypothese:
  - Zu grobkörniger Enrichment-Trigger (Phase-2 Hintergrundpfad läuft auch während Edit oder globaler Trigger in `RouteBuilderView`).
- Diagnoseideen:
  - Log-Guards um Enrichment-Startpunkte; prüfen, wer triggert.
  - Flag setzen „currently editing“ → Enrichment drosseln/deaktivieren.
- Lösungsansatz:
  - Enrichment granularisieren: Nur Kandidaten/ersetzter POI anreichern.
  - Hintergrund-Enrichment pausieren, solange Edit aktiv ist.
- Akzeptanzkriterien:
  - Edit eines einzelnen POI triggert maximal Anreicherung für Alternativen/ausgewählten neuen POI.

## BUG-003: Falsche Bilder für POIs in der erzeugten Route
- Status: Open
- Bereich: Daten-Zuordnung Preview (Identifier/Key)
- Beobachtung:
  - In manchen Fällen zeigt die Preview für POIs falsche Bilder.
- Reproduktion:
  1. Manuelle Route erstellen, Preview öffnen.
  2. Durch Liste scrollen; falsches Bild erscheint bei einzelnen Stopps.
- Erwartet: POI ↔ Bild-Mapping ist stabil und korrekt.
- Hypothese:
  - Key-Mismatch beim Dictionary (`enrichedPOIs[poi.id]`) vs. Zuordnung per Name/Koordinate.
  - Reuse von Zellen/Asynchrones Laden überschreibt falsches Ziel.
- Diagnoseideen:
  - Streng über `poi.id` mappen (kein Name-Fuzzy-Match).
  - In UI klaren AsyncImage-Key verwenden und SwiftUI-Identities überprüfen.
- Lösungsansatz:
  - Einheitliche, eindeutige Schlüssel (POI-ID) für alle Zugriffe.
  - AsyncImage stabilisieren (unique URL per POI, Cancel vorheriger Loads).
- Akzeptanzkriterien:
  - Keine Bildverwechslungen mehr nach 50+ Scrolls/Updates.

---

### Gemeinsame Debug-Hinweise
- Logs aktivieren (bereits vorhandene `SecureLogger`-Meldungen nutzen/erweitern).
- Für Preview: bei Render prüfen, ob `enrichedPOIs` bereits gefüllt ist; ggf. Lazy-Anzeige mit Platzhaltern + spätes Refresh.
- Für Edit: klarer Lebenszyklus (Start/Stop) → Enrichment nur, wenn sinnvoll.

### Priorisierungsvorschlag
1) BUG-003 (Falsche Bilder) – potenziell verwirrend
2) BUG-001 (Fehlende Bilder) – Qualitätslücke
3) BUG-002 (Over-Enrichment beim Edit) – Performance/Netzlast
