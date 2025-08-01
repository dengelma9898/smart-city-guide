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
  
  var body: some View {
    ZStack {
      // Fullscreen Map
      Map(position: $cameraPosition) {
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
          
          Spacer()
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
                Text("Aktive Route")
                  .font(.caption)
                  .foregroundColor(.secondary)
                
                Text("\(Int(route.totalDistance / 1000)) km • \(formatExperienceTime(route.totalExperienceTime))")
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
              
              Spacer()
              
              Text("\(route.numberOfStops) Stopps")
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
                  Text("Route stoppen")
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
                  Text("Ändern")
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
            }
          }
          .padding(.bottom, 50)
          
        } else {
          // No active route - Show plan route button
          VStack(spacing: 16) {
            // Plan Route Button - Main interaction
            Button(action: {
              showingRoutePlanning = true
            }) {
              HStack(spacing: 8) {
                Image(systemName: "location.north.line.fill")
                  .font(.system(size: 18, weight: .medium))
                Text("Route planen")
                  .font(.headline)
                  .fontWeight(.medium)
              }
              .foregroundColor(.white)
              .padding(.horizontal, 32)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 28)
                  .fill(.blue)
                  .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
              )
            }
          }
          .padding(.bottom, 50)
        }
      }
    }
    .sheet(isPresented: $showingProfile) {
      ProfileView()
    }
    .sheet(isPresented: $showingRoutePlanning) {
      RoutePlanningView(onRouteGenerated: { route in
        activeRoute = route
        showingRoutePlanning = false // Dismiss the route planning sheet
        // Adjust camera to show entire route
        if let firstWaypoint = route.waypoints.first,
           let lastWaypoint = route.waypoints.last {
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
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
          )
          
          withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = MapCameraPosition.region(
              MKCoordinateRegion(center: center, span: span)
            )
          }
        }
      })
    }
  }
}

// MARK: - Helper Functions
func formatExperienceTime(_ timeInterval: TimeInterval) -> String {
  let hours = Int(timeInterval / 3600)
  let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
  
  if hours > 0 {
    if minutes > 0 {
      return "\(hours)h \(minutes)min"
    } else {
      return "\(hours)h"
    }
  } else {
    return "\(minutes)min"
  }
}

struct CategoryStat {
  let category: PlaceCategory
  let count: Int
}

func getCategoryStats(for route: GeneratedRoute) -> [CategoryStat] {
  // Only count intermediate stops (exclude start and end points)
  let intermediateStops = route.waypoints.dropFirst().dropLast()
  
  let categoryGroups = Dictionary(grouping: intermediateStops) { $0.category }
  
  return categoryGroups.map { (category, waypoints) in
    CategoryStat(category: category, count: waypoints.count)
  }.sorted { $0.count > $1.count } // Sort by count descending
}

// MARK: - Profile View
struct ProfileView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Profile Header
          VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 80))
              .foregroundColor(.blue)
            
            Text("Max Mustermann")
              .font(.title2)
              .fontWeight(.semibold)
            
            Text("max.mustermann@email.de")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 20)
          
          // Profile Options
          VStack(spacing: 0) {
            ProfileRow(icon: "location.fill", title: "Gespeicherte Orte", subtitle: "5 Orte")
            ProfileRow(icon: "clock.fill", title: "Letzte Routen", subtitle: "12 Routen")
            ProfileRow(icon: "heart.fill", title: "Favoriten", subtitle: "8 Favoriten")
            ProfileRow(icon: "gearshape.fill", title: "Einstellungen", subtitle: "App-Einstellungen")
            ProfileRow(icon: "questionmark.circle.fill", title: "Hilfe & Support", subtitle: "Häufige Fragen")
          }
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(.systemGray6))
          )
          
          Spacer()
        }
        .padding(.horizontal, 20)
      }
      .navigationTitle("Profil")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Route Planning View
