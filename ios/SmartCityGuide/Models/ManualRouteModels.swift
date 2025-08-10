import Foundation
import CoreLocation

// MARK: - Route Planning Mode
enum RoutePlanningMode: String, CaseIterable {
    case automatic = "Automatisch"
    case manual = "Manuell erstellen"
}

// MARK: - Manual Route Configuration
/// Configuration for manual route planning
struct ManualRouteConfig {
    let startingCity: String
    let startingCoordinates: CLLocationCoordinate2D?
    let usingCurrentLocation: Bool
    let endpointOption: EndpointOption
    let customEndpoint: String
    let customEndpointCoordinates: CLLocationCoordinate2D?
}

// MARK: - Manual POI Selection State
/// User's manual POI selection state
class ManualPOISelection: ObservableObject {
    @Published var selectedPOIs: [POI] = []
    @Published var rejectedPOIs: Set<String> = [] // POI IDs
    @Published var currentCardIndex: Int = 0
    @Published private(set) var history: [POISelectionAction] = []
    
    var hasSelections: Bool {
        return !selectedPOIs.isEmpty
    }
    
    var canGenerateRoute: Bool {
        return selectedPOIs.count >= 1 // Mindestens 1 POI für Route
    }
    
    var canUndo: Bool { !history.isEmpty }
    
    /// Add a POI to the selection
    func selectPOI(_ poi: POI) {
        guard !selectedPOIs.contains(where: { $0.id == poi.id }) else { return }
        selectedPOIs.append(poi)
        rejectedPOIs.remove(poi.id)
        history.append(.select(poi))
    }
    
    /// Remove a POI from selection
    func deselectPOI(_ poi: POI) {
        selectedPOIs.removeAll { $0.id == poi.id }
    }
    
    /// Reject a POI (mark as not interested)
    func rejectPOI(_ poi: POI) {
        rejectedPOIs.insert(poi.id)
        selectedPOIs.removeAll { $0.id == poi.id }
        history.append(.reject(poi))
    }
    
    /// Check if POI is already selected
    func isSelected(_ poi: POI) -> Bool {
        return selectedPOIs.contains { $0.id == poi.id }
    }
    
    /// Check if POI is rejected
    func isRejected(_ poi: POI) -> Bool {
        return rejectedPOIs.contains(poi.id)
    }
    
    /// Undo last action if any
    @discardableResult
    func undoLast() -> POISelectionAction? {
        guard let last = history.popLast() else { return nil }
        switch last {
        case .select(let poi):
            selectedPOIs.removeAll { $0.id == poi.id }
        case .reject(let poi):
            rejectedPOIs.remove(poi.id)
        case .undo:
            break
        }
        return last
    }
    
    /// Reset all selections
    func reset() {
        selectedPOIs.removeAll()
        rejectedPOIs.removeAll()
        currentCardIndex = 0
        history.removeAll()
    }
}

// MARK: - Manual Route Request
/// Manual route generation request
struct ManualRouteRequest {
    let config: ManualRouteConfig
    let selectedPOIs: [POI]
    let allDiscoveredPOIs: [POI] // Für mögliche Enrichment-Referenzen
}

// MARK: - Manual Route Result
/// Result of manual route generation
struct ManualRouteResult {
    let generatedRoute: GeneratedRoute
    let optimizationMetrics: RouteOptimizationMetrics?
    let processingTime: TimeInterval
}

// MARK: - Route Optimization Metrics
/// Metrics about the TSP optimization for manual routes
struct RouteOptimizationMetrics {
    let originalDistance: Double // Air distance of selected order
    let optimizedDistance: Double // TSP optimized distance
    let improvementPercentage: Double
    let optimizationTime: TimeInterval
    
    var formattedOriginalDistance: String {
        return String(format: "%.1f km", originalDistance / 1000)
    }
    
    var formattedOptimizedDistance: String {
        return String(format: "%.1f km", optimizedDistance / 1000)
    }
    
    var formattedImprovement: String {
        return String(format: "%.1f%%", improvementPercentage)
    }
}

// MARK: - POI Selection Actions
enum POISelectionAction {
    case select(POI)    // Left swipe - add to route
    case reject(POI)    // Right swipe - skip
    case undo           // Optional: undo last action
}

// MARK: - Route Source
enum RouteSource {
    case automatic
    case manual(ManualRouteConfig)
    
    var isManual: Bool {
        switch self {
        case .manual:
            return true
        case .automatic:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .automatic:
            return "Automatisch generiert"
        case .manual:
            return "Manuell erstellt"
        }
    }
}