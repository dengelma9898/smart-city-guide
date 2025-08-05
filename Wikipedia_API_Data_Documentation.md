# Wikipedia API Daten-Dokumentation
## Smart City Guide - POI Enrichment

### Übersicht
Diese Dokumentation zeigt alle verfügbaren Datenfelder der Wikipedia APIs für die POI-Anreicherung.

---

## 1. Wikipedia OpenSearch API
**Zweck**: Finde Wikipedia-Seitentitel basierend auf POI-Namen

**Endpoint**: `https://de.wikipedia.org/w/api.php?action=opensearch&search={query}&limit=5&namespace=0&format=json`

### Request Parameter:
- `action=opensearch` - OpenSearch API verwenden
- `search={query}` - Suchbegriff (POI Name)
- `limit=5` - Maximal 5 Ergebnisse
- `namespace=0` - Nur Hauptartikel (keine Diskussions-/Benutzerseiten)
- `format=json` - JSON Response

### Response Struktur:
```json
[
  "Suchbegriff",
  [
    "Artikel Titel 1",
    "Artikel Titel 2", 
    "Artikel Titel 3"
  ],
  [
    "Kurzbeschreibung 1",
    "Kurzbeschreibung 2",
    "Kurzbeschreibung 3"
  ],
  [
    "https://de.wikipedia.org/wiki/Artikel_Titel_1",
    "https://de.wikipedia.org/wiki/Artikel_Titel_2", 
    "https://de.wikipedia.org/wiki/Artikel_Titel_3"
  ]
]
```

### Beispiel Response (Kaiserburg Nürnberg):
```json
[
  "Kaiserburg Nürnberg",
  [
    "Kaiserburg Nürnberg",
    "Nürnberg",
    "Kaiser"
  ],
  [
    "Burganlage in Nürnberg",
    "kreisfreie Großstadt im Freistaat Bayern",
    "deutscher Titel"
  ],
  [
    "https://de.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg",
    "https://de.wikipedia.org/wiki/N%C3%BCrnberg", 
    "https://de.wikipedia.org/wiki/Kaiser"
  ]
]
```

---

## 2. Wikipedia Summary API
**Zweck**: Detaillierte Informationen, Zusammenfassung und Bilder für einen spezifischen Wikipedia-Artikel

**Endpoint**: `https://de.wikipedia.org/api/rest_v1/page/summary/{title}`

### Response Struktur - Alle verfügbaren Felder:

#### Basis-Informationen:
- `type` - Typ der Seite ("standard", "disambiguation", etc.)
- `title` - Exakter Seitentitel
- `displaytitle` - Anzeige-Titel (kann HTML enthalten)
- `namespace` - Namespace (meist `{id: 0, text: ""}` für Hauptartikel)
- `wikibase_item` - Wikidata ID (z.B. "Q182923")
- `titles.canonical` - Kanonischer Titel
- `titles.normalized` - Normalisierter Titel
- `titles.display` - Anzeige-Titel

#### Inhalt:
- `extract` - Zusammenfassung/Extract des Artikels (Klartext)
- `extract_html` - Zusammenfassung mit HTML-Formatierung
- `description` - Kurze Beschreibung
- `description_source` - Quelle der Beschreibung ("local", "central")

#### Bilder:
- `thumbnail.source` - URL des Thumbnail-Bildes
- `thumbnail.width` - Breite des Thumbnails
- `thumbnail.height` - Höhe des Thumbnails
- `originalimage.source` - URL des Original-Bildes
- `originalimage.width` - Breite des Originals
- `originalimage.height` - Höhe des Originals

#### URLs:
- `content_urls.desktop.page` - Desktop Wikipedia URL
- `content_urls.desktop.revisions` - Desktop Revisionen URL
- `content_urls.desktop.edit` - Desktop Edit URL
- `content_urls.mobile.page` - Mobile Wikipedia URL
- `content_urls.mobile.revisions` - Mobile Revisionen URL
- `content_urls.mobile.edit` - Mobile Edit URL

