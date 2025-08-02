# POI-basierte Routenerstellung - Implementierungsplan

## Überblick
Implementierung einer POI-basierten Routenerstellung für die Smart City Guide iOS App mit der Overpass API zur Erkennung von Sehenswürdigkeiten und Apple MapKit für die Kartendarstellung.

## 1. Technische Architektur

### 1.1 Komponenten
- **OverpassAPIService**: Service für POI-Abfragen
- **RouteOptimizationService**: Berechnung optimaler Routen zwischen POIs
- **AppleMapKitIntegration**: Kartendarstellung und Navigation
- **POIModels**: Datenmodelle für Points of Interest

### 1.2 Datenfluss
```
RoutePlanningView → RouteBuilderView → OverpassAPIService → RouteOptimizationService → AppleMapKit
```

## 2. POI-Kategorien (Overpass API Tags)

### 2.1 Unterstützte POI-Typen
- **Sehenswürdigkeiten/Attraktionen**: `tourism=attraction`
- **Parks**: `leisure=park`
- **Museen**: `tourism=museum` 
- **Rathäuser**: `amenity=townhall`

### 2.2 Overpass API Query Struktur
```javascript
[out:json][timeout:25];
(
  node["tourism"="attraction"]({{bbox}});
  way["tourism"="attraction"]({{bbox}});
  node["leisure"="park"]({{bbox}});
  way["leisure"="park"]({{bbox}});
  node["tourism"="museum"]({{bbox}});
  way["tourism"="museum"]({{bbox}});
  node["amenity"="townhall"]({{bbox}});
  way["amenity"="townhall"]({{bbox}});
);
out center geom;
```

### 2.3 Verfügbare POI-Kategorien - Überpass API Tags Dokumentation

#### 2.3.1 Tourismus & Sehenswürdigkeiten
```
tourism=attraction         # Allgemeine Sehenswürdigkeiten/Attraktionen
tourism=museum            # Museen
tourism=gallery           # Kunstgalerien  
tourism=zoo               # Zoos/Tierparks
tourism=theme_park        # Freizeitparks
tourism=aquarium          # Aquarien
tourism=artwork           # Kunstwerke im öffentlichen Raum
tourism=viewpoint         # Aussichtspunkte
tourism=picnic_site       # Picknickplätze
tourism=information       # Touristeninformation
tourism=monument          # Denkmäler/Monumente
tourism=memorial          # Gedenkstätten
tourism=castle            # Burgen/Schlösser
tourism=ruins             # Ruinen
tourism=archaeological_site # Archäologische Stätten
```

#### 2.3.2 Freizeit & Erholung
```
leisure=park              # Parks/Grünanlagen
leisure=garden            # Botanische Gärten
leisure=nature_reserve    # Naturschutzgebiete
leisure=playground        # Spielplätze
leisure=sports_centre     # Sportzentren
leisure=swimming_pool     # Schwimmbäder
leisure=beach_resort      # Strandbäder
leisure=marina            # Marinas/Yachthäfen
leisure=golf_course       # Golfplätze
leisure=water_park        # Wasserparks
leisure=fitness_centre    # Fitnesszentren
leisure=bowling_alley     # Bowlingbahnen
leisure=miniature_golf    # Minigolf
leisure=pitch             # Sportplätze
```

#### 2.3.3 Bildung & Kultur
```
amenity=library           # Bibliotheken
amenity=theatre           # Theater
amenity=cinema            # Kinos
amenity=arts_centre       # Kulturzentren
amenity=community_centre  # Gemeindezentren
amenity=university        # Universitäten
amenity=school            # Schulen
amenity=kindergarten      # Kindergärten
amenity=college           # Hochschulen
amenity=conference_centre # Konferenzzentren
amenity=music_venue       # Musikveranstaltungsorte
```

#### 2.3.4 Verwaltung & Öffentliche Einrichtungen
```
amenity=townhall          # Rathäuser
amenity=courthouse        # Gerichte
amenity=post_office       # Postämter
amenity=police            # Polizeistationen
amenity=fire_station      # Feuerwachen
amenity=embassy           # Botschaften
amenity=public_building   # Öffentliche Gebäude
office=government         # Regierungsbüros
office=administrative     # Verwaltungsgebäude
```

