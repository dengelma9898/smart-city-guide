import SwiftUI
import MapKit

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var settingsManager = ProfileSettingsManager.shared
  @StateObject private var locationService = LocationManagerService.shared // Phase 3

  
  @State private var startingCity = ""
  @State private var startingCoordinates: CLLocationCoordinate2D? = nil // NEW: Store coordinates
  @State private var usingCurrentLocation = false // Phase 3: Track if using current location
  @State private var planningMode: RoutePlanningMode = .automatic // NEW: Planning mode selection
  @State private var maximumStops: MaximumStops = .five
  @State private var endpointOption: EndpointOption = .roundtrip
  @State private var customEndpoint = ""
  @State private var customEndpointCoordinates: CLLocationCoordinate2D? = nil // NEW: Store endpoint coordinates
  @State private var maximumWalkingTime: MaximumWalkingTime = .sixtyMin
  @State private var minimumPOIDistance: MinimumPOIDistance = .twoFifty
  @State private var showingRouteBuilder = false
  @State private var showingManualPlanning = false // NEW: Show manual planning sheet
  @State private var showingStartPointInfo = false
  @State private var showingStopsInfo = false
  @State private var showingWalkingTimeInfo = false
  @State private var showingPOIDistanceInfo = false
  @State private var showingEndpointInfo = false
  @State private var hasLoadedDefaults = false // Track if defaults have been loaded
  @State private var didUserInteract = false // Prevent defaults from overwriting user choices
  
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
            
            // Planning Mode Selection Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "slider.horizontal.3")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Wie möchtest du planen?")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              HStack(spacing: 8) {
                ForEach(RoutePlanningMode.allCases, id: \.self) { mode in
                  planningModeButton(mode)
                }
              }
              .accessibilityElement(children: .contain)
              .accessibilityLabel("Planungsmodus wählen")
            }
            
            // Conditional Parameter Display - Show complex parameters only for automatic mode
            if planningMode == .automatic {
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
              .onChange(of: maximumStops) { _, _ in didUserInteract = true }
              
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
              .onChange(of: maximumWalkingTime) { _, _ in didUserInteract = true }
              
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
              .onChange(of: minimumPOIDistance) { _, _ in didUserInteract = true }
            }
            
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
                  endpointOptionButton(option)
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
          // Diagnostics: log the exact parameters the user selected before we open the builder
          SecureLogger.shared.logInfo(
            "🧭 UI Params → start='\(usingCurrentLocation ? "Mein Standort" : startingCity)' stops=\(maximumStops.rawValue) maxTime=\(maximumWalkingTime.rawValue) minDist=\(minimumPOIDistance.rawValue) currentLocation=\(usingCurrentLocation)",
            category: .ui
          )
          if planningMode == .automatic {
            showingRouteBuilder = true
          } else {
            showingManualPlanning = true
          }
        }) {
          HStack(spacing: 8) {
            Text(planningMode == .automatic ? "Los geht's!" : "POIs entdecken!")
              .font(.headline)
              .fontWeight(.medium)
            
            Image(systemName: planningMode == .automatic ? "arrow.right" : "magnifyingglass")
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
        .accessibilityLabel(planningMode == .automatic ? "Los geht's!" : "POIs entdecken!")
        .accessibilityHint(planningMode == .automatic ? "Startet deine Abenteuer-Tour!" : "Entdecke interessante Orte für deine manuelle Route!")
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
      .sheet(isPresented: $showingManualPlanning) {
        ManualRoutePlanningView(
          config: ManualRouteConfig(
            startingCity: startingCity,
            startingCoordinates: startingCoordinates,
            usingCurrentLocation: usingCurrentLocation,
            endpointOption: endpointOption,
            customEndpoint: customEndpoint,
            customEndpointCoordinates: customEndpointCoordinates
          ),
          onRouteGenerated: onRouteGenerated
        )
      }
      .onAppear {
        loadDefaultSettings()
        // UITEST autopilot: drive manual flow end-to-end for simulator verification
        if ProcessInfo.processInfo.arguments.contains("-UITEST_AUTOPILOT_MANUAL") {
          // Provide a deterministic city and open manual planning automatically
          if startingCity.isEmpty {
            startingCity = "Nürnberg"
          }
          planningMode = .manual
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showingManualPlanning = true
          }
        }
      }
      .onChange(of: settingsManager.isLoading) { _, isLoading in
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
  
  // MARK: - Subviews to help type-checker
  @ViewBuilder
  private func planningModeButton(_ mode: RoutePlanningMode) -> some View {
    Button(action: {
      planningMode = mode
    }) {
      Text(mode.rawValue)
        .font(.body)
        .fontWeight(.medium)
        .foregroundColor(planningMode == mode ? .white : .blue)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(planningMode == mode ? .blue : Color(.systemGray6))
        )
    }
    .accessibilityLabel("\(mode.rawValue) Modus")
    .accessibilityIdentifier("Planungsmodus.\(mode.rawValue)")
    .accessibilityValue(planningMode == mode ? "selected" : "not-selected")
    .accessibilityAddTraits(planningMode == mode ? .isSelected : [])
  }

  @ViewBuilder
  private func endpointOptionButton(_ option: EndpointOption) -> some View {
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
    .accessibilityIdentifier("Ziel.\(option.rawValue)")
    .accessibilityValue(endpointOption == option ? "selected" : "not-selected")
    .accessibilityAddTraits(endpointOption == option ? .isSelected : [])
  }
  private func loadDefaultSettings() {
    // Don't apply while settings are still loading
    guard !settingsManager.isLoading else {
      return
    }
    
    // Only load defaults once per view instance to preserve user's active selections
    guard !hasLoadedDefaults else {
      return
    }
    
    // Do not overwrite if the user already interacted with option chips
    guard !didUserInteract else { return }
    
    // Load default values from profile settings
    let newDefaults = settingsManager.settings.getNewDefaultsForRoutePlanning()
    
    // Apply all settings defaults
    maximumStops = newDefaults.0
    endpointOption = newDefaults.1
    maximumWalkingTime = newDefaults.2
    minimumPOIDistance = newDefaults.3
    customEndpoint = newDefaults.4
    
    // Mark as loaded to prevent reloading
    hasLoadedDefaults = true
    
    SecureLogger.shared.logDebug("📱 RoutePlanningView: Loaded settings defaults - Stops: \(maximumStops.rawValue), Time: \(maximumWalkingTime.rawValue), Distance: \(minimumPOIDistance.rawValue)", category: .ui)
  }
}