struct RoutePlanningView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var startingCity = ""
  @State private var numberOfPlaces = 3
  @State private var endpointOption: EndpointOption = .roundtrip
  @State private var customEndpoint = ""
  @State private var routeLength: RouteLength = .medium
  @State private var showingRouteBuilder = false
  
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  enum EndpointOption: String, CaseIterable {
    case roundtrip = "Rundreise"
    case lastPlace = "Letzter Ort"
    case custom = "Anderer Ort"
    
    var description: String {
      switch self {
      case .roundtrip:
        return "Zurück zum Startpunkt"
      case .lastPlace:
        return "Bei letztem besuchten Ort enden"
      case .custom:
        return "Eigenen Endpunkt wählen"
      }
    }
  }
  
  enum RouteLength: String, CaseIterable {
    case short = "Kurz"
    case medium = "Mittel"  
    case long = "Lang"
    
    var description: String {
      switch self {
      case .short:
        return "Bis zu 5km Gesamtstrecke"
      case .medium:
        return "Bis zu 15km Gesamtstrecke"
      case .long:
        return "Über 15km Gesamtstrecke"
      }
    }
    
    var maxTotalDistanceMeters: Double {
      switch self {
      case .short:
        return 5000   // 5km total route
      case .medium:
        return 15000  // 15km total route
      case .long:
        return 50000  // 50km total route
      }
    }
    
    var searchRadiusMeters: Double {
      switch self {
      case .short:
        return 3000   // Search within 3km for short routes
      case .medium:
        return 8000   // Search within 8km for medium routes
      case .long:
        return 15000  // Search within 15km for long routes
      }
    }
  }
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 32) {
          // Header
          VStack(spacing: 12) {
            Text("Route konfigurieren")
              .font(.title2)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)
            
            Text("Erstellen Sie Ihre perfekte Städtereise mit mehreren Stopps")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.top, 20)
          
          VStack(spacing: 24) {
            // Starting Point Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "location.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Startpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wählen Sie die Stadt, in der Ihre Route beginnt")
                .font(.caption)
                .foregroundColor(.secondary)
              
              LocationSearchField(
                placeholder: "z.B. Berlin, München, Hamburg",
                text: $startingCity
              )
            }
            
            // Number of Places Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "map.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Anzahl Orte")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wie viele Zwischenstopps möchten Sie zwischen Start und Ziel?")
                .font(.caption)
                .foregroundColor(.secondary)
              
              HStack(spacing: 12) {
                ForEach(2...5, id: \.self) { number in
                  Button(action: {
                    numberOfPlaces = number
                  }) {
                    Text("\(number)")
                      .font(.headline)
                      .fontWeight(.medium)
                      .foregroundColor(numberOfPlaces == number ? .white : .blue)
                      .frame(width: 50, height: 50)
                      .background(
                        Circle()
                          .fill(numberOfPlaces == number ? .blue : Color(.systemGray6))
                      )
                  }
                }
                
                Spacer()
                
                Text("\(numberOfPlaces) Zwischenstopps")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
            
            // Route Length Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "ruler.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Routenlänge")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wie lang soll die gesamte Route werden?")
                .font(.caption)
                .foregroundColor(.secondary)
              
              HStack(spacing: 12) {
                ForEach(RouteLength.allCases, id: \.self) { length in
                  Button(action: {
                    routeLength = length
                  }) {
                    VStack(spacing: 6) {
                      Text(length.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                      
                      Text(length.description)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    }
                    .foregroundColor(routeLength == length ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(routeLength == length ? .blue : Color(.systemGray6))
                    )
                  }
                }
              }
            }
            
            // Endpoint Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.blue)
                  .font(.system(size: 20))
                
                Text("Endpunkt")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              
              Text("Wo soll Ihre Route enden? (Optional)")
                .font(.caption)
                .foregroundColor(.secondary)
              
              VStack(spacing: 8) {
                ForEach(EndpointOption.allCases, id: \.self) { option in
                  Button(action: {
                    endpointOption = option
                  }) {
                    HStack {
                      Image(systemName: endpointOption == option ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(endpointOption == option ? .blue : .secondary)
                        .font(.system(size: 20))
                      
                      VStack(alignment: .leading, spacing: 2) {
                        Text(option.rawValue)
                          .font(.body)
                          .fontWeight(.medium)
                          .foregroundColor(.primary)
                        
                        Text(option.description)
                          .font(.caption)
                          .foregroundColor(.secondary)
                      }
                      
                      Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                      RoundedRectangle(cornerRadius: 10)
                        .fill(endpointOption == option ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
                    )
                  }
                }
                
                if endpointOption == .custom {
                  LocationSearchField(
                    placeholder: "Gewünschter Endpunkt",
                    text: $customEndpoint
                  )
                  .padding(.top, 8)
                }
              }
            }
          }
          .padding(.horizontal, 20)
          
          // Continue Button
          Button(action: {
            showingRouteBuilder = true
          }) {
            HStack(spacing: 8) {
              Text("Route erstellen")
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
          .padding(.bottom, 30)
        }
      }
      .navigationTitle("Route planen")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
    .sheet(isPresented: $showingRouteBuilder) {
      RouteBuilderView(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength,
        onRouteGenerated: onRouteGenerated
      )
    }
  }
}

