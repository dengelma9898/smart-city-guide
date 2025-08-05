# Route Planning Refactor Plan - Smart City Guide

## Übersicht
Refactoring der RoutePlanningView Optionen für bessere Flexibilität und Benutzerfreundlichkeit.

## Aktuelle vs. Neue Struktur

### 1. Maximum Stops Filter (vorher: "Wie viele Stopps?")
**Aktuell:**
- Feste Auswahl: 2, 3, 4, 5 Stopps
- Kreisförmige Buttons

**Neu:**
- Maximum Stops Konzept: "Bis zu X Stopps"
- Optionen: 3, 5, 8, 10, 15, 20, "Unbegrenzt"
- UI: Horizontal scrollende Liste mit Chips
- Funktionalität: RouteService generiert bis zu X Stopps, kann aber weniger sein

### 2. Maximum Walking Time Filter (vorher: "Wie weit gehst du?")
**Aktuell:**
- Distanz-basiert: Kurz (≤5km), Mittel (≤15km), Lang (≤50km)

**Neu:**
- Zeit-basiert: "Maximale Gehzeit"
- Optionen: 30min, 45min, 60min, 90min, 2h, 3h, "Open End"
- UI: Horizontal scrollende Liste mit Chips
- Funktionalität: Entfernt Stopps bis Gesamtgehzeit unter Maximum liegt

### 3. Minimum Distance Between POIs (NEU)
**Konzept:**
- Mindestabstand zwischen aufeinanderfolgenden POIs
- Optionen: 100m, 250m, 500m, 750m, 1km, "Kein Minimum"
- UI: Horizontal scrollende Liste mit Chips
- Funktionalität: Filtert POIs die zu nah beieinander liegen

## Datenmodell Änderungen

### Neue Enums
```swift
enum MaximumStops: String, CaseIterable {
    case three = "3"
    case five = "5" 
    case eight = "8"
    case ten = "10"
    case fifteen = "15"
    case twenty = "20"
    case unlimited = "Unbegrenzt"
    
    var intValue: Int? {
        switch self {
        case .unlimited: return nil
        default: return Int(rawValue)
        }
    }
}

enum MaximumWalkingTime: String, CaseIterable {
    case thirtyMin = "30min"
    case fortyFiveMin = "45min"
    case sixtyMin = "60min"
    case ninetyMin = "90min"
    case twoHours = "2h"
    case threeHours = "3h"
    case openEnd = "Open End"
    
    var minutes: Int? {
        switch self {
        case .thirtyMin: return 30
        case .fortyFiveMin: return 45
        case .sixtyMin: return 60
        case .ninetyMin: return 90
        case .twoHours: return 120
        case .threeHours: return 180
        case .openEnd: return nil
        }
    }
}

enum MinimumPOIDistance: String, CaseIterable {
    case oneHundred = "100m"
    case twoFifty = "250m"
    case fiveHundred = "500m"
    case sevenFifty = "750m"
    case oneKm = "1km"
    case noMinimum = "Kein Minimum"
    
    var meters: Double? {
        switch self {
        case .oneHundred: return 100
        case .twoFifty: return 250
        case .fiveHundred: return 500
        case .sevenFifty: return 750
        case .oneKm: return 1000
        case .noMinimum: return nil
        }
    }
}
```

### RoutePlanningView State Änderungen
```swift
// Ersetze:
@State private var numberOfPlaces = 3
@State private var routeLength: RouteLength = .medium

// Mit:
@State private var maximumStops: MaximumStops = .five
@State private var maximumWalkingTime: MaximumWalkingTime = .sixtyMin
@State private var minimumPOIDistance: MinimumPOIDistance = .twoFifty
```

## UI Design Änderungen

### Gemeinsame Komponente: HorizontalFilterChips
```swift
struct HorizontalFilterChips<T: CaseIterable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    let options: [T]
    @Binding var selection: T
    let infoAction: () -> Void
}
```

### Layout Updates
1. **Section Headers**: Icon + Titel + Info Button (bleiben gleich)
2. **Filter Options**: Horizontal ScrollView mit Chips statt vertikalen Buttons
3. **Responsive Design**: Chips passen sich an Textlänge an
4. **Accessibility**: Verbesserte Labels und Hints

