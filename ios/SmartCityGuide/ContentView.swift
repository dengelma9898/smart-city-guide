import SwiftUI
import MapKit

struct ContentView: View {
   // MARK: - Coordinator (Centralized State)
   @EnvironmentObject private var coordinator: BasicHomeCoordinator
   
   // MARK: - Services
   private var quickRouteService: RouteService { coordinator.getRouteService() }
   private var geoapifyService: GeoapifyAPIService { coordinator.getGeoapifyService() }
   @ObservedObject private var locationService = LocationManagerService.shared
   
     // MARK: - UI-Specific Services (Keep local)
  @StateObject private var mapService = ContentMapService()
  @State private var errorHandler: UnifiedErrorHandler?
  @State private var didAutoCenterOnFirstFix = false
  // Add-POI Flow State
  @State private var showingAddPOISheet = false
  @StateObject private var addPOISelection = ManualPOISelection()
 
 // MARK: - Local State (UI-specific only)
  

  
     var body: some View {
     NavigationStack(path: $coordinator.navigationPath) {
      ZStack(alignment: .bottom) {
        // Main map view
        ContentMapView(
          cameraPosition: $mapService.cameraPosition,
          locationService: locationService,
          activeRoute: coordinator.activeRoute
        )
        
        // Overlay layer
        overlayLayer
        
        // Quick Planning Loading Overlay (connected to coordinator)
        ContentQuickPlanningOverlay(
          message: coordinator.quickPlanningMessage,
          isVisible: coordinator.isGeneratingRoute
        )
      }
    }
    // Add-POI Flow Sheet using UnifiedSwipeView
    .sheet(isPresented: $showingAddPOISheet, onDismiss: { addPOISelection.reset() }) {
      NavigationView {
        Group {
          if let route = coordinator.activeRoute {
            let filteredPOIs: [POI] = coordinator.cachedPOIsForAlternatives.filter { poi in
              !route.waypoints.contains { wp in
                poi.name.lowercased() == wp.name.lowercased() &&
                CLLocation(latitude: poi.latitude, longitude: poi.longitude)
                  .distance(from: CLLocation(latitude: wp.coordinate.latitude, longitude: wp.coordinate.longitude)) < 50
              }
            }
            UnifiedSwipeView(
              configuration: .addPOI,
              availablePOIs: filteredPOIs,
              enrichedPOIs: coordinator.enrichedPOIs,
              selection: addPOISelection,
              referenceCoordinate: coordinator.currentLocation?.coordinate,
              onDismiss: { showingAddPOISheet = false }
            )
            .navigationTitle("POIs hinzufügen")
          } else {
            Text("Keine aktive Route")
              .navigationTitle("POIs hinzufügen")
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Abbrechen") { showingAddPOISheet = false }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Übernehmen") {
              let count = addPOISelection.selectedPOIs.count
              SecureLogger.shared.logInfo("✅ Add-POI: Übernehmen gedrückt (\(count) POIs)", category: .ui)
              Task { await applyAddedPOIs() }
            }
            .disabled(addPOISelection.selectedPOIs.isEmpty)
          }
        }
        .tint(.blue)
      }
    }
         // Enhanced: Navigation Destinations
     .navigationDestination(for: String.self) { destination in
       navigationDestination(for: destination)
     }
     // Enhanced: Coordinator-based Sheet Routing
    .sheet(item: $coordinator.presentedSheet) { sheet in
      switch sheet {
      case .planning(let mode):
        RoutePlanningView(
          presetMode: mode,
          onRouteGenerated: coordinator.handleRouteGenerated,
          onDismiss: coordinator.dismissSheet
        )
      case .activeRoute:
        if FeatureFlags.activeRouteBottomSheetEnabled, let route = coordinator.activeRoute {
          ActiveRouteSheetView(
            route: route,
            onEnd: coordinator.endActiveRoute,
            onAddStop: {
              SecureLogger.shared.logInfo("➕ ContentView: onAddStop tapped (ActiveRouteSheet)", category: .ui)
              showingAddPOISheet = true
            },
            enrichedPOIs: coordinator.enrichedPOIs
          )
          .presentationDetents([.height(100), .height(350), .fraction(0.8)])
          .presentationDragIndicator(.visible)
          .interactiveDismissDisabled(true)
          .presentationBackgroundInteraction(.enabled)
          .presentationContentInteraction(.scrolls)
        } else {
          EmptyView()
        }
      }
    }
    // Phase 2: Lifecycle & Alerts
         .onAppear {
       // Initialize error handler on main actor
       Task { @MainActor in
         errorHandler = UnifiedErrorHandler.shared
       }
       
       // Location initialization is now handled by the coordinator
       // Just start updates if already authorized
       if locationService.isLocationAuthorized {
         locationService.startLocationUpdates()
         // Auto-center if we already have a fix and no active route
         if coordinator.activeRoute == nil, let loc = locationService.currentLocation, !didAutoCenterOnFirstFix {
           mapService.centerOnUserLocation(loc)
           didAutoCenterOnFirstFix = true
         }
       }
     }
         .onChange(of: locationService.isLocationAuthorized) { _, isAuthorized in
       if isAuthorized {
         locationService.startLocationUpdates()
         // Kamera zur User-Location bewegen bei erster Autorisierung
         if let location = locationService.currentLocation {
           mapService.centerOnUserLocation(location)
           didAutoCenterOnFirstFix = true
         }
       } else {
         locationService.stopLocationUpdates()
       }
    }
        // Auto-center when first location fix arrives (no active route)
        .onChange(of: locationService.currentLocation) { _, newLocation in
          if coordinator.activeRoute == nil, let loc = newLocation, !didAutoCenterOnFirstFix {
            mapService.centerOnUserLocation(loc)
            didAutoCenterOnFirstFix = true
          }
        }
        .overlay {
          if let errorHandler = errorHandler, errorHandler.isShowingError, let error = errorHandler.currentError {
            UnifiedErrorView(
              error: error,
              onRetry: { handleErrorRetry() },
              onDismiss: { errorHandler.dismissError() }
            )
            .transition(.opacity.combined(with: .scale))
          }
        }
    // NavigationBar auf der Root-Map verstecken, damit keine graue/Material-Fläche oben sichtbar ist
    .toolbar(.hidden, for: .navigationBar)
    // Statusbar/Top bar: keep map truly fullscreen
    .statusBarHidden(true)
         .onChange(of: coordinator.activeRoute != nil) { _, isActive in
       // Automatically show active route sheet when route becomes active
       if FeatureFlags.activeRouteBottomSheetEnabled, isActive, coordinator.presentedSheet == nil {
         coordinator.presentSheet(.activeRoute)
       }
     }
         .onChange(of: coordinator.activeRoute?.waypoints.count) { _, waypointCount in
      // Adjust map camera when route is generated or cleared
      if let activeRoute = coordinator.activeRoute, waypointCount != nil {
        SecureLogger.shared.logInfo("📍 ContentView: New route detected, adjusting map camera", category: .ui)
        mapService.adjustCamera(to: activeRoute)
      } else if waypointCount == nil {
        SecureLogger.shared.logInfo("📍 ContentView: Route cleared, resetting map state", category: .ui)
        mapService.clearRouteState()
      }
    }
    // MARK: - Route Success Sheet
    .sheet(isPresented: $coordinator.showRouteSuccessView) {
      if let stats = coordinator.routeSuccessStats,
         let route = coordinator.activeRoute {
        RouteSuccessView(
          completedRoute: route,
          routeStats: stats,
          onClose: {
            coordinator.dismissRouteSuccessView()
          }
        )
      }
    }
  }
}