// MARK: - Helper Views
struct ProfileRow: View {
  let icon: String
  let title: String
  let subtitle: String
  
  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 18))
        .foregroundColor(.blue)
        .frame(width: 24)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
        
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      Image(systemName: "chevron.right")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}

// MARK: - Place Categories
enum PlaceCategory: String, CaseIterable {
  case attraction = "Sehenswürdigkeit"
  case museum = "Museum"
  case park = "Park"
  case nationalPark = "Nationalpark"
  
  var icon: String {
    switch self {
    case .attraction: return "star.fill"
    case .museum: return "building.columns.fill"
    case .park: return "tree.fill"
    case .nationalPark: return "mountain.2.fill"
    }
  }
  
  var color: Color {
    switch self {
    case .attraction: return .orange
    case .museum: return .purple
    case .park: return .green
    case .nationalPark: return .blue
    }
  }
  
  var searchTerms: [String] {
    switch self {
    case .attraction:
      return ["sehenswürdigkeiten", "tourist attractions", "landmarks", "monument", "historic sites"]
    case .museum:
      return ["museen", "galleries", "ausstellungen", "art gallery", "history museum"] 
    case .park:
      return ["parks", "gärten", "grünflächen", "green spaces", "botanical garden"]
    case .nationalPark:
      return ["nationalpark", "national park", "nature reserve", "wildlife park", "forest park"]
    }
  }
  
  static func classify(_ mapItem: MKMapItem) -> PlaceCategory {
    let name = mapItem.name?.lowercased() ?? ""
    let category = mapItem.pointOfInterestCategory
    
    // First check MKPointOfInterestCategory
    if let category = category {
      switch category {
      case .museum:
        return .museum
      case .nationalPark:
        return .nationalPark
      case .park:
        return .park
      default:
        break
      }
    }
    
    // Fallback to name-based classification
    if name.contains("museum") || name.contains("galerie") {
      return .museum  
    } else if name.contains("nationalpark") || name.contains("national park") {
      return .nationalPark
    } else if name.contains("park") || name.contains("garten") {
      return .park
    }
    
    return .attraction // Default fallback
  }
}

struct CategoryDistribution {
  static let target: [PlaceCategory: Double] = [
    .attraction: 0.4,      // 40%
    .museum: 0.3,          // 30%
    .park: 0.2,            // 20%
    .nationalPark: 0.1     // 10%
  ]
}

// MARK: - Route Models and Service
struct RoutePoint {
  let name: String
  let coordinate: CLLocationCoordinate2D
  let address: String
  let category: PlaceCategory
  let phoneNumber: String?
  let url: URL?
  let pointOfInterestCategory: MKPointOfInterestCategory?
  
  init(from mapItem: MKMapItem) {
    self.name = mapItem.name ?? "Unbekannter Ort"
    self.coordinate = mapItem.placemark.coordinate
    self.address = mapItem.placemark.title ?? ""
    self.category = PlaceCategory.classify(mapItem)
    self.phoneNumber = mapItem.phoneNumber
    self.url = mapItem.url
    self.pointOfInterestCategory = mapItem.pointOfInterestCategory
  }
  
  init(name: String, coordinate: CLLocationCoordinate2D, address: String, category: PlaceCategory = .attraction, phoneNumber: String? = nil, url: URL? = nil) {
    self.name = name
    self.coordinate = coordinate
    self.address = address
    self.category = category
    self.phoneNumber = phoneNumber
    self.url = url
    self.pointOfInterestCategory = nil
  }
}

