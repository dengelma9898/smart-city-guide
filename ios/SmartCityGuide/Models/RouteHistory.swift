import Foundation
import CoreLocation

// MARK: - Route History Models
struct SavedRoute: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let startLocation: String
    let endLocation: String?
    let numberOfStops: Int
    let totalDistance: Double // in meters
    let totalDuration: TimeInterval // in seconds
    let routeLength: RouteLength
    let endpointOption: EndpointOption
    let waypoints: [SavedWaypoint]
    let createdAt: Date
    let lastUsedAt: Date?
    
    init(from route: GeneratedRoute, name: String, routeLength: RouteLength, endpointOption: EndpointOption) {
        self.id = UUID()
        self.name = name
        self.startLocation = route.waypoints.first?.name ?? "Unbekannt"
        self.endLocation = route.waypoints.last?.name != route.waypoints.first?.name ? route.waypoints.last?.name : nil
        self.numberOfStops = route.numberOfStops
        self.totalDistance = route.totalDistance
        self.totalDuration = route.totalExperienceTime
        self.routeLength = routeLength
        self.endpointOption = endpointOption
        self.waypoints = route.waypoints.map { SavedWaypoint(from: $0) }
        self.createdAt = Date()
        self.lastUsedAt = nil
    }
    
    init(id: UUID, name: String, startLocation: String, endLocation: String?, numberOfStops: Int, totalDistance: Double, totalDuration: TimeInterval, routeLength: RouteLength, endpointOption: EndpointOption, waypoints: [SavedWaypoint], createdAt: Date, lastUsedAt: Date?) {
        self.id = id
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.numberOfStops = numberOfStops
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.routeLength = routeLength
        self.endpointOption = endpointOption
        self.waypoints = waypoints
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
    
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        } else {
            return "\(Int(totalDistance)) m"
        }
    }
    
    var formattedDuration: String {
        return formatExperienceTime(totalDuration)
    }
    
    var isRoundtrip: Bool {
        return endpointOption == .roundtrip
    }
    
    static func == (lhs: SavedRoute, rhs: SavedRoute) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SavedWaypoint: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: PlaceCategory
    
    init(from waypoint: RoutePoint) {
        self.name = waypoint.name
        self.address = waypoint.address
        self.latitude = waypoint.coordinate.latitude
        self.longitude = waypoint.coordinate.longitude
        self.category = waypoint.category
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Route History Manager
@MainActor
class RouteHistoryManager: ObservableObject {
    @Published var savedRoutes: [SavedRoute] = []
    
    private let userDefaultsKey = "route_history"
    private let maxSavedRoutes = 50 // Limit to prevent storage bloat
    
    init() {
        loadRoutes()
    }
    
    private func loadRoutes() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let routes = try? JSONDecoder().decode([SavedRoute].self, from: data) {
            self.savedRoutes = routes.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    private func saveRoutes() {
        // Limit to max saved routes
        if savedRoutes.count > maxSavedRoutes {
            savedRoutes = Array(savedRoutes.prefix(maxSavedRoutes))
        }
        
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func saveRoute(_ route: GeneratedRoute, name: String? = nil, routeLength: RouteLength, endpointOption: EndpointOption) {
        let routeName = name ?? generateRouteName(for: route)
        let savedRoute = SavedRoute(
            from: route,
            name: routeName,
            routeLength: routeLength,
            endpointOption: endpointOption
        )
        
        // Check if similar route exists (same waypoints)
        if !savedRoutes.contains(where: { existingRoute in
            existingRoute.waypoints.map { $0.name } == savedRoute.waypoints.map { $0.name }
        }) {
            savedRoutes.insert(savedRoute, at: 0)
            saveRoutes()
        }
    }
    
    func deleteRoute(_ route: SavedRoute) {
        savedRoutes.removeAll { $0.id == route.id }
        saveRoutes()
    }
    
    func markRouteAsUsed(_ route: SavedRoute) {
        if let index = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            // Create a new SavedRoute with updated lastUsedAt
            let updatedRoute = SavedRoute(
                id: route.id,
                name: route.name,
                startLocation: route.startLocation,
                endLocation: route.endLocation,
                numberOfStops: route.numberOfStops,
                totalDistance: route.totalDistance,
                totalDuration: route.totalDuration,
                routeLength: route.routeLength,
                endpointOption: route.endpointOption,
                waypoints: route.waypoints,
                createdAt: route.createdAt,
                lastUsedAt: Date()
            )
            savedRoutes[index] = updatedRoute
            saveRoutes()
        }
    }
    
    func clearHistory() {
        savedRoutes.removeAll()
        saveRoutes()
    }
    
    private func generateRouteName(for route: GeneratedRoute) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let startLocation = route.waypoints.first?.name.components(separatedBy: ",").first ?? "Route"
        return "\(startLocation) • \(formatter.string(from: Date()))"
    }
}

// MARK: - SavedRoute Extensions for UI
extension SavedRoute {
    var routeTypeDescription: String {
        switch endpointOption {
        case .roundtrip:
            return "Rundreise"
        case .lastPlace:
            return "Einfache Strecke"
        case .custom:
            return "Benutzerdefiniert"
        }
    }
    
    var routeLengthDescription: String {
        return routeLength.rawValue
    }
    
    var categoryStats: [PlaceCategory: Int] {
        let intermediateWaypoints = waypoints.dropFirst().dropLast()
        return Dictionary(grouping: intermediateWaypoints) { $0.category }
            .mapValues { $0.count }
    }
}