#### 2.3.5 Religion & Spiritualität
```
amenity=place_of_worship  # Gebetsstätten (allgemein)
amenity=church            # Kirchen (veraltet, nutze place_of_worship)
amenity=cathedral         # Kathedralen
amenity=chapel            # Kapellen
amenity=monastery         # Klöster
amenity=shrine            # Schreine
religion=christian        # (Kombination mit place_of_worship)
religion=muslim           # (Kombination mit place_of_worship)
religion=jewish           # (Kombination mit place_of_worship)
religion=buddhist         # (Kombination mit place_of_worship)
religion=hindu            # (Kombination mit place_of_worship)
```

#### 2.3.6 Gastronomie & Einzelhandel
```
amenity=restaurant        # Restaurants
amenity=cafe              # Cafés
amenity=pub               # Kneipen/Pubs
amenity=bar               # Bars
amenity=fast_food         # Fast Food
amenity=food_court        # Food Courts
amenity=biergarten        # Biergärten
amenity=ice_cream         # Eisdielen
shop=supermarket          # Supermärkte
shop=department_store     # Kaufhäuser
shop=mall                 # Einkaufszentren
shop=bakery               # Bäckereien
shop=butcher              # Metzgereien
shop=books                # Buchläden
shop=clothes              # Bekleidungsgeschäfte
shop=gift                 # Souvenirläden
```

#### 2.3.7 Transport & Verkehr
```
amenity=parking           # Parkplätze
amenity=fuel              # Tankstellen
amenity=charging_station  # Ladestationen (E-Autos)
amenity=bicycle_parking   # Fahrradparkplätze
amenity=bicycle_rental    # Fahrradverleih
amenity=car_rental        # Autovermietung
amenity=taxi              # Taxistände
public_transport=station  # Bahnhöfe
public_transport=stop_position # Haltestellen
railway=station           # Bahnhöfe
aeroway=aerodrome         # Flughäfen
```

#### 2.3.8 Gesundheit & Notfall
```
amenity=hospital          # Krankenhäuser
amenity=clinic            # Kliniken
amenity=doctors           # Arztpraxen
amenity=dentist           # Zahnarztpraxen
amenity=pharmacy          # Apotheken
amenity=veterinary        # Tierärzte
emergency=phone           # Notrufsäulen
emergency=defibrillator   # Defibrillatoren
```

#### 2.3.9 Unterkunft
```
tourism=hotel             # Hotels
tourism=hostel            # Hostels
tourism=guest_house       # Pensionen/Gästehäuser
tourism=motel             # Motels
tourism=chalet            # Chalets
tourism=apartment         # Ferienwohnungen
tourism=camp_site         # Campingplätze
tourism=caravan_site      # Wohnmobilstellplätze
```

#### 2.3.10 Natur & Landschaft
```
natural=peak              # Berggipfel
natural=cave_entrance     # Höhleneingänge
natural=spring            # Quellen
natural=waterfall         # Wasserfälle
natural=beach             # Strände
natural=forest            # Wälder
natural=lake              # Seen
natural=river             # Flüsse
natural=volcano           # Vulkane
natural=geyser            # Geysire
landuse=forest            # Waldgebiete
landuse=recreation_ground # Erholungsgebiete
```

#### 2.3.11 Erweiterte Query-Beispiele

**Mehrere Kategorien kombinieren:**
```javascript
[out:json][timeout:25];
(
  // Kultur & Bildung
  node["tourism"="museum"]({{bbox}});
  way["tourism"="museum"]({{bbox}});
  node["amenity"="library"]({{bbox}});
  way["amenity"="library"]({{bbox}});
  node["amenity"="theatre"]({{bbox}});
  way["amenity"="theatre"]({{bbox}});
  
  // Natur & Erholung  
  node["leisure"="park"]({{bbox}});
  way["leisure"="park"]({{bbox}});
  node["natural"="peak"]({{bbox}});
  node["tourism"="viewpoint"]({{bbox}});
);
out center geom;
```

