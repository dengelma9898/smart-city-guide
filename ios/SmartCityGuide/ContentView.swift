import SwiftUI
import MapKit

struct ContentView: View {
  // MARK: - Services
  @StateObject private var coordinator: BasicHomeCoordinator
  @StateObject private var mapService = ContentMapService()
  @StateObject private var quickRouteService = RouteService()
  @StateObject private var geoapifyService = GeoapifyAPIService.shared
  @StateObject private var locationService = LocationManagerService.shared
  
  // MARK: - State
  @State private var isQuickPlanning = false
  @State private var quickPlanningMessage = "Wir basteln deine Route!"
  @State private var showingQuickError = false
  @State private var quickErrorMessage = ""
  @State private var showingLocationPermissionAlert = false
  
  // MARK: - Initialization
  init() {
    // Simplified approach: Use a basic coordinator without complex DI for now
    _coordinator = StateObject(wrappedValue: BasicHomeCoordinator())
  }
  

  
  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        // Main map view
        ContentMapView(
          cameraPosition: $mapService.cameraPosition,
          locationService: locationService,
          activeRoute: coordinator.activeRoute
        )
        
        // Overlay layer
        overlayLayer
      }
    }
    // Phase 4: Coordinator-based Sheet Routing
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
          if FeatureFlags.enhancedActiveRouteSheetEnabled {
            EnhancedActiveRouteSheetView(
              route: route,
              onEnd: coordinator.endActiveRoute,
              onAddStop: {
                // Enhanced: will implement route modification
              },
              onModifyRoute: { modification in
                // TODO: Implement route modification handler
                print("🔄 Route modification requested: \(modification)")
              }
            )
            .presentationDetents([.height(100), .height(350), .fraction(0.8)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.enabled)
            .presentationContentInteraction(.scrolls)
          } else {
            ActiveRouteSheetView(
              route: route,
              onEnd: coordinator.endActiveRoute,
              onAddStop: {
                // Placeholder: will open manual add/edit in Phase 3
              }
            )
            .presentationDetents([.height(100), .height(350), .fraction(0.8)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.enabled)
            .presentationContentInteraction(.scrolls)
          }
        } else {
          EmptyView()
        }
      }
    }
    // Phase 2: Lifecycle & Alerts
    .onAppear {
      // Automatisch Location Permission anfordern bei erstem App-Start
      if locationService.authorizationStatus == .notDetermined {
        Task { @MainActor in
          await locationService.requestLocationPermission()
        }
      }
      // Location-Updates starten wenn bereits authorized
      if locationService.isLocationAuthorized {
        locationService.startLocationUpdates()
      }
    }
    .onChange(of: locationService.isLocationAuthorized) { _, isAuthorized in
      if isAuthorized {
        locationService.startLocationUpdates()
        // Kamera zur User-Location bewegen bei erster Autorisierung
        if let location = locationService.currentLocation {
          mapService.centerOnUserLocation(location)
        }
      } else {
        locationService.stopLocationUpdates()
      }
    }
    .alert("Location-Zugriff erforderlich", isPresented: $showingLocationPermissionAlert) {
      Button("Einstellungen öffnen") {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
      }
      Button("Abbrechen", role: .cancel) { }
    } message: {
      Text("Um deine Position auf der Karte zu sehen, aktiviere bitte Location-Services in den Einstellungen.")
    }
    .alert("Ups, da lief was schief!", isPresented: $showingQuickError) {
      Button("Okay", role: .cancel) { }
    } message: {
      Text(quickErrorMessage)
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
  }
}

#Preview {
  ContentView()
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
    .overlay(
      ContentQuickPlanningOverlay(
        message: quickPlanningMessage,
        isVisible: isQuickPlanning
      )
    )
  }

  private func locationButtonTapped() {
    if !locationService.isLocationAuthorized {
      if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
        showingLocationPermissionAlert = true
      } else {
        Task { @MainActor in
          await locationService.requestLocationPermission()
        }
      }
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
            SecureLogger.shared.logInfo("⚡️ Quick‑Plan: Trigger gedrückt", category: .ui)
            Task { await startQuickPlanning() }
          },
          onFullPlan: {
            SecureLogger.shared.logUserAction("Tap plan automatic")
            coordinator.presentSheet(.planning(mode: .automatic))
          }
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

  
  /// Phase 4: Start the Quick‑Planning flow
  fileprivate func startQuickPlanning() async {
    let overallStart = Date()
    // Ensure permission
    if !locationService.isLocationAuthorized {
      await MainActor.run { quickPlanningMessage = "Brauch kurz dein OK für den Standort…"; isQuickPlanning = true }
      await locationService.requestLocationPermission()
      if !locationService.isLocationAuthorized {
        await MainActor.run {
          isQuickPlanning = false
          showingQuickError = true
          quickErrorMessage = "Ohne Standortfreigabe kann ich die Schnell‑Route nicht starten."
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
        showingQuickError = true
        quickErrorMessage = "Konnte deinen Standort gerade nicht bestimmen. Versuch es gleich nochmal."
      }
      return
    }
    await MainActor.run { quickPlanningMessage = "Entdecke coole Orte…"; isQuickPlanning = true }
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
      await MainActor.run { quickPlanningMessage = "Optimiere deine Route…" }
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
          isQuickPlanning = false
        }
        Task { await ProximityService.shared.startProximityMonitoring(for: route) }
      } else {
        await MainActor.run {
          isQuickPlanning = false
          showingQuickError = true
          quickErrorMessage = quickRouteService.errorMessage ?? "Leider keine Route gefunden."
        }
      }
    } catch {
      await MainActor.run {
        isQuickPlanning = false
        showingQuickError = true
        quickErrorMessage = "Konnte keine Orte in deiner Nähe laden: \(error.localizedDescription)"
      }
    }
  }
}