#### Metadaten:
- `api_urls.summary` - API Summary URL
- `api_urls.metadata` - API Metadata URL
- `api_urls.references` - API References URL
- `api_urls.media` - API Media URL
- `api_urls.edit_html` - API Edit HTML URL
- `api_urls.talk_page_html` - API Talk Page URL
- `lang` - Sprache (z.B. "de")
- `dir` - Textrichtung (z.B. "ltr")
- `revision` - Revision ID
- `tid` - Transaction ID
- `timestamp` - Letzter Änderungszeitpunkt

#### Koordinaten (falls verfügbar):
- `coordinates.lat` - Breitengrad
- `coordinates.lon` - Längengrad

### Beispiel Response (Kaiserburg Nürnberg):
```json
{
  "type": "standard",
  "title": "Kaiserburg Nürnberg",
  "displaytitle": "Kaiserburg Nürnberg",
  "namespace": {
    "id": 0,
    "text": ""
  },
  "wikibase_item": "Q182923",
  "titles": {
    "canonical": "Kaiserburg_Nürnberg",
    "normalized": "Kaiserburg Nürnberg",
    "display": "Kaiserburg Nürnberg"
  },
  "pageid": 169169,
  "thumbnail": {
    "source": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Nuremberg_Castle_02.jpg/320px-Nuremberg_Castle_02.jpg",
    "width": 320,
    "height": 240
  },
  "originalimage": {
    "source": "https://upload.wikimedia.org/wikipedia/commons/a/ab/Nuremberg_Castle_02.jpg",
    "width": 1600,
    "height": 1200
  },
  "lang": "de",
  "dir": "ltr",
  "revision": "240123456",
  "tid": "abc12345-1234-1234-1234-123456789abc",
  "timestamp": "2024-01-15T10:30:00Z",
  "description": "Burganlage in Nürnberg",
  "description_source": "local",
  "coordinates": {
    "lat": 49.4583,
    "lon": 11.0758
  },
  "content_urls": {
    "desktop": {
      "page": "https://de.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg",
      "revisions": "https://de.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg?action=history",
      "edit": "https://de.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg?action=edit"
    },
    "mobile": {
      "page": "https://de.m.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg",
      "revisions": "https://de.m.wikipedia.org/wiki/Special:History/Kaiserburg_N%C3%BCrnberg",
      "edit": "https://de.m.wikipedia.org/wiki/Kaiserburg_N%C3%BCrnberg?action=edit"
    }
  },
  "api_urls": {
    "summary": "https://de.wikipedia.org/api/rest_v1/page/summary/Kaiserburg_N%C3%BCrnberg",
    "metadata": "https://de.wikipedia.org/api/rest_v1/page/metadata/Kaiserburg_N%C3%BCrnberg",
    "references": "https://de.wikipedia.org/api/rest_v1/page/references/Kaiserburg_N%C3%BCrnberg",
    "media": "https://de.wikipedia.org/api/rest_v1/page/media/Kaiserburg_N%C3%BCrnberg",
    "edit_html": "https://de.wikipedia.org/api/rest_v1/page/html/Kaiserburg_N%C3%BCrnberg",
    "talk_page_html": "https://de.wikipedia.org/api/rest_v1/page/html/Diskussion:Kaiserburg_N%C3%BCrnberg"
  },
  "extract": "Die Kaiserburg Nürnberg ist eine Doppelburg auf einem Sandsteinfelsen im Nordwesten der Altstadt der bayerischen Stadt Nürnberg. Sie ist das Wahrzeichen der Stadt und gilt als eine der bedeutendsten Kaiserpfalzen des Mittelalters. Die Anlage besteht aus der Kaiserburg im engeren Sinne und der östlich davon gelegenen Burggrafenburg.",
  "extract_html": "<p><b>Die Kaiserburg Nürnberg</b> ist eine Doppelburg auf einem Sandsteinfelsen im Nordwesten der Altstadt der bayerischen Stadt Nürnberg. Sie ist das Wahrzeichen der Stadt und gilt als eine der bedeutendsten Kaiserpfalzen des Mittelalters. Die Anlage besteht aus der Kaiserburg im engeren Sinne und der östlich davon gelegenen Burggrafenburg.</p>"
}
```