**Mit zusätzlichen Filtern:**
```javascript
[out:json][timeout:25];
(
  // Nur benannte Attraktionen
  node["tourism"="attraction"]["name"]({{bbox}});
  way["tourism"="attraction"]["name"]({{bbox}});
  
  // Museen mit Öffnungszeiten
  node["tourism"="museum"]["opening_hours"]({{bbox}});
  way["tourism"="museum"]["opening_hours"]({{bbox}});
);
out center geom;
```

**Ausschluss bestimmter Kategorien:**
```javascript
[out:json][timeout:25];
(
  // Alle Tourismus-POIs außer Hotels
  node["tourism"]["tourism"!="hotel"]({{bbox}});
  way["tourism"]["tourism"!="hotel"]({{bbox}});
);
out center geom;
```

### 2.4 Implementierungshinweise für neue Kategorien

Bei der Erweiterung um neue POI-Kategorien beachten:

1. **Tag-Kombinationen**: Manche POIs nutzen mehrere Tags (z.B. `place_of_worship` + `religion=christian`)
2. **Geometrie-Typen**: Berücksichtigung von Nodes, Ways und Relations
3. **Qualitätsfilter**: Verwendung von `name`-Tags für bessere Ergebnisse
4. **Performance**: Begrenzung der Kategorien pro Query für bessere Response-Zeiten
5. **Lokalisierung**: Unterstützung für mehrsprachige Namen (`name:de`, `name:en`, etc.)

## 3. Implementierung - Phase 1

### 3.1 OverpassAPIService erstellen
```swift
// Services/OverpassAPIService.swift
class OverpassAPIService {
    private let baseURL = "https://overpass-api.de/api/interpreter"
    
    func fetchPOIs(in city: String, categories: [POICategory]) async throws -> [POI]
    func fetchPOIsInBoundingBox(_ bbox: BoundingBox, categories: [POICategory]) async throws -> [POI]
}
```

### 3.2 POI-Datenmodelle erweitern
```swift
// Models/POI.swift
struct POI: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: POICategory
    let description: String?
    let tags: [String: String]
}

enum POICategory: String, CaseIterable {
    case attraction = "tourism=attraction"
    case park = "leisure=park"
    case museum = "tourism=museum"
    case townhall = "amenity=townhall"
}
```

### 3.3 RouteBuilderView erweitern
```swift
// Views/RoutePlanning/RouteBuilderView.swift
struct RouteBuilderView: View {
    @StateObject private var overpassService = OverpassAPIService()
    @State private var discoveredPOIs: [POI] = []
    @State private var isLoadingPOIs = false
    
    private func loadPOIsForCity() async {
        // POIs für gewählte Stadt laden
    }
    
    private func generateOptimalRoute() {
        // Optimale Route zwischen POIs berechnen
    }
}
```

## 4. Implementierung - Phase 2

### 4.1 Stadt zu Koordinaten-Mapping
```swift
// Services/GeocodingService.swift
class GeocodingService {
    func getBoundingBox(for cityName: String) async throws -> BoundingBox
    func getCoordinates(for cityName: String) async throws -> CLLocationCoordinate2D
}

struct BoundingBox {
    let south: Double
    let west: Double
    let north: Double
    let east: Double
}
```

### 4.2 Routenoptimierung
```swift
// Services/RouteOptimizationService.swift
class RouteOptimizationService {
    func optimizeRoute(
        start: CLLocationCoordinate2D,
        pois: [POI],
        numberOfStops: Int,
        routeLength: RouteLength
    ) -> OptimizedRoute
    
    private func selectBestPOIs(_ allPOIs: [POI], count: Int) -> [POI]
    private func calculateTravelingSalesmanRoute(_ pois: [POI]) -> [POI]
}
```

## 5. Implementierung - Phase 3

### 5.1 Apple MapKit Integration
```swift
// Views/RoutePlanning/RouteMapView.swift
struct RouteMapView: UIViewRepresentable {
    let route: OptimizedRoute
    
    func makeUIView(context: Context) -> MKMapView
    func updateUIView(_ mapView: MKMapView, context: Context)
    
    private func addPOIAnnotations(_ mapView: MKMapView)
    private func addRouteOverlay(_ mapView: MKMapView)
}
```