struct GeneratedRoute {
  let waypoints: [RoutePoint]
  let routes: [MKRoute]
  let totalDistance: CLLocationDistance  
  let totalTravelTime: TimeInterval
  let totalVisitTime: TimeInterval
  let totalExperienceTime: TimeInterval
  
  var numberOfStops: Int {
    // Exclude start and end points from stop count
    max(0, waypoints.count - 2)
  }
  
  var walkingTimes: [TimeInterval] {
    return routes.map { $0.expectedTravelTime }
  }
  
  var walkingDistances: [CLLocationDistance] {
    return routes.map { $0.distance }
  }
}

@MainActor
class RouteService: ObservableObject {
  @Published var isGenerating = false
  @Published var generatedRoute: GeneratedRoute?
  @Published var errorMessage: String?
  
  func generateRoute(
    startingCity: String,
    numberOfPlaces: Int,
    endpointOption: RoutePlanningView.EndpointOption,
    customEndpoint: String,
    routeLength: RoutePlanningView.RouteLength
  ) async {
    isGenerating = true
    errorMessage = nil
    generatedRoute = nil
    
    do {
      // Step 1: Find starting location
      let startLocation = try await findLocation(query: startingCity)
      
      // Step 2: Find interesting places based on endpoint option
      var waypoints: [RoutePoint]
      
      // Find optimal route combination that fits within distance limit
      waypoints = try await findOptimalRoute(
        startLocation: startLocation,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength
      )
      
      // Step 4: Generate routes between waypoints
      let routes = try await generateRoutesBetweenWaypoints(waypoints)
      
      // Step 5: Calculate totals
      let totalDistance = routes.reduce(0) { $0 + $1.distance }
      let totalWalkingTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
      
      // Calculate visit time (30min to 1hr per stop, excluding start/end points)
      let numberOfStops = max(0, waypoints.count - 2)
      let minVisitTime = TimeInterval(numberOfStops * 30 * 60) // 30 min per stop
      let maxVisitTime = TimeInterval(numberOfStops * 60 * 60) // 60 min per stop
      let averageVisitTime = (minVisitTime + maxVisitTime) / 2
      
      let totalExperienceTime = totalWalkingTime + averageVisitTime
      
      generatedRoute = GeneratedRoute(
        waypoints: waypoints,
        routes: routes,
        totalDistance: totalDistance,
        totalTravelTime: totalWalkingTime,
        totalVisitTime: averageVisitTime,
        totalExperienceTime: totalExperienceTime
      )
      
    } catch {
      errorMessage = "Fehler beim Erstellen der Route: \(error.localizedDescription)"
    }
    
    isGenerating = false
  }
  