---

## 3. Workflow für POI-Enrichment

### Schritt 1: OpenSearch
1. POI Name + Stadt kombinieren: "[POI-Name] [Stadt]" (z.B. "Schöner Brunnen Nürnberg")
2. Kombinierte Suche → Wikipedia OpenSearch für bessere Genauigkeit
3. Beste Übereinstimmung finden basierend auf Relevanz-Score
4. Wikipedia-Seitentitel extrahieren

### Schritt 2: Summary API
1. Seitentitel → Wikipedia Summary API
2. Detaillierte Informationen abrufen
3. Relevante Daten für POI-Anreicherung extrahieren

### Schritt 3: Relevanz-Bewertung
- **Koordinaten-Check**: Wenn verfügbar, prüfe Entfernung zu Original-POI
- **Beschreibungs-Match**: Prüfe ob Beschreibung zum POI-Typ passt
- **Titel-Ähnlichkeit**: String-Ähnlichkeit zwischen POI-Name und Wikipedia-Titel

---

## 4. Empfohlene Datenfelder für Smart City Guide

### Primäre Felder (hohe Priorität):
- ✅ `extract` - Hauptbeschreibung für POI-Details
- ✅ `thumbnail.source` - Bild für POI-Anzeige  
- ✅ `description` - Kurzbeschreibung für Listen
- ✅ `coordinates` - Validierung der Genauigkeit
- ✅ `content_urls.desktop.page` - Link zu vollständiger Information

### Sekundäre Felder (mittlere Priorität):
- 🔄 `originalimage.source` - Hochauflösende Bilder
- 🔄 `wikibase_item` - Wikidata-Verknüpfung für weitere Daten
- 🔄 `extract_html` - Formatierte Beschreibung
- 🔄 `timestamp` - Aktualität der Information

### Tertiäre Felder (niedrige Priorität):
- ⚪ `api_urls.*` - Für erweiterte Features
- ⚪ `revision` - Für Caching-Strategien
- ⚪ `namespace` - Für Filterung

---

## 5. Error Handling

### OpenSearch Fehlerfall:
- Keine Ergebnisse → POI ohne Wikipedia-Enrichment verwenden
- Zu viele Ergebnisse → Bester Match über String-Ähnlichkeit

### Summary API Fehlerfall:
- 404 - Seite nicht gefunden → Fallback auf andere OpenSearch-Ergebnisse
- 400 - Ungültiger Titel → URL-Encoding prüfen
- Rate Limiting → Exponential backoff

---

## 6. Performance-Überlegungen

### Caching:
- **OpenSearch Ergebnisse**: 7 Tage Cache für POI-Namen
- **Summary Daten**: 24 Stunden Cache für Summary-Responses
- **Negative Caches**: 1 Stunde für "nicht gefunden" Ergebnisse

### Rate Limiting:
- Wikipedia: Sehr großzügig (normalerweise kein Problem)
- Empfehlung: 50ms Delay zwischen Requests
- Parallel Requests: Max 3 gleichzeitig

### Optimierungen:
- Batch OpenSearch für mehrere POIs
- Priorisierung: Erst wichtige POIs enrichen
- Async Loading: UI nicht blockieren

---

## 7. Datenqualität

### Matching-Kriterien:
1. **Exakte Übereinstimmung**: POI-Name == Wikipedia-Titel
2. **Koordinaten-Nähe**: < 500m Entfernung (falls verfügbar)
3. **Kategorie-Match**: POI-Typ passt zu Wikipedia-Kategorie
4. **String-Ähnlichkeit**: Levenshtein Distance < 3

### Validierung:
- Coordinates vorhanden und plausibel?
- Extract mindestens 50 Zeichen?
- Thumbnail verfügbar und erreichbar?
- Relevanz-Score > 0.7?

---

*Dokumentation erstellt: Januar 2025*
*Für: Smart City Guide POI Enrichment*