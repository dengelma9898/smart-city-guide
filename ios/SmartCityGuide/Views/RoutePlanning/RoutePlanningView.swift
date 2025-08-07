import SwiftUI
import MapKit

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var settingsManager = ProfileSettingsManager()
  @StateObject private var locationService = LocationManagerService.shared // Phase 3

  
  @State private var startingCity = ""
  @State private var startingCoordinates: CLLocationCoordinate2D? = nil // NEW: Store coordinates
  @State private var usingCurrentLocation = false // Phase 3: Track if using current location
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
              
              if !usingCurrentLocation {
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
              } else {
                // Phase 3: Current Location Display
                HStack {
                  Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                  
                  Text("Mein Standort")
                    .font(.body)
                    .foregroundColor(.primary)
                  
                  if let location = locationService.currentLocation {
                    Text("(\(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude)))")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  Spacer()
                  
                  Button(action: {
                    usingCurrentLocation = false
                    startingCity = ""
                    startingCoordinates = nil
                  }) {
                    Image(systemName: "xmark.circle.fill")
                      .foregroundColor(.gray)
                      .font(.system(size: 20))
                  }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                )
              }
              
              // Phase 3: "Meinen Standort verwenden" Button
              if !usingCurrentLocation && locationService.isLocationAuthorized {
                Button(action: {
                  if let currentLocation = locationService.currentLocation {
                    usingCurrentLocation = true
                    startingCity = "Mein Standort"
                    startingCoordinates = currentLocation.coordinate
                  }
                }) {
                  HStack {
                    Image(systemName: "location.fill")
                      .font(.system(size: 16))
                    Text("Meinen Standort verwenden")
                      .font(.body)
                      .fontWeight(.medium)
                  }
                  .foregroundColor(.blue)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 10)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color.blue, lineWidth: 1)
                  )
                }
                .disabled(locationService.currentLocation == nil)
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
              .fill((startingCity.isEmpty && !usingCurrentLocation) ? .gray : .blue)
          )
        }
        .disabled(startingCity.isEmpty && !usingCurrentLocation)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(.regularMaterial.opacity(0.8))
        .accessibilityLabel("Los geht's!")
        .accessibilityHint("Startet deine Abenteuer-Tour!")
      }
      .opacity(settingsManager.isLoading ? 0.4 : 1.0)
      .animation(.easeInOut(duration: 0.4), value: settingsManager.isLoading)
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
        RouteBuilderView(
          startingCity: startingCity,
          startingCoordinates: startingCoordinates,
          usingCurrentLocation: usingCurrentLocation, // Phase 3
          maximumStops: maximumStops,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          customEndpointCoordinates: customEndpointCoordinates,
          maximumWalkingTime: maximumWalkingTime,
          minimumPOIDistance: minimumPOIDistance,
          onRouteGenerated: onRouteGenerated
        )
      }
      .onAppear {
        loadDefaultSettings()
      }
      .onChange(of: settingsManager.isLoading) { isLoading in
        if !isLoading {
          withAnimation(.easeInOut(duration: 0.3)) {
            loadDefaultSettings()
          }
        }
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
    // Don't apply while settings are still loading
    guard !settingsManager.isLoading else {
      return
    }
    
    // Load default values from profile settings ONLY if still at initial defaults
    // This preserves user's active selections while providing intelligent defaults for new users
    
    let newDefaults = settingsManager.settings.getNewDefaultsForRoutePlanning()
    
    // Only load defaults if user hasn't changed from initial values
    if endpointOption == .roundtrip {
      endpointOption = newDefaults.1
    }
    
    if customEndpoint.isEmpty {
      customEndpoint = newDefaults.4
    }
    
    // Load user's preferred defaults for new filter options (ONLY on first load)
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