  private func findLocation(query: String) async throws -> RoutePoint {
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = query
      request.resultTypes = [.address, .pointOfInterest]
      
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let firstResult = response?.mapItems.first {
          continuation.resume(returning: RoutePoint(from: firstResult))
        } else {
          continuation.resume(throwing: NSError(
            domain: "RouteService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Ort nicht gefunden: \(query)"]
          ))
        }
      }
    }
  }
  
  private func findOptimalRoute(
    startLocation: RoutePoint,
    numberOfPlaces: Int,
    endpointOption: RoutePlanningView.EndpointOption,
    customEndpoint: String,
    routeLength: RoutePlanningView.RouteLength
  ) async throws -> [RoutePoint] {
    
    // Step 1: Get many potential places
    let potentialPlaces = try await findInterestingPlaces(
      near: startLocation.coordinate,
      count: numberOfPlaces * 5, // Get 5x more places for better selection
      maxDistance: routeLength.searchRadiusMeters,
      excluding: [startLocation]
    )
    
    // Always try with available places, even if fewer than requested
    // The distance checking will handle reduction if needed
    let actualCount = min(numberOfPlaces, potentialPlaces.count)
    
    guard actualCount > 0 else {
      throw NSError(
        domain: "RouteService", 
        code: 404,
        userInfo: [NSLocalizedDescriptionKey: "Keine interessanten Orte in der Nähe von \(startLocation.name) gefunden."]
      )
    }
    
    // Step 2: Try different combinations to find optimal route
    let bestCombination = try await findBestRouteCombination(
      startLocation: startLocation,
      potentialPlaces: potentialPlaces,
      numberOfPlaces: actualCount,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint,
      maxTotalDistance: routeLength.maxTotalDistanceMeters
    )
    
    return bestCombination
  }
  
  private func findBestRouteCombination(
    startLocation: RoutePoint,
    potentialPlaces: [RoutePoint],
    numberOfPlaces: Int,
    endpointOption: RoutePlanningView.EndpointOption,
    customEndpoint: String,
    maxTotalDistance: Double
  ) async throws -> [RoutePoint] {
    
    var bestRoute: [RoutePoint] = []
    var bestDistance: Double = Double.infinity
    
    // Try up to 10 different combinations
    let maxAttempts = min(10, potentialPlaces.count)
    
    for attempt in 0..<maxAttempts {
      // Select a different combination of places
      let selectedPlaces = selectPlacesForAttempt(
        from: potentialPlaces,
        count: numberOfPlaces,
        attempt: attempt
      )
      
      // Build route with endpoint logic
      let testRoute = try await buildRouteWithEndpoint(
        startLocation: startLocation,
        places: selectedPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint
      )
      
      // Calculate ACTUAL walking distance using real routes
      let testRoutes = try await generateRoutesBetweenWaypoints(testRoute)
      let actualDistance = testRoutes.reduce(0) { $0 + $1.distance }
      
      print("🔍 Teste Route: \(testRoute.count) Waypoints")
      print("   Luftlinie: \(Int(calculateTotalRouteDistance(testRoute)/1000))km")
      print("   Tatsächlich: \(Int(actualDistance/1000))km (Limit: \(Int(maxTotalDistance/1000))km)")
      
      // Check if this is better and within limits using ACTUAL distance
      if actualDistance <= maxTotalDistance && actualDistance < bestDistance {
        bestRoute = testRoute
        bestDistance = actualDistance
        print("   ✅ NEUE BESTE ROUTE: \(Int(actualDistance/1000))km")
      } else {
        print("   ❌ ZU LANG: \(Int(actualDistance/1000))km > \(Int(maxTotalDistance/1000))km")
      }
      
      // If we found a good short route, stop early
      if bestDistance <= maxTotalDistance * 0.8 {
        break
      }
    }
    
    // If no route found within distance limit, try with fewer stops
    if bestRoute.isEmpty && numberOfPlaces > 1 {
      print("⚠️ Keine Route mit \(numberOfPlaces) Stopps innerhalb \(Int(maxTotalDistance/1000))km gefunden")
      print("🔄 Versuche mit \(numberOfPlaces-1) Stopps...")
      
      // Retry with one fewer place
      return try await findBestRouteCombination(
        startLocation: startLocation,
        potentialPlaces: potentialPlaces,
        numberOfPlaces: numberOfPlaces - 1,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        maxTotalDistance: maxTotalDistance
      )
    }
    
    // If still no route found, throw error instead of exceeding distance limit
    guard !bestRoute.isEmpty else {
      throw NSError(
        domain: "RouteService",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "Keine Route innerhalb der gewünschten Entfernung von \(Int(maxTotalDistance/1000))km möglich. Versuchen Sie eine längere Routenoption oder weniger Zwischenstopps."]
      )
    }
    
    return bestRoute
  }
  
  private func selectPlacesForAttempt(
    from places: [RoutePoint],
    count: Int,
    attempt: Int
  ) -> [RoutePoint] {
    let startIndex = attempt * 2 % max(1, places.count - count)
    let endIndex = min(startIndex + count, places.count)
    return Array(places[startIndex..<endIndex])
  }
  
  private func buildRouteWithEndpoint(
    startLocation: RoutePoint,
    places: [RoutePoint],
    endpointOption: RoutePlanningView.EndpointOption,
    customEndpoint: String
  ) async throws -> [RoutePoint] {
    
    switch endpointOption {
    case .roundtrip:
      return [startLocation] + places + [startLocation]
      
    case .custom:
      if !customEndpoint.isEmpty {
        let endLocation = try await findLocation(query: customEndpoint)
        return [startLocation] + places + [endLocation]
      } else {
        return [startLocation] + places
      }
      
    case .lastPlace:
      return [startLocation] + places
    }
  }
  
  private func buildSimpleRoute(
    startLocation: RoutePoint,
    places: [RoutePoint],
    endpointOption: RoutePlanningView.EndpointOption,
    customEndpoint: String
  ) async throws -> [RoutePoint] {
    
    return try await buildRouteWithEndpoint(
      startLocation: startLocation,
      places: places,
      endpointOption: endpointOption,
      customEndpoint: customEndpoint
    )
  }
  
  private func calculateTotalRouteDistance(_ waypoints: [RoutePoint]) -> Double {
    var totalDistance: Double = 0
    
    for i in 0..<waypoints.count-1 {
      let distance = distance(
        from: waypoints[i].coordinate,
        to: waypoints[i+1].coordinate
      )
      totalDistance += distance
    }
    
    return totalDistance
  }
  
  private func findInterestingPlaces(
    near coordinate: CLLocationCoordinate2D,
    count: Int,
    maxDistance: Double,
    excluding excludedLocations: [RoutePoint] = []
  ) async throws -> [RoutePoint] {
    
    // Calculate how many places we need per category based on distribution
    let targetCounts = calculateCategoryTargets(totalCount: count)
    
    // Search for places in each category in parallel
    async let attractions = searchPlacesByCategory(.attraction, near: coordinate, maxDistance: maxDistance, count: targetCounts[.attraction] ?? 0)
    async let museums = searchPlacesByCategory(.museum, near: coordinate, maxDistance: maxDistance, count: targetCounts[.museum] ?? 0)
    async let parks = searchPlacesByCategory(.park, near: coordinate, maxDistance: maxDistance, count: targetCounts[.park] ?? 0)
    async let nationalParks = searchPlacesByCategory(.nationalPark, near: coordinate, maxDistance: maxDistance, count: targetCounts[.nationalPark] ?? 0)
    
    // Wait for all searches to complete
    let categoryResults = try await [attractions, museums, parks, nationalParks]
    var allPlaces: [RoutePoint] = []
    
    // Combine results from all categories
    for categoryPlaces in categoryResults {
      allPlaces.append(contentsOf: categoryPlaces)
    }
    
    // Filter out excluded locations and enforce distance limit
    let filteredPlaces = allPlaces.filter { place in
      // Check if not excluded
      let notExcluded = !excludedLocations.contains { excluded in
        self.distance(from: place.coordinate, to: excluded.coordinate) < 100 // 100m threshold
      }
      
      // Check distance from center
      let distanceFromCenter = self.distance(from: coordinate, to: place.coordinate)
      
      return notExcluded && distanceFromCenter <= maxDistance
    }
    
    // If we don't have enough places, fill with attractions as fallback
    var selectedPlaces = filteredPlaces
    if selectedPlaces.count < count {
      let fallbackPlaces = try await searchPlacesByCategory(.attraction, near: coordinate, maxDistance: maxDistance, count: count - selectedPlaces.count)
      selectedPlaces.append(contentsOf: fallbackPlaces.filter { fallback in
        !selectedPlaces.contains { existing in
          self.distance(from: fallback.coordinate, to: existing.coordinate) < 100
        }
      })
    }
    
    // Apply geographic distribution to avoid clustering
    let distributedPlaces = applyGeographicDistribution(selectedPlaces, maxCount: count)
    
    return distributedPlaces
  }
  
  private func calculateCategoryTargets(totalCount: Int) -> [PlaceCategory: Int] {
    var targets: [PlaceCategory: Int] = [:]
    var remainingCount = totalCount
    
    // Calculate targets based on distribution percentages
    for (category, percentage) in CategoryDistribution.target {
      let targetCount = Int(Double(totalCount) * percentage)
      targets[category] = targetCount
      remainingCount -= targetCount
    }
    
    // Distribute any remaining places to attractions
    if remainingCount > 0 {
      targets[.attraction] = (targets[.attraction] ?? 0) + remainingCount
    }
    
    return targets
  }
  
  private func searchPlacesByCategory(
    _ category: PlaceCategory,
    near coordinate: CLLocationCoordinate2D,
    maxDistance: Double,
    count: Int
  ) async throws -> [RoutePoint] {
    
    // Skip if no places needed for this category
    guard count > 0 else { return [] }
    
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKLocalSearch.Request()
      
      // Use category-specific search terms
      request.naturalLanguageQuery = category.searchTerms.joined(separator: " ")
      
      request.region = MKCoordinateRegion(
        center: coordinate,
        latitudinalMeters: maxDistance * 2,
        longitudinalMeters: maxDistance * 2
      )
      request.resultTypes = [.pointOfInterest]
      
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let mapItems = response?.mapItems {
          // Convert to RoutePoints and verify category classification
          let categoryPlaces = mapItems
            .map { RoutePoint(from: $0) }
            .filter { $0.category == category || category == .attraction } // Accept any for attractions as fallback
            .prefix(count * 2) // Get extra for better selection
          
          continuation.resume(returning: Array(categoryPlaces))
        } else {
          continuation.resume(returning: [])
        }
      }
    }
  }
  
  private func applyGeographicDistribution(_ places: [RoutePoint], maxCount: Int) -> [RoutePoint] {
    guard places.count > maxCount else {
      return places
    }
    
    var selectedPlaces: [RoutePoint] = []
    var remainingPlaces = places
    
    // Minimum distance between places (in meters) to avoid clustering
    let minDistanceBetweenPlaces: CLLocationDistance = 200
    
    // Select places with geographic distribution
    while selectedPlaces.count < maxCount && !remainingPlaces.isEmpty {
      if selectedPlaces.isEmpty {
        // Select first place randomly
        let randomIndex = Int.random(in: 0..<remainingPlaces.count)
        selectedPlaces.append(remainingPlaces.remove(at: randomIndex))
      } else {
        // Find the place that is furthest from all already selected places
        var bestPlace: RoutePoint?
        var bestMinDistance: CLLocationDistance = 0
        var bestIndex = 0
        
        for (index, candidate) in remainingPlaces.enumerated() {
          // Calculate minimum distance to any already selected place
          let minDistanceToSelected = selectedPlaces.map { selected in
            distance(from: candidate.coordinate, to: selected.coordinate)
          }.min() ?? 0
          
          // Prefer places that are farther away from existing selections
          if minDistanceToSelected > bestMinDistance {
            bestMinDistance = minDistanceToSelected
            bestPlace = candidate
            bestIndex = index
          }
        }
        
        // If we found a good candidate, add it
        if let place = bestPlace, bestMinDistance >= minDistanceBetweenPlaces {
          selectedPlaces.append(place)
          remainingPlaces.remove(at: bestIndex)
        } else {
          // If no place meets the distance criteria, just take the best available
          if let place = bestPlace {
            selectedPlaces.append(place)
            remainingPlaces.remove(at: bestIndex)
          } else {
            break
          }
        }
      }
    }
    
    return selectedPlaces
  }
  
  private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
  
  private func generateRoutesBetweenWaypoints(_ waypoints: [RoutePoint]) async throws -> [MKRoute] {
    var routes: [MKRoute] = []
    
    for i in 0..<waypoints.count-1 {
      let startPoint = waypoints[i]
      let endPoint = waypoints[i+1]
      
      let route = try await generateSingleRoute(
        from: startPoint.coordinate,
        to: endPoint.coordinate
      )
      routes.append(route)
      
      // Small delay to avoid rate limiting
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    return routes
  }
  
  private func generateSingleRoute(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D
  ) async throws -> MKRoute {
    return try await withCheckedThrowingContinuation { continuation in
      let request = MKDirections.Request()
      request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
      request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
      request.transportType = .walking
      
      let directions = MKDirections(request: request)
      directions.calculate { response, error in
        if let error = error {
          continuation.resume(throwing: error)
        } else if let route = response?.routes.first {
          continuation.resume(returning: route)
        } else {
          continuation.resume(throwing: NSError(
            domain: "RouteService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Keine Route gefunden"]
          ))
        }
      }
    }
  }
}

