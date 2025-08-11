import SwiftUI
import MapKit

// MARK: - Route Builder View (Next Step)
struct RouteBuilderView: View {
  @Environment(\.dismiss) private var dismiss
  // Source indicates if we show an already generated manual route or generate automatically
  let routeSource: RouteSource
  // When manual: we receive a ready route and optionally discovered POIs to power the edit flow
  let manualInitialRoute: GeneratedRoute?
  let initialDiscoveredPOIs: [POI]?
  let startingCity: String
  let startingCoordinates: CLLocationCoordinate2D?
  let usingCurrentLocation: Bool // Phase 3: Current Location flag
  let endpointOption: EndpointOption
  let customEndpoint: String
  let customEndpointCoordinates: CLLocationCoordinate2D?
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  // New enhanced parameters
  let maximumStops: MaximumStops?
  let maximumWalkingTime: MaximumWalkingTime?
  let minimumPOIDistance: MinimumPOIDistance?
  
  // Legacy parameters (for backwards compatibility)
  let numberOfPlaces: Int?
  let routeLength: RouteLength?
  
  // MARK: - Enhanced Initializer
  init(
    startingCity: String,
    startingCoordinates: CLLocationCoordinate2D?,
    usingCurrentLocation: Bool = false, // Phase 3
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    customEndpointCoordinates: CLLocationCoordinate2D?,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    onRouteGenerated: @escaping (GeneratedRoute) -> Void
  ) {
    self.routeSource = .automatic
    self.manualInitialRoute = nil
    self.initialDiscoveredPOIs = nil
    self.startingCity = startingCity
    self.startingCoordinates = startingCoordinates
    self.usingCurrentLocation = usingCurrentLocation
    self.endpointOption = endpointOption
    self.customEndpoint = customEndpoint
    self.customEndpointCoordinates = customEndpointCoordinates
    self.onRouteGenerated = onRouteGenerated
    
    // New parameters
    self.maximumStops = maximumStops
    self.maximumWalkingTime = maximumWalkingTime
    self.minimumPOIDistance = minimumPOIDistance
    
    // Legacy parameters (nil for new initializer)
    self.numberOfPlaces = nil
    self.routeLength = nil
  }
  
  // MARK: - Legacy Initializer (for backwards compatibility)
  init(
    startingCity: String,
    startingCoordinates: CLLocationCoordinate2D?,
    numberOfPlaces: Int,
    endpointOption: EndpointOption,
    customEndpoint: String,
    customEndpointCoordinates: CLLocationCoordinate2D?,
    routeLength: RouteLength,
    onRouteGenerated: @escaping (GeneratedRoute) -> Void
  ) {
    self.routeSource = .automatic
    self.manualInitialRoute = nil
    self.initialDiscoveredPOIs = nil
    self.startingCity = startingCity
    self.startingCoordinates = startingCoordinates
    self.usingCurrentLocation = false // Legacy initializer defaults to false
    self.endpointOption = endpointOption
    self.customEndpoint = customEndpoint
    self.customEndpointCoordinates = customEndpointCoordinates
    self.onRouteGenerated = onRouteGenerated
    
    // Legacy parameters
    self.numberOfPlaces = numberOfPlaces
    self.routeLength = routeLength
    
    // Convert legacy to new parameters
    self.maximumStops = MaximumStops.allCases.first { $0.intValue == numberOfPlaces } ?? .five
    self.maximumWalkingTime = Self.convertLegacyRouteLength(routeLength)
    self.minimumPOIDistance = .twoFifty // Default value
  }

  // MARK: - Manual Initializer
  init(
    manualRoute: GeneratedRoute,
    config: ManualRouteConfig,
    discoveredPOIs: [POI],
    onRouteGenerated: @escaping (GeneratedRoute) -> Void
  ) {
    self.routeSource = .manual(config)
    self.manualInitialRoute = manualRoute
    self.initialDiscoveredPOIs = discoveredPOIs
    // Map shared inputs for UI context
    self.startingCity = config.startingCity
    self.startingCoordinates = config.startingCoordinates
    self.usingCurrentLocation = config.usingCurrentLocation
    self.endpointOption = config.endpointOption
    self.customEndpoint = config.customEndpoint
    self.customEndpointCoordinates = config.customEndpointCoordinates
    self.onRouteGenerated = onRouteGenerated
    // No generation needed
    self.maximumStops = nil
    self.maximumWalkingTime = nil
    self.minimumPOIDistance = nil
    self.numberOfPlaces = nil
    self.routeLength = nil
  }
  