## RouteService Änderungen

### Neue Parameter in Route Generation
```swift
struct RouteGenerationParameters {
    let startingCity: String
    let startingCoordinates: CLLocationCoordinate2D?
    let maximumStops: MaximumStops
    let endpointOption: EndpointOption
    let customEndpoint: String
    let customEndpointCoordinates: CLLocationCoordinate2D?
    let maximumWalkingTime: MaximumWalkingTime
    let minimumPOIDistance: MinimumPOIDistance
}
```

### Algorithmus Updates
1. **POI Filtering**: Anwendung des Mindestabstands zwischen POIs
2. **Time-based Optimization**: Entfernung von Stopps basierend auf Gehzeit
3. **Flexible Stop Count**: Dynamische Anpassung der Stopp-Anzahl

### Implementierungslogik
```swift
// 1. POI Discovery (unverändert)
// 2. Mindestabstand-Filterung
// 3. TSP Optimierung
// 4. Gehzeit-Berechnung und Stopp-Entfernung falls nötig
// 5. Finale Route-Generierung
```

## ProfileSettings Integration

### ProfileSettings Model Updates
```swift
// Aktuell in ProfileSettings.swift:
struct ProfileSettings: Codable {
    var defaultNumberOfPlaces: Int          // DEPRECATED - wird zu maximumStops
    var defaultEndpointOption: EndpointOption
    var defaultRouteLength: RouteLength     // DEPRECATED - wird zu maximumWalkingTime  
    var customEndpointDefault: String
    
    // NEU hinzufügen:
    var defaultMaximumStops: MaximumStops
    var defaultMaximumWalkingTime: MaximumWalkingTime
    var defaultMinimumPOIDistance: MinimumPOIDistance
}
```

### Migration Strategy für ProfileSettings
```swift
extension ProfileSettings {
    init() {
        // Legacy Werte für Backwards Compatibility
        self.defaultNumberOfPlaces = 3
        self.defaultEndpointOption = .roundtrip
        self.defaultRouteLength = .medium
        self.customEndpointDefault = ""
        
        // Neue Default-Werte
        self.defaultMaximumStops = .five
        self.defaultMaximumWalkingTime = .sixtyMin
        self.defaultMinimumPOIDistance = .twoFifty
    }
    
    // Migration von alten zu neuen Settings
    mutating func migrateToNewSettings() {
        // Migration: numberOfPlaces -> maximumStops
        if defaultNumberOfPlaces <= 3 {
            defaultMaximumStops = .three
        } else if defaultNumberOfPlaces <= 5 {
            defaultMaximumStops = .five
        } else {
            defaultMaximumStops = .ten
        }
        
        // Migration: routeLength -> maximumWalkingTime
        switch defaultRouteLength {
        case .short:
            defaultMaximumWalkingTime = .thirtyMin
        case .medium:
            defaultMaximumWalkingTime = .sixtyMin
        case .long:
            defaultMaximumWalkingTime = .twoHours
        }
        
        // Standard-Wert für neuen Filter
        defaultMinimumPOIDistance = .twoFifty
    }
}
```

### ProfileSettingsManager Updates
```swift
extension ProfileSettingsManager {
    func updateDefaults(
        maximumStops: MaximumStops? = nil,
        endpointOption: EndpointOption? = nil,
        maximumWalkingTime: MaximumWalkingTime? = nil,
        minimumPOIDistance: MinimumPOIDistance? = nil,
        customEndpoint: String? = nil
    ) {
        if let maximumStops = maximumStops {
            settings.defaultMaximumStops = maximumStops
        }
        if let endpointOption = endpointOption {
            settings.defaultEndpointOption = endpointOption
        }
        if let maximumWalkingTime = maximumWalkingTime {
            settings.defaultMaximumWalkingTime = maximumWalkingTime
        }
        if let minimumPOIDistance = minimumPOIDistance {
            settings.defaultMinimumPOIDistance = minimumPOIDistance
        }
        if let customEndpoint = customEndpoint {
            settings.customEndpointDefault = customEndpoint
        }
        save()
    }
}
```