#Preview {
  ContentView()
}

 // MARK: - Navigation Destinations
 extension ContentView {
   
   @ViewBuilder
   private func navigationDestination(for destination: String) -> some View {
     switch destination {
     case "profile":
       ProfileView()
     case "routeHistory":
       RouteHistoryView()
     case "settings":
       ProfileSettingsView()
     case "help":
       HelpSupportView()
     default:
       Text("Unknown destination: \(destination)")
         .navigationTitle("Error")
     }
   }
 }
 
 // MARK: - Private helpers
 extension ContentView {
   // Extracted overlay (top controls + bottom actions + loader) to reduce body complexity
  @ViewBuilder
  fileprivate var overlayLayer: some View {
    VStack {
      // Top overlay with profile and location buttons
               ContentTopOverlay(
           locationService: locationService,
           onLocationTap: locationButtonTapped
         )

      Spacer()

      // Bottom overlay – legacy or primary actions
      bottomOverlay
    }
  }

     private func locationButtonTapped() {
     if !locationService.isLocationAuthorized {
       // Permission requests now handled in intro flow
       // Show settings alert for denied permissions or profile hint for not determined
       coordinator.showingLocationPermissionAlert = true
     } else if let userLocation = locationService.currentLocation {
       mapService.centerOnUserLocation(userLocation)
     }
   }


  // Extracted bottom overlay to reduce body complexity
  @ViewBuilder
  fileprivate var bottomOverlay: some View {
    // 1) Legacy banner only when route active AND sheet feature disabled
    if let route = coordinator.activeRoute, !FeatureFlags.activeRouteBottomSheetEnabled {
      ContentActiveRouteBanner(
        route: route,
        onEndRoute: coordinator.endActiveRoute
      )
    } else if coordinator.activeRoute == nil {
      if FeatureFlags.quickRoutePlanningEnabled {
                   ContentBottomActionBar(
             onQuickPlan: {
               SecureLogger.shared.logInfo("⚡️ Quick‑Plan: Trigger gedrückt (via Coordinator)", category: .ui)
               Task { await startEnhancedQuickPlanning() }
             },
          onFullPlan: {
            SecureLogger.shared.logUserAction("Tap plan automatic")
            coordinator.presentSheet(.planning(mode: .automatic))
          },
          isQuickPlanEnabled: (coordinator.currentLocation ?? locationService.currentLocation) != nil
        )
      } else {
        // Legacy buttons when quick planning disabled
        VStack(spacing: 12) {
          Button(action: {
            SecureLogger.shared.logUserAction("Tap plan automatic")
            coordinator.presentSheet(.planning(mode: .automatic))
          }) {
            Text("Route planen")
              .font(.headline)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 14)
                  .fill(.blue)
                  .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
              )
          }
          .accessibilityIdentifier("home.plan.automatic")
          .accessibilityLabel("Route planen")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
      }
    } else {
      // 2) Route active AND sheet feature enabled → hide bottom actions entirely
      EmptyView()
    }
  }

  
     /// Enhanced: Start Quick‑Planning with Coordinator features
   fileprivate func startEnhancedQuickPlanning() async {
     SecureLogger.shared.logInfo("🚀 Enhanced Quick Planning Started!", category: .ui)
     
     // Use coordinator's location and error management
     guard let location = coordinator.currentLocation ?? locationService.currentLocation else {
       SecureLogger.shared.logWarning("⚠️ Enhanced Quick Planning: No location available", category: .ui)
       await MainActor.run {
         coordinator.showingLocationPermissionAlert = true
       }
       return
     }
     
     SecureLogger.shared.logInfo("✅ Enhanced Quick Planning: Using location \(location)", category: .ui)
     await coordinator.startQuickPlanningAt(location: location)
   }
   
   /// Legacy: Start the Quick‑Planning flow (keep for backward compatibility)
   fileprivate func startQuickPlanning() async {
    let overallStart = Date()
    // Ensure permission
         if !locationService.isLocationAuthorized {
       // Legacy method - message handled by coordinator now
       await locationService.requestLocationPermission()
       if !locationService.isLocationAuthorized {
        await MainActor.run {
          errorHandler?.presentLocationError(message: "Ohne Standortfreigabe kann ich die Schnell‑Route nicht starten.")
        }
        return
      }
    }
    // Get coordinate (retry once if nil)
         var current = locationService.currentLocation
     if current == nil {
       locationService.startLocationUpdates()
       try? await Task.sleep(nanoseconds: 800_000_000)
       current = locationService.currentLocation
     }
    guard let loc = current else {
      await MainActor.run {
        errorHandler?.presentLocationError(message: "Konnte deinen Standort gerade nicht bestimmen. Versuch es gleich nochmal.")
      }
      return
    }
    // Legacy method - message handled by coordinator now
    do {
      // Fetch POIs around current coordinate
      let fetchStart = Date()
             let pois = try await geoapifyService.fetchPOIs(
        at: loc.coordinate,
        cityName: "Mein Standort",
        categories: PlaceCategory.geoapifyEssentialCategories,
        radiusMeters: 2000
      )
      let fetchDuration = Date().timeIntervalSince(fetchStart)
      SecureLogger.shared.logInfo("Quick POI fetch: \(pois.count) results in \(String(format: "%.2f", fetchDuration))s", category: .performance)
      
      // Debug POI details
      if pois.isEmpty {
        SecureLogger.shared.logWarning("⚠️ Quick Planning: No POIs found at \(loc.coordinate)", category: .ui)
      } else {
        SecureLogger.shared.logInfo("✅ Quick Planning: Found \(pois.count) POIs: \(pois.prefix(3).map { $0.name })", category: .ui)
      }
      
      // Legacy method - message handled by coordinator now
      // Generate route with fixed parameters
      let routeStart = Date()
             await quickRouteService.generateRoute(
        fromCurrentLocation: loc,
        maximumStops: .eight,
        endpointOption: .roundtrip,
        customEndpoint: "",
        maximumWalkingTime: .openEnd,
        minimumPOIDistance: .noMinimum,
        availablePOIs: pois
      )
      let routeDuration = Date().timeIntervalSince(routeStart)
             if let route = quickRouteService.generatedRoute {
        let totalDuration = Date().timeIntervalSince(overallStart)
        SecureLogger.shared.logRouteCalculation(waypoints: route.waypoints.count, duration: routeDuration)
        SecureLogger.shared.logInfo("Quick planning total: \(String(format: "%.2f", totalDuration))s", category: .performance)
        await MainActor.run {
          coordinator.handleRouteGenerated(route)
        }
        Task { await ProximityService.shared.startProximityMonitoring(for: route) }
      } else {
        await MainActor.run {
          errorHandler?.presentRouteGenerationError(
            message: quickRouteService.errorMessage ?? "Für deine aktuelle Position konnten keine interessanten Orte gefunden werden."
          )
        }
      }
    } catch {
      await MainActor.run {
        errorHandler?.presentError(error, context: "quick planning location")
      }
    }
  }
  
  // MARK: - Error Handling
  
  private func handleErrorRetry() {
    // Handle retry based on current error context
    if let currentError = errorHandler?.currentError {
      switch currentError.category {
      case .routeGeneration:
        // Retry route generation with current settings
        if locationService.currentLocation != nil {
          Task {
            await startQuickPlanning()
          }
        }
      case .locationAccess:
        // Open settings for location access
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
      case .networkConnectivity:
        // Retry the last failed operation
        if locationService.currentLocation != nil {
          Task {
            await startQuickPlanning()
          }
        }
      default:
        // General retry - attempt to refresh current state
        coordinator.clearError()
      }
    }
  }

  /// Apply selected POIs from add flow into the active route and re-optimize
  fileprivate func applyAddedPOIs() async {
    guard let route = coordinator.activeRoute else {
      SecureLogger.shared.logWarning("⚠️ Add-POI: No active route to apply to", category: .ui)
      await MainActor.run { showingAddPOISheet = false }
      return
    }
    let pois = addPOISelection.selectedPOIs
    if pois.isEmpty {
      await MainActor.run { showingAddPOISheet = false }
      return
    }

    // Merge new POIs with existing waypoints
    var newWaypoints = route.waypoints
    for poi in pois {
      newWaypoints.insert(RoutePoint(from: poi), at: max(1, newWaypoints.count - 1))
    }

    SecureLogger.shared.logInfo("🔄 Add-POI: Re-optimizing route with +\(pois.count) POIs", category: .ui)

    // Re-generate optimized route via coordinator utilities
    do {
      let routeGenerationService = RouteGenerationService()
      let tsp = RouteTSPService()
      let optimized = tsp.optimizeWaypointOrder(newWaypoints)
      let originalEndpointOption = coordinator.activeRoute?.endpointOption ?? .roundtrip
      let updated = try await routeGenerationService.generateCompleteRoute(from: optimized, endpointOption: originalEndpointOption)
      await MainActor.run {
        coordinator.handleRouteGenerated(updated)
        addPOISelection.reset()
        showingAddPOISheet = false
      }
    } catch {
      SecureLogger.shared.logError("❌ Add-POI: Failed to re-optimize route: \(error.localizedDescription)", category: .ui)
      await MainActor.run {
        addPOISelection.reset()
        showingAddPOISheet = false
      }
    }
  }
}