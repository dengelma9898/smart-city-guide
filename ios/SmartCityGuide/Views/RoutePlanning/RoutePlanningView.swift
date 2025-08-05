import SwiftUI
import MapKit

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var settingsManager = ProfileSettingsManager()

  
  @State private var startingCity = ""
  @State private var startingCoordinates: CLLocationCoordinate2D? = nil // NEW: Store coordinates
  @State private var maximumStops: MaximumStops = .five
  @State private var endpointOption: EndpointOption = .roundtrip
  @State private var customEndpoint = ""
  @State private var customEndpointCoordinates: CLLocationCoordinate2D? = nil // NEW: Store endpoint coordinates
  @State private var maximumWalkingTime: MaximumWalkingTime = .sixtyMin
  @State private var minimumPOIDistance: MinimumPOIDistance = .twoFifty
  @State private var showingRouteBuilder = false
  @State private var showingStartPointInfo = false
  @State private var showingStopsInfo = false
  @State private var showingWalkingTimeInfo = false
  @State private var showingPOIDistanceInfo = false
  @State private var showingEndpointInfo = false
  
  // Legacy support - entfernen nach Migration
  @State private var numberOfPlaces = 3
  @State private var routeLength: RouteLength = .medium
  
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
            // Starting Point Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "location.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Wo startest du?")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingStartPointInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Startort Info")
                .accessibilityHint("Mehr Infos zum Startort")
              }
              
              LocationSearchField(
                placeholder: "Berlin, München, Hamburg... worauf hast du Lust?",
                text: $startingCity,
                onLocationSelected: { coordinates, address in
                  startingCoordinates = coordinates
                  SecureLogger.shared.logCoordinates(coordinates, context: "Starting location saved")
                }
              )
              
              // City extraction hint
              if !startingCity.isEmpty {
                CityInputHintView(inputText: startingCity)
              }
            }
            
            // Maximum Stops Section
            HorizontalFilterChips(
              title: "Maximale Stopps",
              icon: "map.fill",
              options: MaximumStops.allCases,
              selection: $maximumStops,
              infoAction: {
                showingStopsInfo = true
              }
            )
            
            // Maximum Walking Time Section
            HorizontalFilterChips(
              title: "Maximale Gehzeit",
              icon: "clock.fill",
              options: MaximumWalkingTime.allCases,
              selection: $maximumWalkingTime,
              infoAction: {
                showingWalkingTimeInfo = true
              }
            )
            
            // Minimum POI Distance Section
            HorizontalFilterChips(
              title: "Mindestabstand",
              icon: "point.3.filled.connected.trianglepath.dotted",
              options: MinimumPOIDistance.allCases,
              selection: $minimumPOIDistance,
              infoAction: {
                showingPOIDistanceInfo = true
              }
            )
            
            // Endpoint Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Wo willst du hin?")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                  showingEndpointInfo = true
                }) {
                  Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Ziel Info")
                .accessibilityHint("Mehr Infos zum Ziel")
              }
              
              HStack(spacing: 8) {
                ForEach(EndpointOption.allCases, id: \.self) { option in
                  Button(action: {
                    endpointOption = option
                  }) {
                    Text(option.rawValue)
                      .font(.body)
                      .fontWeight(.medium)
                      .foregroundColor(endpointOption == option ? .white : .blue)
                      .padding(.horizontal, 16)
                      .padding(.vertical, 12)
                      .frame(maxWidth: .infinity)
                      .background(
                        RoundedRectangle(cornerRadius: 10)
                          .fill(endpointOption == option ? .blue : Color(.systemGray6))
                      )
                  }
                  .accessibilityLabel("\(option.rawValue) Ziel")
                  .accessibilityAddTraits(endpointOption == option ? .isSelected : [])
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Ziel wählen")
              
              if endpointOption == .custom {
                LocationSearchField(
                  placeholder: "Wo soll's enden?",
                  text: $customEndpoint
                )
                .padding(.top, 8)
                
                // City extraction hint for custom endpoint
                if !customEndpoint.isEmpty {
                  CityInputHintView(inputText: customEndpoint)
                    .padding(.top, 4)
                }
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 20)
        }
        }
        
        // Bottom Button with Safe Area Support
        Button(action: {
          showingRouteBuilder = true
        }) {
          HStack(spacing: 8) {
            Text("Los geht's!")
              .font(.headline)
              .fontWeight(.medium)
            
            Image(systemName: "arrow.right")
              .font(.system(size: 16, weight: .medium))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(startingCity.isEmpty ? .gray : .blue)
          )
        }
        .disabled(startingCity.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(.regularMaterial.opacity(0.8))
        .accessibilityLabel("Los geht's!")
        .accessibilityHint("Startet deine Abenteuer-Tour!")
      }
      .navigationTitle("Lass uns loslegen!")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingRouteBuilder) {
        // TODO: Update RouteBuilderView to use new parameters in Phase 4
        RouteBuilderView(
          startingCity: startingCity,
          startingCoordinates: startingCoordinates,
          numberOfPlaces: numberOfPlaces, // Legacy - bis RouteBuilderView aktualisiert ist
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          customEndpointCoordinates: customEndpointCoordinates,
          routeLength: routeLength, // Legacy - bis RouteBuilderView aktualisiert ist
          onRouteGenerated: onRouteGenerated
        )
      }
      .onAppear {
        loadDefaultSettings()
      }
      .alert("Startort Info", isPresented: $showingStartPointInfo) {
        Button("Alles klar!") { }
      } message: {
        Text("Sag mir einfach, wo wir starten sollen! Ich finde dann automatisch coole Orte in der Nähe.")
      }
      .alert("Maximum Stopps Info", isPresented: $showingStopsInfo) {
        Button("Verstanden!") { }
      } message: {
        Text("Wie viele Stopps sollen maximal in deiner Route sein? Ich finde die besten Orte, aber es können auch weniger werden!")
      }
      .alert("Gehzeit Info", isPresented: $showingWalkingTimeInfo) {
        Button("Passt!") { }
      } message: {
        Text("Wie lange möchtest du maximal laufen? Wenn die Route länger wird, entferne ich automatisch Stopps bis die Zeit stimmt!")
      }
      .alert("Mindestabstand Info", isPresented: $showingPOIDistanceInfo) {
        Button("Macht Sinn!") { }
      } message: {
        Text("Wie weit sollen die Orte mindestens voneinander entfernt sein? Größere Abstände = weniger Stopps, aber mehr Abwechslung!")
      }
      .alert("Ziel Info", isPresented: $showingEndpointInfo) {
        Button("Macht Sinn!") { }
      } message: {
        Text("Wo soll's am Ende hingehen?\n• Rundreise: Zurück zum Start\n• Stopp: Einfach am letzten Ort bleiben\n• Custom: Du bestimmst das Ziel!")
      }
    }
  }
  
  private func loadDefaultSettings() {
    // Migration durchführen falls nötig
    settingsManager.settings.migrateToNewSettings()
    
    // Load default values from profile settings, but only if not already set
    let legacyDefaults = settingsManager.settings.getDefaultsForRoutePlanning()
    let newDefaults = settingsManager.settings.getNewDefaultsForRoutePlanning()
    
    // Legacy migration für bestehende Einstellungen
    if numberOfPlaces == 3 { // Legacy support
      numberOfPlaces = legacyDefaults.0
    }
    
    if endpointOption == .roundtrip { // Only update if still at default value
      endpointOption = newDefaults.1
    }
    
    if routeLength == .medium { // Legacy support
      routeLength = legacyDefaults.2
    }
    
    if customEndpoint.isEmpty { // Only update if empty
      customEndpoint = newDefaults.4
    }
    
    // Neue Settings laden
    if maximumStops == .five {
      maximumStops = newDefaults.0
    }
    if maximumWalkingTime == .sixtyMin {
      maximumWalkingTime = newDefaults.2
    }
    if minimumPOIDistance == .twoFifty {
      minimumPOIDistance = newDefaults.3
    }
  }
}