// MARK: - Location Search Field with Autocomplete
struct LocationSearchField: View {
  let placeholder: String
  @Binding var text: String
  @State private var searchResults: [MKMapItem] = []
  @State private var isSearching = false
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TextField(placeholder, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .focused($isFocused)
        .onChange(of: text) { newValue in
          if !newValue.isEmpty {
            searchLocations(query: newValue)
          } else {
            searchResults = []
          }
        }
      
      if !searchResults.isEmpty && isFocused {
        VStack(spacing: 0) {
          ForEach(searchResults.prefix(5), id: \.self) { item in
            Button(action: {
              selectLocation(item)
            }) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.name ?? "Unbekannter Ort")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                  
                  if let address = item.placemark.title {
                    Text(address)
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .lineLimit(1)
                  }
                }
                
                Spacer()
                
                Image(systemName: "location.fill")
                  .font(.system(size: 12))
                  .foregroundColor(.blue)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            
            if item != searchResults.prefix(5).last {
              Divider()
                .padding(.leading, 12)
            }
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.top, 4)
      }
    }
  }
  
  private func searchLocations(query: String) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.resultTypes = [.address, .pointOfInterest]
    
    let search = MKLocalSearch(request: request)
    search.start { response, error in
      DispatchQueue.main.async {
        if let response = response {
          self.searchResults = response.mapItems
        } else {
          self.searchResults = []
        }
      }
    }
  }
  
  private func selectLocation(_ item: MKMapItem) {
    text = formatFullAddress(item.placemark)
    searchResults = []
    isFocused = false
  }
  
  private func formatFullAddress(_ placemark: MKPlacemark) -> String {
    var components: [String] = []
    
    // Add street name and number
    if let thoroughfare = placemark.thoroughfare {
      var streetComponent = thoroughfare
      if let subThoroughfare = placemark.subThoroughfare {
        streetComponent = "\(thoroughfare) \(subThoroughfare)"
      }
      components.append(streetComponent)
    }
    
    // Add postal code and city
    var cityComponent: String? = nil
    if let postalCode = placemark.postalCode, let locality = placemark.locality {
      cityComponent = "\(postalCode) \(locality)"
    } else if let locality = placemark.locality {
      cityComponent = locality
    }
    
    if let city = cityComponent {
      components.append(city)
    }
    
    return components.joined(separator: ", ")
  }
}

