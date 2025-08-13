import SwiftUI
import MapKit

struct ContentView: View {
  @State private var cameraPosition = MapCameraPosition.region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Berlin default
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
  )
  @State private var showingProfile = false
  @State private var showingRoutePlanning = false
  @State private var activeRoute: GeneratedRoute?
  // Phase 2: Vorbereitung für Modus-Vorselektion (Phase 3 nutzt dies)
  @State private var desiredPlanningMode: RoutePlanningMode? = nil
  // Phase 4: Quick‑Planning Flow
  @StateObject private var quickRouteService = RouteService()
  @StateObject private var geoapifyService = GeoapifyAPIService.shared
  @State private var isQuickPlanning = false
  @State private var quickPlanningMessage = "Wir basteln deine Route!"
  @State private var showingQuickError = false
  @State private var quickErrorMessage = ""
  
  // Phase 2: Location Features
  @StateObject private var locationService = LocationManagerService.shared
  @State private var showingLocationPermissionAlert = false
  
  // Computed properties for Location Button
  private var locationButtonIcon: String {
    if !locationService.isLocationAuthorized {
      return locationService.authorizationStatus == .denied ? "location.slash" : "location"
    } else {
      return "location.fill"
    }
  }
  
  private var locationButtonColor: Color {
    if !locationService.isLocationAuthorized {
      return locationService.authorizationStatus == .denied ? .red : .orange
    } else {
      return .blue
    }
  }
  
  var body: some View {
    ZStack {
      // Fullscreen Map
      Map(position: $cameraPosition) {
        // Phase 2: User Location (Blue Dot)
        if locationService.currentLocation != nil {
          UserAnnotation()
        }
        
        // Display route if active
        if let route = activeRoute {
          // Route polylines
          ForEach(Array(route.routes.enumerated()), id: \.offset) { index, mkRoute in
            MapPolyline(mkRoute)
              .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
          
          // Waypoint markers
          ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
            Marker(
              waypoint.name,
              coordinate: waypoint.coordinate
            )
            .tint(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
          }
        }
      }
      .mapControls {
        MapCompass()
        MapScaleView()
      }
      .mapStyle(.standard)
      .ignoresSafeArea()
      
      // Overlay following iOS design patterns
      VStack {
        // Top overlay - Profile button (top-left like Apple Maps)
        HStack {
          // Profile Button
            Button(action: {
            showingProfile = true
          }) {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 20))
              .foregroundColor(.blue)
              .frame(width: 40, height: 40)
              .background(
                Circle()
                  .fill(.regularMaterial)
                  .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
              )
          }
          .accessibilityIdentifier("home.profile.button")
          .accessibilityLabel("Profil öffnen")
          
          Spacer()
          
          // Phase 2: Location Button - Always visible, smart behavior
          Button(action: {
            if !locationService.isLocationAuthorized {
              // Not authorized - request permission or show settings
              if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                showingLocationPermissionAlert = true
              } else {
                Task { @MainActor in
                  await locationService.requestLocationPermission()
                }
              }
            } else {
              // Authorized - center on user location
              if let userLocation = locationService.currentLocation {
                withAnimation(.easeInOut(duration: 0.8)) {
                  cameraPosition = MapCameraPosition.region(
                    MKCoordinateRegion(
                      center: userLocation.coordinate,
                      span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                  )
                }
              }
            }
          }) {
            Image(systemName: locationButtonIcon)
              .font(.system(size: 18))
              .foregroundColor(locationButtonColor)
              .frame(width: 40, height: 40)
              .background(
                Circle()
                  .fill(.regularMaterial)
                  .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
              )
          }
          .accessibilityIdentifier("home.location.button")
          .accessibilityLabel("Mein Standort")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        
        Spacer()
        
        // Bottom overlay - Different based on route state
        if let route = activeRoute {
          // Route is active - Show route controls
          VStack(spacing: 16) {
            // Route info card
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Deine Tour läuft!")
                  .font(.caption)
                  .foregroundColor(.secondary)
                
                Text("\(Int(route.totalDistance / 1000)) km • \(formatExperienceTime(route.totalExperienceTime))")
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
              
              Spacer()
              
              Text("\(route.numberOfStops) coole Stopps")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Route action buttons
            HStack(spacing: 12) {
              // Stop Route Button
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  activeRoute = nil
                }
              }) {
                HStack(spacing: 6) {
                  Image(systemName: "stop.fill")
                    .font(.system(size: 16, weight: .medium))
                  Text("Tour beenden")
                    .font(.body)
                    .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(.red)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
              }
              
              // Modify Route Button
              Button(action: {
                showingRoutePlanning = true
              }) {
                HStack(spacing: 6) {
                  Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                  Text("Anpassen")
                    .font(.body)
                    .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
              }
              .accessibilityIdentifier("route.edit.button")
            }
          }
          .padding(.bottom, 50)
          
        } else {
          // No active route – drei Primäraktionen im Thumb‑Bereich
          VStack(spacing: 12) {
            // Automatisch planen
            Button(action: {
              desiredPlanningMode = .automatic
              SecureLogger.shared.logUserAction("Tap plan automatic")
              showingRoutePlanning = true
            }) {
              HStack(spacing: 10) {
                Image(systemName: "sparkles")
                  .font(.system(size: 16, weight: .medium))
                Text("Automatisch planen")
                  .font(.headline)
                  .fontWeight(.medium)
              }
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
            .accessibilityLabel("Automatisch planen")
            // Legacy Identifier für bestehende UI-Tests (Kompatibilität)
            .accessibilityIdentifier("Los, planen wir!")

            // Manuell auswählen
            Button(action: {
              desiredPlanningMode = .manual
              SecureLogger.shared.logUserAction("Tap plan manual")
              showingRoutePlanning = true
            }) {
              HStack(spacing: 10) {
                Image(systemName: "hand.point.up.left")
                  .font(.system(size: 16, weight: .medium))
                Text("Manuell auswählen")
                  .font(.headline)
                  .fontWeight(.medium)
              }
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 14)
                  .fill(.regularMaterial)
                  .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
              )
            }
            .accessibilityIdentifier("home.plan.manual")
            .accessibilityLabel("Manuell auswählen")

            if FeatureFlags.quickRoutePlanningEnabled {
              // Schnell planen (Quick)
              Button(action: {
                SecureLogger.shared.logInfo("⚡️ Quick‑Plan: Trigger gedrückt", category: .ui)
                Task { await startQuickPlanning() }
              }) {
                HStack(spacing: 10) {
                  Image(systemName: "bolt.circle")
                    .font(.system(size: 16, weight: .medium))
                  Text("Schnell planen")
                    .font(.headline)
                    .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                  RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                )
              }
              .accessibilityIdentifier("home.plan.quick")
              .accessibilityLabel("Schnell planen")
            }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 50)
        }
      }
      // Quick‑Planning Loader Overlay
      .overlay(
        Group {
          if isQuickPlanning {
            ZStack {
              Color.black.opacity(0.25).ignoresSafeArea()
              VStack(spacing: 16) {
                ProgressView().scaleEffect(1.2)
                Text(quickPlanningMessage)
                  .font(.body)
                  .foregroundColor(.white)
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
              .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55)))
            }
          }
        }
      )
    }
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    .sheet(isPresented: $showingRoutePlanning) {
      RoutePlanningView(onRouteGenerated: { route in
        activeRoute = route
        showingRoutePlanning = false // Dismiss the route planning sheet
        adjustCamera(to: route)
      })
      .onAppear {
        // Phase 3: Modus aus Startscreen vorbesetzen
        if let mode = desiredPlanningMode {
          NotificationCenter.default.post(name: .init("PresetPlanningMode"), object: nil, userInfo: ["mode": mode.rawValue])
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
          withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = MapCameraPosition.region(
              MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
              )
            )
          }
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
  }
}