  // MARK: - Helper Functions
  
  /// Extrahiert nur den Stadtnamen aus einer Vollständigen Adresse
  /// Beispiele: "Bienenweg 4, 90537 Feucht" → "Feucht", "Berlin" → "Berlin"
  private func extractCityName(from fullAddress: String) -> String {
    let trimmed = fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Split by comma and take the last part (meist Stadt + Land)
    let parts = trimmed.components(separatedBy: ",")
    let lastPart = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? trimmed
    
    // Split by spaces and find the city after postal code
    let words = lastPart.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    // Finde Wort nach Postleitzahl (5 Zahlen) oder nehme letztes Wort
    for i in 0..<words.count {
      let word = words[i]
      // Ist das eine deutsche Postleitzahl? (5 Zahlen)
      if word.count == 5 && word.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
        // Nehme das nächste Wort als Stadt
        if i + 1 < words.count {
          return words[i + 1]
        }
      }
    }
    
    // Fallback: Nehme das letzte Wort (meist Stadt)
    return words.last ?? trimmed
  }
  
  private static func convertLegacyRouteLength(_ routeLength: RouteLength) -> MaximumWalkingTime {
    switch routeLength {
    case .short:
      return .thirtyMin
    case .medium:
      return .sixtyMin
    case .long:
      return .twoHours
    }
  }
  
  private func generateOptimalRoute() async {
    // Use new or legacy parameters based on availability
    if let maximumStops = maximumStops,
       let maximumWalkingTime = maximumWalkingTime,
       let minimumPOIDistance = minimumPOIDistance {
      
      // Phase 3: Check if using current location
      if usingCurrentLocation, let coordinates = startingCoordinates {
        // Use current location route generation
        let currentLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        await routeService.generateRoute(
          fromCurrentLocation: currentLocation,
          maximumStops: maximumStops,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          maximumWalkingTime: maximumWalkingTime,
          minimumPOIDistance: minimumPOIDistance,
          availablePOIs: discoveredPOIs
        )
      } else {
        // Use city-based route generation
        await routeService.generateRoute(
          startingCity: startingCity,
          maximumStops: maximumStops,
          endpointOption: endpointOption,
          customEndpoint: customEndpoint,
          maximumWalkingTime: maximumWalkingTime,
          minimumPOIDistance: minimumPOIDistance,
          availablePOIs: discoveredPOIs
        )
      }
    } else if let numberOfPlaces = numberOfPlaces,
              let routeLength = routeLength {
      // Use legacy route generation
      await routeService.generateRoute(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength,
        availablePOIs: discoveredPOIs
      )
    }
  }
  
  @StateObject private var routeService = RouteService()
  @StateObject private var historyManager = RouteHistoryManager()
  @StateObject private var geoapifyService = GeoapifyAPIService.shared
  @StateObject private var wikipediaService = WikipediaService.shared
  
  @State private var discoveredPOIs: [POI] = []
  @State private var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:] // POI.id -> EnrichedPOI
  @State private var isLoadingPOIs = false
  @State private var isEnrichingRoutePOIs = false
  @State private var isEnrichingAllPOIs = false
  @State private var enrichmentProgress = 0.0
  
  // Full-Screen Image Modal States
  @State private var showFullScreenImage = false
  @State private var fullScreenImageURL: String = ""
  @State private var fullScreenImageTitle: String = ""
  @State private var fullScreenWikipediaURL: String = ""
  
  // Route Edit States
  @State private var showingEditView = false
  @State private var editingWaypointIndex: Int?
  @State private var editableSpot: EditableRouteSpot?
  
  // Route Edit History (track replaced POIs by waypoint index)
  @State private var replacedPOIsHistory: [Int: [POI]] = [:]
  
  // MARK: - Computed Properties
  
  private var loadingStateText: String {
    if isLoadingPOIs {
      return "Entdecke coole Orte..."
    } else if routeService.isGenerating {
      return "Optimiere deine Route..."
    } else if isEnrichingRoutePOIs {
      return "Lade Wikipedia-Infos..."
    } else {
      return "Bereite vor..."
    }
  }
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          if (routeSource.isManual && routeService.generatedRoute == nil) || isLoadingPOIs || routeService.isGenerating || isEnrichingRoutePOIs {
            // Header - only show during generation
            VStack(spacing: 12) {
              Text("Wir basteln deine Route!")
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("Suchen die coolsten \(maximumStops?.intValue ?? 5) Stopps in \(startingCity) für dich!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            
            // Loading State
            VStack(spacing: 16) {
              ProgressView()
                .scaleEffect(1.2)
              
              Text(loadingStateText)
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
          } else if let route = routeService.generatedRoute {
            // Success State - Show Generated Route
            VStack(spacing: 20) {
              
              // Waypoints List
              VStack(alignment: .leading, spacing: 12) {
                Text("Deine Tour im Detail")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                  VStack(spacing: 0) {
                    // Waypoint info
                    HStack(spacing: 12) {
                      ZStack {
                        Circle()
                          .fill(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
                          .frame(width: 28, height: 28)
                        
                        if index == 0 {
                          Image(systemName: "figure.walk")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        } else if index == route.waypoints.count - 1 {
                          Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        } else {
                          Image(systemName: waypoint.category.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        }
                      }
                      
                      VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                          // Display-friendly name: show "Ziel" for last waypoint on roundtrip/lastPlace, or custom name when provided
                          let displayName: String = {
                            if index == 0 { return "Start" }
                            if index == route.waypoints.count - 1 {
                              switch endpointOption {
                              case .custom:
                                return customEndpoint.isEmpty ? "Ziel" : customEndpoint
                              default:
                                return "Ziel"
                              }
                            }
                            return waypoint.name
                          }()
                          Text(displayName)
                            .font(.body)
                            .fontWeight(.medium)
                          
                          // Category indicator (only for intermediate stops)
                          if index > 0 && index < route.waypoints.count - 1 {
                            HStack(spacing: 4) {
                              Text(waypoint.category.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                              Capsule()
                                .fill(waypoint.category.color)
                            )
                          }
                        }
                        
                        Text(waypoint.address)
                          .font(.caption)
                          .foregroundColor(.secondary)
                          .lineLimit(2)
                        
                        // Additional information if available
                        if let phoneNumber = waypoint.phoneNumber {
                          Button(action: {
                            if let phoneURL = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                              UIApplication.shared.open(phoneURL)
                            }
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "phone.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                          }
                        }
                        
                        if let url = waypoint.url {
                          Button(action: {
                            UIApplication.shared.open(url)
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "link")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(url.host ?? url.absoluteString)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                            }
                          }
                        }
                        
                        // E-Mail-Adresse
                        if let email = waypoint.emailAddress {
                          Button(action: {
                            if let emailURL = URL(string: "mailto:\(email)") {
                              UIApplication.shared.open(emailURL)
                            }
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "envelope.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(email)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                            }
                          }
                        }
                        
                        // Öffnungszeiten
                        if let hours = waypoint.operatingHours, !hours.isEmpty {
                          HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                              .font(.system(size: 10))
                              .foregroundColor(.orange)
                            Text(hours)
                              .font(.caption)
                              .foregroundColor(.secondary)
                              .lineLimit(2)
                          }
                        }
                        
                        // Wikipedia-Informationen (nur für POI-Waypoints)
                        if index > 0 && index < route.waypoints.count - 1 {
                          wikipediaInfoView(for: waypoint)
                        }
                      }
                      
                      Spacer()
                      
                      // Edit button (only for intermediate waypoints)
                      if index > 0 && index < route.waypoints.count - 1 {
                        Button(action: {
                          editWaypoint(at: index)
                        }) {
                          Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                      }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                    )
                    
                    // Walking time indicator (if not the last waypoint)
                    if index < route.waypoints.count - 1 {
                      VStack(spacing: 4) {
                        Rectangle()
                          .fill(Color(.systemGray4))
                          .frame(width: 2, height: 20)
                        
                        HStack(spacing: 6) {
                          Image(systemName: "figure.walk")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                          
                          let walkingTime = route.walkingTimes[index]
                          let walkingDistance = route.walkingDistances[index]
                          
                          Text("\(Int(walkingTime / 60)) min • \(Int(walkingDistance)) m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                          Capsule()
                            .fill(Color(.systemGray5))
                        )
                        
                        Rectangle()
                          .fill(Color(.systemGray4))
                          .frame(width: 2, height: 20)
                      }
                    }
                  }
                }
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Route Summary
              VStack(spacing: 12) {
                HStack(spacing: 24) {
                  VStack {
                    Text("\(Int(route.totalDistance / 1000)) km")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Deine Strecke")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text(formatExperienceTime(route.totalExperienceTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Deine Zeit")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text("\(route.numberOfStops)")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Coole Stopps")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Time Breakdown
              VStack(alignment: .leading, spacing: 12) {
                Text("So sieht's aus")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("🚶‍♂️ Laufen")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalTravelTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.blue)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("📍 Entdecken")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalVisitTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.orange)
                  }
                }
                
                HStack {
                  Text("⏱️ Dein ganzes Abenteuer:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                  Spacer()
                  Text(formatExperienceTime(route.totalExperienceTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                )
                
                Text("💡 Rechnen mit 30-60 Min pro Stopp - ohne Start und Ziel")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.top, 4)
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Background Enrichment Status
              if isEnrichingAllPOIs {
                VStack(spacing: 8) {
                  HStack(spacing: 8) {
                    ProgressView()
                      .scaleEffect(0.8)
                    Text("Wikipedia-Daten für weitere POIs werden im Hintergrund geladen...")
                      .font(.caption)
                      .foregroundColor(.secondary)
                    Spacer()
                  }
                  
                  ProgressView(value: enrichmentProgress)
                    .tint(.blue)
                    .scaleEffect(y: 0.8)
                  
                  Text("\(Int(enrichmentProgress * 100))% abgeschlossen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBlue).opacity(0.1))
                )
              }
              
              // Use Route Button
              Button(action: {
                onRouteGenerated(route)
                
                // Phase 4: Start proximity monitoring for the active route
                Task {
                  await ProximityService.shared.startProximityMonitoring(for: route)
                }
                
                dismiss()
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "map")
                    .font(.system(size: 18, weight: .medium))
                  Text("Zeig mir die Tour!")
                    .font(.headline)
                    .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(.blue)
                )
              }
              .accessibilityIdentifier("route.start.button")
            }
            
          } else if let error = routeService.errorMessage {
            // Error State
            VStack(spacing: 16) {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
              
              Text("Ups, da lief was schief!")
                .font(.headline)
                .fontWeight(.semibold)
              
              Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
              
              Button("Nochmal probieren!") {
                Task {
                  await generateOptimalRoute()
                }
              }
              .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 40)
          }
          
          Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
      }
      .accessibilityIdentifier("route.builder.screen")
      .navigationTitle(routeSource.isManual ? "Deine manuelle Route!" : "Deine Tour entsteht!")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      routeService.setHistoryManager(historyManager)
      // Manual source: seed the route and POIs so we show preview immediately
      if case .manual = routeSource {
        print("🟦 RouteBuilderView.onAppear: routeSource=manual, seeding data…")
        if let r = manualInitialRoute {
          routeService.generatedRoute = r
          print("🟩 RouteBuilderView: seeded generatedRoute with \(r.waypoints.count) waypoints")
        } else {
          print("🟥 RouteBuilderView: manualInitialRoute is nil")
        }
        if let pois = initialDiscoveredPOIs {
          discoveredPOIs = pois
          print("🟩 RouteBuilderView: seeded discoveredPOIs = \(pois.count)")
        } else {
          discoveredPOIs = []
          print("🟥 RouteBuilderView: initialDiscoveredPOIs is nil, using []")
        }
        // trigger a small refresh to ensure body re-evaluates after seeding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          withAnimation(.easeInOut(duration: 0.1)) { }
        }
      }
    }
    .task {
      // Skip auto-generation when manual route is provided
      if case .automatic = routeSource {
        await loadPOIsAndGenerateRoute()
      }
    }
    .fullScreenCover(isPresented: $showFullScreenImage) {
      FullScreenImageView(
        imageURL: fullScreenImageURL,
        title: fullScreenImageTitle,
        wikipediaURL: fullScreenWikipediaURL.isEmpty ? nil : fullScreenWikipediaURL,
        isPresented: $showFullScreenImage
      )
    }
    .sheet(isPresented: $showingEditView) {
      if let editableSpot = editableSpot {
        RouteEditView(
          originalRoute: routeService.generatedRoute!,
          editableSpot: editableSpot,
          cityName: startingCity,
          allDiscoveredPOIs: discoveredPOIs,
          onSpotChanged: handleSpotChange,
          onCancel: handleEditCancel
        )
      }
    }
  }
  
  // MARK: - POI Loading and Route Generation
  
  private func loadPOIsAndGenerateRoute() async {
    do {
      // Step 1: Load POIs from Geoapify API (MIGRATION TESTING: Distance filtering disabled)
      isLoadingPOIs = true
      
      // 🚀 USE DIRECT COORDINATES if available (eliminates geocoding!)
      if let coordinates = startingCoordinates {
                    // Direct coordinates available - skip geocoding
        
        discoveredPOIs = try await geoapifyService.fetchPOIs(
          at: coordinates,
          cityName: startingCity,
          categories: PlaceCategory.geoapifyEssentialCategories
        )
      } else {
                    // No coordinates available - will use geocoding
        
        discoveredPOIs = try await geoapifyService.fetchPOIs(
          for: startingCity,
          categories: PlaceCategory.geoapifyEssentialCategories
        )
      }
      
                // POIs loaded successfully
      isLoadingPOIs = false
      
      // Step 2: Generate route using discovered POIs
      await generateOptimalRoute()
      
      // Step 3: 2-Phase Wikipedia Enrichment
      if let generatedRoute = routeService.generatedRoute {
        await enrichRouteWithWikipedia(route: generatedRoute)
      }
      
    } catch {
      isLoadingPOIs = false
                // Error will be displayed via errorMessage
      routeService.errorMessage = "Konnte keine coolen Orte finden: \(error.localizedDescription)"
    }
  }
  
  // MARK: - Wikipedia Enrichment (2-Phase Strategy)
  
  /// Phase 1: Enrich nur die POIs in der generierten Route (schnell für UI)
  private func enrichRouteWithWikipedia(route: GeneratedRoute) async {
    isEnrichingRoutePOIs = true
    
    do {
      // Extrahiere die POIs aus den Route-Waypoints (ohne Start/End)
      let routePOIs = extractPOIsFromRoute(route: route)
      
      print("📚 [Phase 1] Enriching \(routePOIs.count) route POIs with Wikipedia...")
      
      // Enriche nur die Route-POIs
      let cityName = extractCityName(from: startingCity)
      print("📚 Using extracted city name '\(cityName)' from '\(startingCity)' for Wikipedia enrichment")
      let enrichedRoutePOIs = try await wikipediaService.enrichPOIs(routePOIs, cityName: cityName)
      
      // Speichere enriched POIs in Dictionary für schnellen Zugriff
      await MainActor.run {
        for enrichedPOI in enrichedRoutePOIs {
          enrichedPOIs[enrichedPOI.basePOI.id] = enrichedPOI
        }
        isEnrichingRoutePOIs = false
      }
      
      let successCount = enrichedRoutePOIs.filter { $0.wikipediaData != nil }.count
      print("📚 [Phase 1] Route enrichment completed: \(successCount)/\(routePOIs.count) successful")
      
      // Phase 2: Enriche alle anderen POIs im Hintergrund
      await enrichAllPOIsInBackground()
      
    } catch {
      isEnrichingRoutePOIs = false
      print("📚 [Phase 1] Route enrichment failed: \(error.localizedDescription)")
      
      // Starte trotzdem Phase 2
      await enrichAllPOIsInBackground()
    }
  }
  
  /// Phase 2: Enriche alle gefundenen POIs im Hintergrund (für zukünftige Features)
  private func enrichAllPOIsInBackground() async {
    await MainActor.run {
      isEnrichingAllPOIs = true
    }
    
    // Filtere POIs die noch nicht enriched wurden
    let unenrichedPOIs = discoveredPOIs.filter { poi in
      enrichedPOIs[poi.id] == nil
    }
    
    guard !unenrichedPOIs.isEmpty else {
      await MainActor.run {
        isEnrichingAllPOIs = false
      }
      print("📚 [Phase 2] All POIs already enriched")
      return
    }
    
    print("📚 [Phase 2] Background enriching \(unenrichedPOIs.count) additional POIs...")
    
    // Enriche im Hintergrund (mit langsamerer Rate für bessere UX)
    let cityName = extractCityName(from: startingCity)
    var completedCount = 0
    for poi in unenrichedPOIs {
      do {
        let enrichedPOI = try await wikipediaService.enrichPOI(poi, cityName: cityName)
        
        await MainActor.run {
          enrichedPOIs[enrichedPOI.basePOI.id] = enrichedPOI
          completedCount += 1
          enrichmentProgress = Double(completedCount) / Double(unenrichedPOIs.count)
        }
        
        // Längere Pause für Hintergrund-Enrichment
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
      } catch {
        print("📚 [Phase 2] Failed to enrich POI '\(poi.name)': \(error.localizedDescription)")
      }
    }
    
    await MainActor.run {
      isEnrichingAllPOIs = false
      enrichmentProgress = 1.0
    }
    
    let totalEnriched = enrichedPOIs.values.filter { $0.wikipediaData != nil }.count
    print("📚 [Phase 2] Background enrichment completed: \(totalEnriched)/\(discoveredPOIs.count) total enriched")
  }
  
  /// Extrahiert POI-Objekte aus den Route-Waypoints
  private func extractPOIsFromRoute(route: GeneratedRoute) -> [POI] {
    var routePOIs: [POI] = []
    
    // Waypoints ohne Start/End (Index 0 und letzter)
    let poiWaypoints = Array(route.waypoints.dropFirst().dropLast())
    
    for waypoint in poiWaypoints {
      // Finde das ursprüngliche POI basierend auf Koordinaten und Name
      if let originalPOI = discoveredPOIs.first(where: { poi in
        let nameMatch = poi.name.lowercased() == waypoint.name.lowercased()
        let coordinateMatch = abs(poi.coordinate.latitude - waypoint.coordinate.latitude) < 0.001 &&
                              abs(poi.coordinate.longitude - waypoint.coordinate.longitude) < 0.001
        return nameMatch || coordinateMatch
      }) {
        routePOIs.append(originalPOI)
      }
    }
    
    return routePOIs
  }
  
  // MARK: - UI Helper Methods
  
  /// Erstellt Wikipedia-Info-View für einen Waypoint
  @ViewBuilder
  private func wikipediaInfoView(for waypoint: RoutePoint) -> some View {
    // Finde entsprechende enriched POI
    if let enrichedPOI = findEnrichedPOI(for: waypoint) {
      VStack(alignment: .leading, spacing: 6) {
        
        // Wikipedia-Artikel gefunden
        if let wikipediaData = enrichedPOI.wikipediaData {
          
          // Wikipedia-Badge + Qualitäts-Indikator
          HStack(spacing: 6) {
            HStack(spacing: 4) {
              Image(systemName: "book.fill")
                .font(.system(size: 10))
                .foregroundColor(.blue)
              Text("Wikipedia")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            
            // Qualitäts-Score
            if enrichedPOI.isHighQuality {
              Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(.yellow)
            }
            
            Spacer()
            
            // Link-Button
            if let pageURL = enrichedPOI.wikipediaURL,
               let url = URL(string: pageURL) {
              Button(action: {
                UIApplication.shared.open(url)
              }) {
                Image(systemName: "arrow.up.right.square")
                  .font(.system(size: 12))
                  .foregroundColor(.blue)
              }
            }
          }
          
          // Wikipedia-Beschreibung (gekürzt)
          if let extract = wikipediaData.extract {
            Text(String(extract.prefix(120)) + (extract.count > 120 ? "..." : ""))
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(3)
              .fixedSize(horizontal: false, vertical: true)
          } else if let description = wikipediaData.description {
            Text(description)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
          
          // Wikipedia-Bild (optimiert für bessere Sichtbarkeit)
          if let imageURL = enrichedPOI.wikipediaImageURL,
             let url = URL(string: imageURL) {
            HStack(spacing: 12) {
              AsyncImage(url: url) { imagePhase in
                switch imagePhase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Zeige ganzes Bild
                    .frame(width: 80, height: 50) // Kompakte Größe
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                case .failure(_), .empty:
                  RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 50)
                    .overlay(
                      Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    )
                @unknown default:
                  EmptyView()
                }
              }
              
              VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                  Image(systemName: "camera.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                  Text("Wikipedia Foto")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
                
                Text("Tap für Vollbild")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              
              Spacer()
            }
            .contentShape(Rectangle()) // Gesamte Fläche anklickbar
            .onTapGesture {
              // ✅ In-App Vollbild statt Browser
              fullScreenImageURL = imageURL
              fullScreenImageTitle = enrichedPOI.wikipediaData?.title ?? enrichedPOI.basePOI.name
              fullScreenWikipediaURL = enrichedPOI.wikipediaURL ?? ""
              showFullScreenImage = true
            }
          }
          
        } else {
          // Enrichment läuft noch oder fehlgeschlagen
          if isEnrichingRoutePOIs {
            HStack(spacing: 6) {
              ProgressView()
                .scaleEffect(0.8)
              Text("Lade Wikipedia-Info...")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          } else {
            HStack(spacing: 4) {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)
              Text("Keine Wikipedia-Info gefunden")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }
      .padding(.top, 4)
      
    } else if isEnrichingRoutePOIs {
      // POI wird noch gesucht
      HStack(spacing: 6) {
        ProgressView()
          .scaleEffect(0.8)
        Text("Lade Wikipedia-Info...")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.top, 4)
    }
  }
  
  /// Findet die enriched POI für einen gegebenen Waypoint
  private func findEnrichedPOI(for waypoint: RoutePoint) -> WikipediaEnrichedPOI? {
    // Suche über POI-ID (effizienteste Methode)
    for (_, enrichedPOI) in enrichedPOIs {
      let nameMatch = enrichedPOI.basePOI.name.lowercased() == waypoint.name.lowercased()
      let coordinateMatch = abs(enrichedPOI.basePOI.coordinate.latitude - waypoint.coordinate.latitude) < 0.001 &&
                            abs(enrichedPOI.basePOI.coordinate.longitude - waypoint.coordinate.longitude) < 0.001
      
      if nameMatch || coordinateMatch {
        return enrichedPOI
      }
    }
    
    return nil
  }
  
  // MARK: - Route Edit Methods
  
  /// Start editing a waypoint
  private func editWaypoint(at index: Int) {
    guard let route = routeService.generatedRoute,
          index >= 0 && index < route.waypoints.count else { return }
    
    let waypoint = route.waypoints[index]
    
    // Create editable spot with alternatives from current cache
    let alternatives = findAlternativePOIsWithHistory(for: waypoint, at: index, from: discoveredPOIs)
    
    editableSpot = EditableRouteSpot(
      originalWaypoint: waypoint,
      waypointIndex: index,
      alternativePOIs: alternatives,
      currentPOI: findCurrentPOI(for: waypoint),
      replacedPOIs: replacedPOIsHistory[index] ?? []
    )
    
    editingWaypointIndex = index
    showingEditView = true
  }
  
  /// Handle spot change from route edit
  private func handleSpotChange(_ newPOI: POI, _ newRoute: GeneratedRoute?) {
    // Immediately show global loading in parent to avoid flicker when returning from edit sheet
    routeService.isGenerating = true
    // Capture index before clearing state
    let capturedIndex: Int? = editableSpot?.waypointIndex

    // Track the replaced POI in history
    if let e = editableSpot {
      let waypointIndex = e.waypointIndex
      if let currentPOI = findCurrentPOI(for: e.originalWaypoint) {
        var history = replacedPOIsHistory[waypointIndex] ?? []
        if !history.contains(where: { $0.id == currentPOI.id }) {
          history.append(currentPOI)
          replacedPOIsHistory[waypointIndex] = history
        }
      }
    }

    // Close edit sheet immediately for responsive UX
    showingEditView = false
    self.editableSpot = nil
    self.editingWaypointIndex = nil

    Task {
      if let updatedRoute = newRoute {
        // We already have a recalculated route; apply it directly
        await MainActor.run {
          routeService.generatedRoute = updatedRoute
          routeService.isGenerating = false
        }
        await enrichRouteWithWikipedia(route: updatedRoute)
      } else if let index = capturedIndex, let route = routeService.generatedRoute {
        // Recalculate in background and show global loading in parent
        await generateUpdatedRoute(
          replacing: index,
          with: newPOI,
          in: route
        )
      }
    }
  }
  
  /// Handle edit cancellation
  private func handleEditCancel() {
    showingEditView = false
    editableSpot = nil
    editingWaypointIndex = nil
  }
  
  /// Find alternative POIs for a waypoint including replaced POIs from history
  private func findAlternativePOIsWithHistory(for waypoint: RoutePoint, at waypointIndex: Int, from cachedPOIs: [POI]) -> [POI] {
    // Get previously replaced POIs for this position
    let replacedPOIs = replacedPOIsHistory[waypointIndex] ?? []
    
    // Combine cached POIs with replaced POIs (excluding current route POIs)
    let allPossiblePOIs = cachedPOIs + replacedPOIs
    
    return allPossiblePOIs.filter { poi in
      // Only exclude POIs already in route - NO distance restriction
      return !isAlreadyInRoute(poi)
    }
    .sorted { poi1, poi2 in
      // Prioritize previously replaced POIs (show them first)
      let poi1WasReplaced = replacedPOIs.contains { $0.id == poi1.id }
      let poi2WasReplaced = replacedPOIs.contains { $0.id == poi2.id }
      
      if poi1WasReplaced && !poi2WasReplaced {
        return true
      } else if !poi1WasReplaced && poi2WasReplaced {
        return false
      }
      
      // Then sort by category match
      let categoryMatch1 = poi1.category == waypoint.category
      let categoryMatch2 = poi2.category == waypoint.category
      
      if categoryMatch1 && !categoryMatch2 {
        return true
      } else if !categoryMatch1 && categoryMatch2 {
        return false
      }
      
      // Finally sort by distance
      let distance1 = calculateDistance(from: poi1.coordinate, to: waypoint.coordinate)
      let distance2 = calculateDistance(from: poi2.coordinate, to: waypoint.coordinate)
      return distance1 < distance2
    }
    .prefix(30) // Increased limit for more alternatives
    .map { $0 }
  }
  
  /// Check if POI is already in the current route
  private func isAlreadyInRoute(_ poi: POI) -> Bool {
    guard let route = routeService.generatedRoute else { return false }
    
    return route.waypoints.contains { waypoint in
      poi.name.lowercased() == waypoint.name.lowercased() &&
      calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50 // 50m tolerance
    }
  }
  
  /// Find current POI for a waypoint (if it exists in cache)
  private func findCurrentPOI(for waypoint: RoutePoint) -> POI? {
    return discoveredPOIs.first { poi in
      poi.name.lowercased() == waypoint.name.lowercased() &&
      calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50
    }
  }
  
  /// Calculate distance between coordinates
  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  /// Generate updated route with new POI
  private func generateUpdatedRoute(
    replacing waypointIndex: Int,
    with newPOI: POI,
    in originalRoute: GeneratedRoute
  ) async {
    
    // Update UI to show loading
    await MainActor.run {
      routeService.isGenerating = true
      routeService.errorMessage = nil
    }
    
    do {
      // Update the route by replacing the waypoint
      var newWaypoints = originalRoute.waypoints
      let newWaypoint = RoutePoint(from: newPOI)
      newWaypoints[waypointIndex] = newWaypoint
      
      // Recalculate walking routes between waypoints
      let newRoutes = try await recalculateWalkingRoutes(for: newWaypoints)
      
      // Calculate new metrics (keep units consistent: seconds)
      let newTotalDistance = newRoutes.reduce(0) { $0 + $1.distance }
      let newTotalTravelTime: TimeInterval = newRoutes.reduce(0) { $0 + $1.expectedTravelTime }
      
      // Keep original visit time, update experience time
      let newTotalExperienceTime: TimeInterval = newTotalTravelTime + originalRoute.totalVisitTime
      
      let updatedRoute = GeneratedRoute(
        waypoints: newWaypoints,
        routes: newRoutes,
        totalDistance: newTotalDistance,
        totalTravelTime: newTotalTravelTime,
        totalVisitTime: originalRoute.totalVisitTime,
        totalExperienceTime: newTotalExperienceTime
      )
      
      await MainActor.run {
        routeService.generatedRoute = updatedRoute
        routeService.isGenerating = false
        
        // Re-enrich the updated route with Wikipedia data
        Task {
          await enrichRouteWithWikipedia(route: updatedRoute)
        }
      }
      
    } catch {
      await MainActor.run {
        routeService.isGenerating = false
        routeService.errorMessage = "Route-Update fehlgeschlagen: \(error.localizedDescription)"
      }
    }
  }
  
  /// Recalculate walking routes between waypoints
  private func recalculateWalkingRoutes(for waypoints: [RoutePoint]) async throws -> [MKRoute] {
    var routes: [MKRoute] = []
    
    for i in 0..<(waypoints.count - 1) {
      let startPoint = waypoints[i]
      let endPoint = waypoints[i + 1]
      
      let request = MKDirections.Request()
      request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint.coordinate))
      request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endPoint.coordinate))
      request.transportType = .walking
      
      let directions = MKDirections(request: request)
      
      do {
        let response = try await directions.calculate()
        if let route = response.routes.first {
          routes.append(route)
        } else {
          throw NSError(
            domain: "RouteUpdate",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Keine Route zwischen Wegpunkten gefunden"]
          )
        }
      } catch {
        throw NSError(
          domain: "RouteUpdate", 
          code: 500,
          userInfo: [NSLocalizedDescriptionKey: "Routenberechnung fehlgeschlagen: \(error.localizedDescription)"]
        )
      }
      
      // Rate limiting to be respectful to Apple's servers
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    return routes
  }
}