// MARK: - Route Builder View (Next Step)
struct RouteBuilderView: View {
  @Environment(\.dismiss) private var dismiss
  let startingCity: String
  let numberOfPlaces: Int
  let endpointOption: RoutePlanningView.EndpointOption
  let customEndpoint: String
  let routeLength: RoutePlanningView.RouteLength
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  @StateObject private var routeService = RouteService()
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          if routeService.isGenerating {
            // Header - only show during generation
            VStack(spacing: 12) {
              Text("Route wird erstellt...")
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("Wir suchen die besten \(numberOfPlaces) Zwischenstopps in \(startingCity)")
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
              
              Text("Route wird berechnet...")
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
          } else if let route = routeService.generatedRoute {
            // Success State - Show Generated Route
            VStack(spacing: 20) {
              
              // Waypoints List
              VStack(alignment: .leading, spacing: 12) {
                Text("Route Details")
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
                    Text("Gesamtstrecke")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text(formatExperienceTime(route.totalExperienceTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Gesamtzeit")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text("\(route.numberOfStops)")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Stopps")
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
                Text("Zeitaufteilung")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("🚶‍♂️ Gehzeit")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalTravelTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.blue)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("📍 Besichtigungszeit")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalVisitTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.orange)
                  }
                }
                
                HStack {
                  Text("⏱️ Gesamte Erlebniszeit:")
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
                
                Text("💡 Basiert auf 30-60 Minuten pro Stopp (ohne Start- und Endpunkt)")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.top, 4)
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Use Route Button
              Button(action: {
                onRouteGenerated(route)
                dismiss()
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "map")
                    .font(.system(size: 18, weight: .medium))
                  Text("Route auf Karte anzeigen")
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
              
              Text("Fehler beim Erstellen der Route")
                .font(.headline)
                .fontWeight(.semibold)
              
              Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
              
              Button("Erneut versuchen") {
                Task {
                  await routeService.generateRoute(
                    startingCity: startingCity,
                    numberOfPlaces: numberOfPlaces,
                    endpointOption: endpointOption,
                    customEndpoint: customEndpoint,
                    routeLength: routeLength
                  )
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
      .navigationTitle("Route erstellen")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
    .task {
      await routeService.generateRoute(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength
      )
    }
  }
}

#Preview {
  ContentView()
}