#Preview {
  ContentView()
}

// MARK: - Private helpers
extension ContentView {
  /// Adjust camera to show entire route
  private func adjustCamera(to route: GeneratedRoute) {
    if let firstWaypoint = route.waypoints.first {
      let coordinates = route.waypoints.map { $0.coordinate }
      let minLat = coordinates.map { $0.latitude }.min() ?? firstWaypoint.coordinate.latitude
      let maxLat = coordinates.map { $0.latitude }.max() ?? firstWaypoint.coordinate.latitude
      let minLon = coordinates.map { $0.longitude }.min() ?? firstWaypoint.coordinate.longitude
      let maxLon = coordinates.map { $0.longitude }.max() ?? firstWaypoint.coordinate.longitude
      let center = CLLocationCoordinate2D(
        latitude: (minLat + maxLat) / 2,
        longitude: (minLon + maxLon) / 2
      )
      let span = MKCoordinateSpan(
        latitudeDelta: max(0.005, (maxLat - minLat) * 1.3),
        longitudeDelta: max(0.005, (maxLon - minLon) * 1.3)
      )
      withAnimation(.easeInOut(duration: 1.0)) {
        cameraPosition = MapCameraPosition.region(
          MKCoordinateRegion(center: center, span: span)
        )
      }
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
      // Phase 11: Resolve city and fetch POIs strictly within that city
      let fetchStart = Date()
      let city = try await GeoapifyAPIService.resolveCityContext(for: loc.coordinate)
      let pois = try await GeoapifyAPIService.fetchPOIsInCity(
        cityId: city.cityId,
        cityName: city.cityName,
        categories: PlaceCategory.geoapifyEssentialCategories
      )
      let fetchDuration = Date().timeIntervalSince(fetchStart)
      SecureLogger.shared.logInfo("Quick POI fetch: \(pois.count) results in \(String(format: "%.2f", fetchDuration))s", category: .performance)
      await MainActor.run { quickPlanningMessage = "Optimiere deine Route…" }
      // Generate route with fixed parameters
      let routeStart = Date()
      await quickRouteService.generateRoute(
        fromCurrentLocation: loc,
        maximumStops: .five,
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
          activeRoute = route
          adjustCamera(to: route)
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