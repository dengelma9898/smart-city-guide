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
  
  // MARK: - Generated Route List View
  @ViewBuilder
  private func generatedRouteListView(_ route: GeneratedRoute) -> some View {
    RouteListView(
      route: route,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      enrichedPOIs: wikipediaService.enrichedPOIs,
      isEnrichingAllPOIs: wikipediaService.isEnrichingAllPOIs,
      enrichmentProgress: wikipediaService.enrichmentProgress,
      onRouteStart: {
        onRouteGenerated(route)
        Task { await ProximityService.shared.startProximityMonitoring(for: route) }
        dismiss()
      },
      onWaypointEdit: editWaypoint,
      onWaypointDelete: deletePOI,
      onWikipediaImageTap: { imageURL, title, wikipediaURL in
        // Prepare state for full-screen image modal
        fullScreenImageURL = imageURL
        fullScreenImageTitle = title
        fullScreenWikipediaURL = wikipediaURL
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
          showFullScreenImage = true
        }
      }
    )
  }



  // MARK: - Full-Screen Image Modal
  @ViewBuilder
  private var zoomOverlay: some View {
    if showFullScreenImage {
      FullScreenImageView(
        imageURL: fullScreenImageURL,
        title: fullScreenImageTitle,
        wikipediaURL: fullScreenWikipediaURL,
        imageZoomNamespace: imageZoomNamespace,
        onDismiss: {
          withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showFullScreenImage = false
          }
        }
      )
    }
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
  
  // MARK: - Coordinator (Centralized Services)
  @EnvironmentObject private var coordinator: BasicHomeCoordinator
  
  // MARK: - Services (Via Coordinator)
  private var routeService: RouteService { coordinator.getRouteService() }
  private var geoapifyService: GeoapifyAPIService { coordinator.getGeoapifyService() }
  
  // MARK: - Specialized Services (Keep Local)
  @StateObject private var historyManager = RouteHistoryManager()
  @StateObject private var wikipediaService = RouteWikipediaService()
  @State private var editService: RouteBuilderEditService?
  
  @State private var discoveredPOIs: [POI] = []
  @State private var isLoadingPOIs = false
  
  // Full-Screen Image Modal States
  @State private var showFullScreenImage = false
  @State private var fullScreenImageURL: String = ""
  @State private var fullScreenImageTitle: String = ""
  @State private var fullScreenWikipediaURL: String = ""
  @Namespace private var imageZoomNamespace

  
  // Route Edit States
  @State private var showingEditView = false // deprecated by sheet(item:), kept for safety
  @State private var editingWaypointIndex: Int?
  @State private var editableSpot: EditableRouteSpot?
  
  // Phase 2 (Vorbereitung): Add-POI Sheet-State (wird später genutzt)
  @State private var showingAddPOISheet = false
  @State private var addFlowTopCard: SwipeCard?
  @State private var addFlowSelectedPOIs: [POI] = []
  
  // MARK: - Computed Properties
  
  private var loadingStateText: String {
    if isLoadingPOIs {
      return "Entdecke coole Orte..."
    } else if routeService.isGenerating {
      return "Optimiere deine Route..."
    } else if wikipediaService.isEnrichingRoutePOIs {
      return "Lade Wikipedia-Infos..."
    } else {
      return "Bereite vor..."
    }
  }
  
  var body: some View {
    NavigationView {
      Group {
        if (routeSource.isManual && routeService.generatedRoute == nil) || isLoadingPOIs || routeService.isGenerating || wikipediaService.isEnrichingRoutePOIs {
          // Loading/Generating State
          RouteLoadingStateView(
            loadingStateText: loadingStateText,
            maximumStops: maximumStops,
            startingCity: startingCity
          )
        } else if let route = routeService.generatedRoute {
          // Generated Route - List with swipe actions
          generatedRouteListView(route)
        } else if let error = routeService.errorMessage {
          // Error State
          RouteErrorStateView(
            errorMessage: error,
            onRetry: {
              Task { await generateOptimalRoute() }
            }
          )
        }
      }
      .accessibilityIdentifier("route.builder.screen")
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: 12) {
            if routeService.generatedRoute != nil {
              Button {
                showingAddPOISheet = true
              } label: {
                Image(systemName: "plus")
              }
              .accessibilityIdentifier("route.add-poi.button")
            }
            Button("Fertig") { dismiss() }
          }
        }
      }
    }
    .onAppear {
      routeService.setHistoryManager(historyManager)
      
      // Initialize edit service with dependencies
      if editService == nil {
        editService = RouteBuilderEditService(routeService: routeService, wikipediaService: wikipediaService)
      }
      
      // Manual source: seed the route and POIs so we show preview immediately
      if case .manual = routeSource {
        SecureLogger.shared.logDebug("🟦 RouteBuilderView.onAppear: routeSource=manual, seeding data…", category: .ui)
        if let r = manualInitialRoute {
          routeService.generatedRoute = r
          SecureLogger.shared.logDebug("🟩 RouteBuilderView: seeded generatedRoute with \(r.waypoints.count) waypoints", category: .ui)
        } else {
          SecureLogger.shared.logWarning("🟥 RouteBuilderView: manualInitialRoute is nil", category: .ui)
        }
        if let pois = initialDiscoveredPOIs {
          discoveredPOIs = pois
          SecureLogger.shared.logDebug("🟩 RouteBuilderView: seeded discoveredPOIs = \(pois.count)", category: .ui)
        } else {
          discoveredPOIs = []
          SecureLogger.shared.logWarning("🟥 RouteBuilderView: initialDiscoveredPOIs is nil, using []", category: .ui)
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
    .overlay(zoomOverlay)
    .sheet(item: $editableSpot) { item in
      RouteEditView(
        originalRoute: routeService.generatedRoute!,
        editableSpot: item,
        cityName: startingCity,
        allDiscoveredPOIs: discoveredPOIs,
        onSpotChanged: handleSpotChange,
        onCancel: handleEditCancel
      )
    }
    .sheet(isPresented: $showingAddPOISheet, onDismiss: {
      addFlowSelectedPOIs.removeAll()
      addFlowTopCard = nil
    }) {
      if let route = routeService.generatedRoute {
        AddPOISheetView(
          route: route,
          discoveredPOIs: discoveredPOIs,
          enrichedPOIs: wikipediaService.enrichedPOIs,
          startingCity: startingCity,
          startingCoordinates: startingCoordinates,
          selectedPOIs: $addFlowSelectedPOIs,
          topCard: $addFlowTopCard,
          isAlreadyInRoute: { poi in
            guard let route = routeService.generatedRoute else { return false }
            return route.waypoints.contains { waypoint in
              poi.name.lowercased() == waypoint.name.lowercased() &&
              calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50
            }
          },
          onOptimize: {
            await reoptimizeRouteWithAddedPOIs()
          },
          onDismiss: {
            showingAddPOISheet = false
          }
        )
      }
    }
  }

  // MARK: - Navigation Title
  private var navigationTitle: String {
    if routeService.generatedRoute != nil {
      return "Deine Tour im Detail"
    }
    return routeSource.isManual ? "Deine manuelle Route!" : "Deine Tour entsteht!"
  }
  
  // MARK: - POI Loading and Route Generation
  
  private func loadPOIsAndGenerateRoute() async {
    do {
      // Step 1: Load POIs from Geoapify API
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
        await wikipediaService.enrichRoute(generatedRoute, from: discoveredPOIs, startingCity: startingCity)
      }
      
    } catch {
      isLoadingPOIs = false
                // Error will be displayed via errorMessage
      routeService.errorMessage = "Konnte keine coolen Orte finden: \(error.localizedDescription)"
    }
  }
  

  
  
  // MARK: - Route Edit Methods
  
  /// Start editing a waypoint
  private func editWaypoint(at index: Int) {
    guard let editService = editService else { return }
    
    editableSpot = editService.createEditableSpot(for: index, discoveredPOIs: discoveredPOIs)
    editingWaypointIndex = index
    // Present via sheet(item:)
  }
  
  /// Handle spot change from route edit
  private func handleSpotChange(_ newPOI: POI, _ newRoute: GeneratedRoute?) {
    guard let editService = editService else { return }
    
    Task {
      if let updatedRoute = newRoute {
        // We already have a recalculated route; apply it directly
        await MainActor.run {
          routeService.generatedRoute = updatedRoute
          routeService.isGenerating = false
        }
        await wikipediaService.enrichRoute(updatedRoute, from: discoveredPOIs, startingCity: startingCity)
      } else {
        _ = await editService.handleSpotChange(
          newPOI,
          editableSpot: editableSpot,
          discoveredPOIs: discoveredPOIs,
          startingCity: startingCity,
          onDismiss: {
            showingEditView = false
            self.editableSpot = nil
            self.editingWaypointIndex = nil
          }
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
  

  


  

  
  /// Löscht einen Zwischenstopp aus der aktuellen Route
  /// - Parameter index: Index des zu löschenden Wegpunkts (nur Zwischenstopps erlaubt)
  private func deletePOI(at index: Int) async {
    guard let editService = editService else { return }
    
    _ = await editService.deletePOI(
      at: index,
      discoveredPOIs: discoveredPOIs,
      startingCity: startingCity,
      onDismiss: { dismiss() }
    )
  }
  


  // MARK: - Helper Methods
  
  /// Calculate distance between coordinates
  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  // MARK: - Full Re-Optimization after Add Flow
  
  private func reoptimizeRouteWithAddedPOIs() async {
    guard let editService = editService else { return }
    
    let success = await editService.reoptimizeRouteWithAddedPOIs(
      selectedPOIs: addFlowSelectedPOIs,
      startingCoordinates: startingCoordinates,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      customEndpointCoordinates: customEndpointCoordinates,
      discoveredPOIs: discoveredPOIs,
      startingCity: startingCity
    )
    
    if success {
      await MainActor.run {
        showingAddPOISheet = false
        addFlowSelectedPOIs.removeAll()
      }
    }
  }
}