### Default Settings Helper Updates
```swift
extension ProfileSettings {
    func getDefaultsForRoutePlanning() -> (MaximumStops, EndpointOption, MaximumWalkingTime, MinimumPOIDistance, String) {
        return (
            defaultMaximumStops,
            defaultEndpointOption,
            defaultMaximumWalkingTime,
            defaultMinimumPOIDistance,
            customEndpointDefault
        )
    }
    
    // Legacy Support - kann später entfernt werden
    func getLegacyDefaultsForRoutePlanning() -> (Int, EndpointOption, RouteLength, String) {
        return (
            defaultNumberOfPlaces,
            defaultEndpointOption,
            defaultRouteLength,
            customEndpointDefault
        )
    }
}
```

### ProfileSettingsView.swift Updates
Die bestehende ProfileSettingsView.swift muss komplett überarbeitet werden:

#### Aktuelle Sektionen (zu ersetzen):
1. **"Number of Places Section"** → wird zu **"Maximum Stops Section"**
2. **"Route Length Section"** → wird zu **"Maximum Walking Time Section"**  
3. **"Endpoint Options Section"** → bleibt gleich
4. **NEU**: **"Minimum POI Distance Section"**

#### Neue Section: Maximum Stops
```swift
// Ersetzt die aktuelle "Number of Places Section" (Zeilen 32-71)
Section {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: "map.fill")
                .foregroundColor(.blue)
                .frame(width: 20)
            Text("Maximale Stopps")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        
        // Horizontal scrollende Chips wie in RoutePlanningView
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MaximumStops.allCases, id: \.self) { stops in
                    Button(action: {
                        settingsManager.updateDefaults(maximumStops: stops)
                    }) {
                        Text(stops.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(settingsManager.settings.defaultMaximumStops == stops ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(settingsManager.settings.defaultMaximumStops == stops ? .blue : Color(.systemGray6))
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        
        Text("Standard: \(settingsManager.settings.defaultMaximumStops.rawValue)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
} header: {
    Text("Stopp-Präferenzen")
}
```

#### Neue Section: Maximum Walking Time
```swift
// Ersetzt die aktuelle "Route Length Section" (Zeilen 73-120)
Section {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
                .frame(width: 20)
            Text("Maximale Gehzeit")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        
        VStack(spacing: 8) {
            ForEach(MaximumWalkingTime.allCases, id: \.self) { time in
                Button(action: {
                    settingsManager.updateDefaults(maximumWalkingTime: time)
                }) {
                    HStack {
                        Image(systemName: settingsManager.settings.defaultMaximumWalkingTime == time ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(settingsManager.settings.defaultMaximumWalkingTime == time ? .blue : .secondary)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(time.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(time.description) // Brauchen wir noch
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(settingsManager.settings.defaultMaximumWalkingTime == time ? Color(.systemBlue).opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    .padding(.vertical, 4)
} header: {
    Text("Zeit-Präferenzen")
}
```

#### Neue Section: Minimum POI Distance
```swift
// Komplett neue Sektion nach der Walking Time Section
Section {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .foregroundColor(.blue)
                .frame(width: 20)
            Text("Mindestabstand zwischen Stopps")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MinimumPOIDistance.allCases, id: \.self) { distance in
                    Button(action: {
                        settingsManager.updateDefaults(minimumPOIDistance: distance)
                    }) {
                        Text(distance.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(settingsManager.settings.defaultMinimumPOIDistance == distance ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(settingsManager.settings.defaultMinimumPOIDistance == distance ? .blue : Color(.systemGray6))
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        
        Text("Standard: \(settingsManager.settings.defaultMinimumPOIDistance.rawValue)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
} header: {
    Text("Abstand-Präferenzen")
} footer: {
    Text("Größere Abstände = weniger Stopps, aber mehr Abwechslung in der Route")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

#### Endpoint Options Section (bleibt gleich)
```swift
// Die bestehende "Endpoint Options Section" (Zeilen 122-187) bleibt unverändert
// Nur der updateDefaults-Call muss angepasst werden falls neue Parameter hinzukommen
```

#### Neue Required Extensions für MaximumWalkingTime
```swift
// Müssen wir in RouteModels.swift hinzufügen:
extension MaximumWalkingTime {
    var description: String {
        switch self {
        case .thirtyMin: return "Kurze Spaziergänge"
        case .fortyFiveMin: return "Entspannte Touren"
        case .sixtyMin: return "Solide Entdeckungstouren"
        case .ninetyMin: return "Ausgiebige Erkundungen"
        case .twoHours: return "Intensive City-Touren"
        case .threeHours: return "Ganztages-Abenteuer"
        case .openEnd: return "Ohne Zeitlimit"
        }
    }
}
```

#### Migration der bestehenden updateDefaults Calls
```swift
// Alle bestehenden updateDefaults-Calls in ProfileSettingsView müssen ersetzt werden:

// ALT:
settingsManager.updateDefaults(numberOfPlaces: number)
settingsManager.updateDefaults(routeLength: length)

// NEU:
settingsManager.updateDefaults(maximumStops: stops)
settingsManager.updateDefaults(maximumWalkingTime: time)
settingsManager.updateDefaults(minimumPOIDistance: distance)
```

### Migration in loadDefaultSettings()
```swift
// In RoutePlanningView.swift:
private func loadDefaultSettings() {
    // Erst Migration durchführen falls nötig
    settingsManager.settings.migrateToNewSettings()
    
    // Dann neue Defaults laden
    let defaults = settingsManager.settings.getDefaultsForRoutePlanning()
    
    if maximumStops == .five { // Nur aktualisieren wenn noch Default-Wert
        maximumStops = defaults.0
    }
    
    if endpointOption == .roundtrip {
        endpointOption = defaults.1
    }
    
    if maximumWalkingTime == .sixtyMin {
        maximumWalkingTime = defaults.2
    }
    
    if minimumPOIDistance == .twoFifty {
        minimumPOIDistance = defaults.3
    }
    
    if customEndpoint.isEmpty {
        customEndpoint = defaults.4
    }
}
```

## Info Dialog Updates

### Neue Hilfe-Texte
1. **Maximum Stops**: "Wie viele Stopps sollen maximal in deiner Route sein? Ich finde die besten Orte, aber es können auch weniger werden!"
2. **Maximum Walking Time**: "Wie lange möchtest du maximal laufen? Wenn die Route länger wird, entferne ich automatisch Stopps."
3. **Minimum POI Distance**: "Wie weit sollen die Orte mindestens voneinander entfernt sein? Größere Abstände = weniger Stopps, aber mehr Abwechslung!"

## Implementierungsreihenfolge

### Phase 1: Datenmodell
1. Neue Enums erstellen
2. RouteModels.swift erweitern
3. ProfileSettings anpassen

### Phase 2: UI Komponenten
1. HorizontalFilterChips Komponente erstellen
2. RoutePlanningView Layout anpassen
3. Info Dialogs aktualisieren

### Phase 3: Service Logic
1. RouteService Parameter erweitern
2. POI Distanz-Filterung implementieren
3. Zeit-basierte Optimierung implementieren

### Phase 4: Integration & Testing
1. Alle Komponenten zusammenführen
2. ProfileSettings Integration
3. Umfangreiches Testing

## FAQ Updates (Mandatory)
Nach Implementierung müssen die FAQs in `HelpSupportView.swift` aktualisiert werden:
- Neue Filteroptionen erklären
- Zeitbasierte vs. distanzbasierte Routenplanung
- Mindestabstand-Konzept erläutern

## Performance Überlegungen
- Caching von Distanz-Berechnungen zwischen POIs
- Optimierte TSP-Algorithmen für größere POI-Sets
- Lazy Loading bei vielen Stopp-Optionen

## Backwards Compatibility
- Migration alter RouteLength zu neuen MaximumWalkingTime
- Default-Werte für neue Optionen
- Graceful Handling von Legacy-Einstellungen

## Testing Strategy
1. **Unit Tests**: Neue Enums und Berechnungslogik
2. **Integration Tests**: RouteService mit neuen Parametern
3. **UI Tests**: Neue Filter-Interaktionen
4. **Performance Tests**: Große POI-Sets und komplexe Routen
5. **User Testing**: Intuitive Bedienung der neuen Optionen