### 5.2 POI-Bewertungssystem
```swift
// Models/POIRating.swift
struct POIRating {
    let poi: POI
    let popularityScore: Double  // Basierend auf OSM-Tags
    let relevanceScore: Double   // Basierend auf Kategorie-Präferenzen
    let accessibilityScore: Double  // Entfernung zu anderen POIs
    
    var totalScore: Double {
        (popularityScore + relevanceScore + accessibilityScore) / 3.0
    }
}
```

## 6. Benutzeroberfläche

### 6.1 RouteBuilderView Updates
- **Loading State**: Anzeige während POI-Suche
- **POI-Auswahl**: Liste der gefundenen POIs mit Kategoriefiltern
- **Kartenvorschau**: Mini-Karte mit vorgeschlagener Route
- **Route-Anpassung**: Drag & Drop für POI-Reihenfolge

### 6.2 Neue Views
```
Views/
├── RoutePlanning/
│   ├── RouteBuilderView.swift (erweitert)
│   ├── POIListView.swift (neu)
│   ├── RouteMapView.swift (neu)
│   └── POIDetailView.swift (neu)
```

## 7. Fehlerbehandlung

### 7.1 Overpass API Fehler
- **Timeout**: Fallback auf cached POIs
- **Rate Limiting**: Exponential backoff
- **Keine Ergebnisse**: Erweiterte Suchreichweite

### 7.2 Benutzer-Feedback
- **Keine POIs gefunden**: Alternative Städte vorschlagen
- **Zu wenige POIs**: Suchradius erweitern
- **API-Fehler**: Offline-Modus mit vordefinierten POIs

## 8. Performance-Optimierung

### 8.1 Caching-Strategie
- **POI-Cache**: Core Data für häufig gesuchte Städte
- **Route-Cache**: Optimierte Routen zwischenspeichern
- **Image-Cache**: POI-Bilder von OpenStreetMap

### 8.2 Asynchrone Verarbeitung
- **Batch-Verarbeitung**: POIs in Gruppen laden
- **Background-Tasks**: Routenoptimierung im Hintergrund
- **Progressive Loading**: Erste Ergebnisse sofort anzeigen

## 9. Testing-Strategie

### 9.1 Unit Tests
- OverpassAPIService: Query-Generierung und Parsing
- RouteOptimizationService: Algorithmus-Validierung
- POI-Models: Datenintegrität

### 9.2 Integration Tests
- End-to-End Routenerstellung
- Apple MapKit Integration
- Offline-Verhalten

## 10. Zeitplan

### Phase 1 (Woche 1-2): Grundgerüst
- OverpassAPIService Implementation
- POI-Modelle erweitern
- Basis-UI in RouteBuilderView

### Phase 2 (Woche 3-4): Routenoptimierung  
- GeocodingService für Städte-Mapping
- Routenoptimierungs-Algorithmen
- POI-Bewertungssystem

### Phase 3 (Woche 5-6): Integration & Polish
- Apple MapKit Integration
- UI/UX Verbesserungen
- Fehlerbehandlung & Testing

## 11. Risiken & Mitigation

### 11.1 Technische Risiken
- **Overpass API Verfügbarkeit**: Fallback auf alternative APIs
- **Performance bei vielen POIs**: Paginierung implementieren
- **Routenoptimierung Komplexität**: Heuristische Algorithmen nutzen

### 11.2 UX-Risiken
- **Lange Ladezeiten**: Progressive Loading
- **Unzureichende POI-Abdeckung**: Mehrere Datenquellen
- **Komplexe Benutzeroberfläche**: Schrittweise Einführung

## 12. Zukünftige Erweiterungen

- **Offline-Karten**: Apple MapKit Offline-Unterstützung
- **POI-Reviews**: Integration von Bewertungsplattformen
- **Personalisierung**: ML-basierte POI-Empfehlungen
- **Social Features**: Route-Sharing mit anderen Nutzern

---

**Nächste Schritte**: Review des Plans und Beginn mit Phase 1 - OverpassAPIService Implementation