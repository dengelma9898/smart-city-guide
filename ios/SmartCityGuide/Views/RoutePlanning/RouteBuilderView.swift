import SwiftUI
import MapKit

// MARK: - Route Builder View (Next Step)
struct RouteBuilderView: View {
  @Environment(\.dismiss) private var dismiss
  let startingCity: String
  let startingCoordinates: CLLocationCoordinate2D?
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
    maximumStops: MaximumStops,
    endpointOption: EndpointOption,
    customEndpoint: String,
    customEndpointCoordinates: CLLocationCoordinate2D?,
    maximumWalkingTime: MaximumWalkingTime,
    minimumPOIDistance: MinimumPOIDistance,
    onRouteGenerated: @escaping (GeneratedRoute) -> Void
  ) {
    self.startingCity = startingCity
    self.startingCoordinates = startingCoordinates
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
    self.startingCity = startingCity
    self.startingCoordinates = startingCoordinates
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
      // Use new enhanced route generation
      await routeService.generateRoute(
        startingCity: startingCity,
        maximumStops: maximumStops,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        maximumWalkingTime: maximumWalkingTime,
        minimumPOIDistance: minimumPOIDistance,
        availablePOIs: discoveredPOIs
      )
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
          if isLoadingPOIs || routeService.isGenerating || isEnrichingRoutePOIs {
            // Header - only show during generation
            VStack(spacing: 12) {
              Text("Wir basteln deine Route!")
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("Suchen die coolsten \(numberOfPlaces) Stopps in \(startingCity) für dich!")
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
                          Text(waypoint.name)
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
      .navigationTitle("Deine Tour entsteht!")
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
    }
    .task {
      await loadPOIsAndGenerateRoute()
    }
    .fullScreenCover(isPresented: $showFullScreenImage) {
      FullScreenImageView(
        imageURL: fullScreenImageURL,
        title: fullScreenImageTitle,
        wikipediaURL: fullScreenWikipediaURL.isEmpty ? nil : fullScreenWikipediaURL,
        isPresented: $showFullScreenImage
      )
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
    
    do {
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
      
    } catch {
      await MainActor.run {
        isEnrichingAllPOIs = false
      }
      print("📚 [Phase 2] Background enrichment failed: \(error.localizedDescription)")
    }
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
}