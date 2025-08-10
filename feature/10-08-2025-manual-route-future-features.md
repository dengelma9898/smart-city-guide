# Zukunfts-Ideen: Manuelle Routenplanung & UX-Enhancements

Stand: 10.08.2025

Ziel: Verbesserungen rund um den manuellen Planungsflow (Swipe-Auswahl), Klarheit/Transparenz für Nutzer:innen und technische Robustheit.

## Quick Wins (UX/UI)
- Auswahl-Info dauerhaft: Kompakte Info im Menü (⋯) bleibt, zusätzlich Kontext-Hinweise bei Erstnutzung (kurzer Coach‑Mark).
- Optionaler „Mini-Stack“-Preview: 3 zuletzt gewertete Karten als kleine Timeline anzeigen (ein-/ausblendbar).
- Haptik: Leichtes Feedback bei Accept/Reject/Undo.
- Filter im Menü (⋯): Kategorien schnell ein-/ausblenden (Museum, Park, …).

## Undo/Selection-Flow
- „Mehrfach-Undo“-Viewer: Verlaufsliste öffnen und gezielt Einträge wiederherstellen.
- Re-Insert-Strategie wählbar: „vor aktuelle Karte“ (Standard) vs. „ans Ende“ (später erneut sehen).

## Datenqualität & Bilder
- Stabile Bildzuordnung: AsyncImage mit stabilem Cache-Key (POI-ID + thumb URL), Clear-Policy bei Edit.
- Enrichment-Optimierung: Kein globales Re‑Enrichment bei Einzel‑Edit (nur betroffener POI, gezieltes Invalidieren).
- Caching-Strategie Wikipedia/Geoapify: TTL + ETag-Unterstützung; Pre‑warm nach Discovery.

## Eingabevalidierung / Startkoordinaten
- MR‑001 Fix: CTA deaktivieren, bis gültige Koordinaten vorliegen; Inline-Hinweis + Fallback-Geocoding.
- „Adresse wählen“-Coach‑Mark beim ersten Mal.

## Routen-Logik
- Besuchszeit-Profil: „schnell (30m) / normal (45m) / entspannt (60m)“. Auswahl beeinflusst `totalVisitTime`.
- Endpoint-Varianten: Rundreise, letzter Stopp, Custom – plus „Start ≠ Ziel“ Visualisierung im Preview.
- Distanz/Zeit-Limits im manuellen Flow optional sichtbar (live Balken/Badge).

## FAQ/Support
- FAQ-Erweiterungen (bereits begonnen in `HelpSupportView.swift`):
  - Manuell vs. Automatisch
  - Swipe/Undo erklärt
  - Aktuelle Auswahl/Übersicht im Menü (⋯)
  - Bekannte Einschränkungen verlinken (`known_bugs/10-08-2025-manual-route-bugs.md`)

## Performance/Technik
- Directions-Rate‑Limit: konfigurierbar mit Kurve (0.2s → adaptiv bei hoher Last).
- Distanz-/Zeit-Caching zwischen Waypoints (Memoization über Hash der Koordinatenpaare).
- Parallelisierung Wikipedia‑Fetch mit strukturiertem Concurrency‑Limit.

## Telemetrie (später)
- Anonyme Metriken: Annahme-/Ablehnungsraten pro Kategorie, Abbruchpunkte, Undo‑Quote (lokal opt‑in).

## Akzeptanzkriterien (Auszug)
- Undo‑Sheet: Liste letzter 10 Aktionen, gezieltes Wiederherstellen funktioniert, Zähler aktualisiert sich live.
- Bildkonsistenz: Kein POI zeigt ein falsches Bild nach Edit/Neu‑Generierung (manuelle Stichprobe 20 POIs, 0 Fehlzuordnungen).
- MR‑001: Kein Start mit `(0.0, 0.0)` möglich; verständliche UI‑Hinweise, CTA erst bei gültigen Koordinaten aktiv.

## Hinweise
- Siehe bekannte Bugs: `known_bugs/10-08-2025-manual-route-bugs.md`.
- Alle Texte deutsch, freundlicher Ton („du“), s. `.cursorrules`.

