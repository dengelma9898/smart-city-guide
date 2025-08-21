# Swift Style Guide

## Indentation & Spacing

- Use 4 spaces for indentation (never tabs)
- Add blank lines to separate logical sections of code
- Use single blank line between methods
- No trailing whitespace on any line

## Code Organization

### File Structure
```swift
// 1. Import statements
import SwiftUI
import MapKit

// 2. Type definitions
struct ContentView: View {
    // 3. Properties (grouped by type)
    @State private var isLoading = false
    @StateObject private var locationManager = LocationManager()
    
    // 4. Computed properties
    var body: some View {
        // Implementation
    }
    
    // 5. Methods (grouped by functionality)
    private func setupLocationServices() {
        // Implementation
    }
}

// 6. Extensions
extension ContentView {
    // Protocol conformance or additional functionality
}
```

### MARK Comments
Use `// MARK: -` to organize code sections:

```swift
class RouteService {
    // MARK: - Properties
    private let apiService = APIService()
    
    // MARK: - Public API
    func generateRoute() async throws -> Route {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func optimizeRoute(_ points: [RoutePoint]) -> [RoutePoint] {
        // Implementation
    }
}
```

## Naming Conventions

### Variables and Methods
- Use descriptive camelCase names
- Start with lowercase letter
- Be explicit rather than abbreviated

```swift
// ✅ Good
let userLocationCoordinate: CLLocationCoordinate2D
func calculateOptimalRoute(from startPoint: RoutePoint) -> Route

// ❌ Bad  
let usrLoc: CLLocationCoordinate2D
func calcRoute(from start: RoutePoint) -> Route
```

### Types (Classes, Structs, Enums, Protocols)
- Use descriptive PascalCase names
- Start with uppercase letter

```swift
// ✅ Good
struct RouteGenerationService
class LocationManagerService
protocol POIServiceProtocol
enum PlaceCategory

// ❌ Bad
struct routeGen
class locMgr
protocol POIService_Protocol
```

### Constants
- Use camelCase for local constants
- Use PascalCase for static/global constants

```swift
// ✅ Good
let maxRetryCount = 3
static let DefaultCacheTimeout: TimeInterval = 3600

// ❌ Bad
let MAX_RETRY_COUNT = 3
static let default_cache_timeout: TimeInterval = 3600
```

## SwiftUI Specific Guidelines

### Property Wrappers
```swift
struct ProfileView: View {
    // State for local view data
    @State private var isEditing = false
    
    // StateObject for creating observed objects
    @StateObject private var viewModel = ProfileViewModel()
    
    // ObservedObject for injected dependencies
    @ObservedObject var coordinator: HomeCoordinator
    
    // Environment for app-wide state
    @EnvironmentObject var userProfile: UserProfile
}
```

### View Hierarchy
```swift
var body: some View {
    NavigationStack {
        VStack(spacing: 16) {
            HeaderView(title: "Profile")
            
            if isLoading {
                LoadingView()
            } else {
                ContentView()
            }
        }
        .padding()
        .navigationTitle("Smart City Guide")
    }
}
```

## Async/Await Guidelines

### Function Signatures
```swift
// ✅ Preferred async/await
func fetchPOIs(for cityName: String) async throws -> [POI] {
    let response = try await apiService.getPOIs(city: cityName)
    return response.data
}

// ❌ Avoid completion handlers when possible
func fetchPOIs(for cityName: String, completion: @escaping (Result<[POI], Error>) -> Void) {
    // Old style - avoid in new code
}
```

### Error Handling
```swift
func loadRouteData() async {
    do {
        let route = try await routeService.generateRoute()
        await MainActor.run {
            self.currentRoute = route
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
```

## Memory Management

### Weak References
```swift
class RouteCoordinator {
    weak var delegate: RouteCoordinatorDelegate?
    
    private var completion: (() -> Void)?
    
    func setupLocationUpdates() {
        locationManager.onUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
    }
}
```

### Capture Lists
```swift
// ✅ Use weak self to prevent retain cycles
Task { [weak self] in
    await self?.performBackgroundTask()
}

// ✅ Use unowned when self is guaranteed to exist
someService.performTask { [unowned self] result in
    self.handleResult(result)
}
```

## Documentation Comments

Use Swift DocC format for public APIs:

```swift
/// Generates an optimized walking route between multiple points of interest.
/// 
/// This method uses the Traveling Salesman Problem (TSP) algorithm to find
/// the most efficient route visiting all provided POIs.
///
/// - Parameters:
///   - startLocation: The starting coordinate for the route
///   - pois: Array of points of interest to visit
///   - maxDistance: Maximum allowed total route distance in meters
/// - Returns: An optimized route with turn-by-turn directions
/// - Throws: `RouteError.tooManyPOIs` if more than 10 POIs are provided
func generateOptimizedRoute(
    from startLocation: CLLocationCoordinate2D,
    visiting pois: [POI],
    maxDistance: Double = 5000
) async throws -> GeneratedRoute {
    // Implementation
}
```

## String Handling

### String Literals
```swift
// ✅ Use double quotes
let welcomeMessage = "Welcome to Smart City Guide"

// ✅ Use string interpolation
let greetingMessage = "Hello \(userName), ready to explore \(cityName)?"

// ✅ Multi-line strings
let helpText = """
    Welcome to Smart City Guide!
    
    This app helps you discover amazing places in your city
    and creates optimized walking routes between them.
    """
```

### Localization
```swift
// ✅ Use String(localized:) for user-facing strings
let errorMessage = String(localized: "Unable to load route data")

// ✅ Use string keys for complex localization
let routeStatusText = String(localized: "route.status.generating", 
                           comment: "Status shown while route is being calculated")
```
