# Phase 4: State-Entkopplung & Clean Architecture
*Created: 17-08-2025*

## 🎯 Ziele
- **HomeCoordinator** als zentraler State Manager für Route/Sheets/Quick-Planning
- **Dependency Injection** für RouteService und optionale History-Injection  
- **Clean Architecture** mit MVVM-Prinzipien
- **Better Testability** durch entkoppelte Dependencies

## 📊 Current State Analysis

### ❌ Current Problems
- **ContentView** ist überladen mit State Management
- **Direct Service Dependencies** erschweren Testing
- **Mixed Responsibilities** in ContentView (UI + Business Logic)
- **Tight Coupling** zwischen Views und Services
- **Hard to Test** wegen direkter Service-Referenzen

### ✅ Target Architecture
- **HomeCoordinator** manages all app-level state
- **Dependency Injection** für flexibles Service Management
- **Single Responsibility** pro View/Component
- **Testable Architecture** mit Mock-Services
- **Clear Separation** zwischen UI, Business Logic und Data

## 🏗️ Implementation Plan

### Task 1: HomeCoordinator Implementation
```swift
@MainActor
class HomeCoordinator: ObservableObject {
    // MARK: - Dependencies (Injected)
    private let routeService: RouteServiceProtocol
    private let historyManager: RouteHistoryManager?
    private let cacheManager: CacheManager
    
    // MARK: - Published State
    @Published var activeRoute: GeneratedRoute?
    @Published var presentedSheet: SheetDestination?
    @Published var isGeneratingRoute = false
    @Published var errorMessage: String?
    
    // MARK: - Quick Planning State
    @Published var quickPlanningLocation: CLLocation?
    @Published var showingQuickPlanning = false
    
    // MARK: - Initialization
    init(
        routeService: RouteServiceProtocol = RouteService.shared,
        historyManager: RouteHistoryManager? = nil,
        cacheManager: CacheManager = CacheManager.shared
    ) {
        self.routeService = routeService
        self.historyManager = historyManager
        self.cacheManager = cacheManager
    }
    
    // MARK: - Route Management
    func generateRoute(/* parameters */) async
    func endActiveRoute()
    func showRouteSheet(mode: RoutePlanningMode?)
    
    // MARK: - Sheet Management  
    func presentSheet(_ destination: SheetDestination)
    func dismissSheet()
}
```

### Task 2: Service Protocols for DI
```swift
protocol RouteServiceProtocol {
    var isGenerating: Bool { get }
    var errorMessage: String? { get }
    var generatedRoute: GeneratedRoute? { get }
    
    func generateRoute(/* parameters */) async
    func generateRoute(fromCurrentLocation location: CLLocation, /* parameters */) async
}

protocol RouteHistoryManagerProtocol {
    func saveRoute(_ route: GeneratedRoute, routeLength: RouteLength, endpointOption: EndpointOption)
    func getHistory() -> [RouteHistory]
    func clearHistory()
}
```

### Task 3: ContentView Refactoring
```swift
struct ContentView: View {
    @StateObject private var coordinator = HomeCoordinator()
    @StateObject private var locationManager = LocationManagerService()
    @StateObject private var proximityService = ProximityService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                MapView(
                    activeRoute: coordinator.activeRoute,
                    onLocationUpdate: coordinator.updateLocation
                )
                
                // UI Overlays
                VStack {
                    Spacer()
                    ActionButtonsView(coordinator: coordinator)
                }
            }
        }
        .sheet(item: $coordinator.presentedSheet) { destination in
            SheetContentView(destination: destination, coordinator: coordinator)
        }
        .onAppear {
            coordinator.setupInitialState()
        }
    }
}
```

### Task 4: Sheet Content Coordination
```swift
struct SheetContentView: View {
    let destination: SheetDestination
    @ObservedObject var coordinator: HomeCoordinator
    
    var body: some View {
        switch destination {
        case .planning(let mode):
            RoutePlanningView(
                presetMode: mode,
                onRouteGenerated: coordinator.handleRouteGenerated,
                onDismiss: coordinator.dismissSheet
            )
        case .activeRoute:
            if let route = coordinator.activeRoute {
                ActiveRouteSheetView(
                    route: route,
                    onEnd: coordinator.endActiveRoute,
                    onAddStop: coordinator.showManualRouteEdit
                )
            }
        }
    }
}
```

### Task 5: Dependency Injection Container
```swift
class DIContainer {
    static let shared = DIContainer()
    
    // Service Instances
    lazy var routeService: RouteServiceProtocol = RouteService.shared
    lazy var historyManager: RouteHistoryManagerProtocol = RouteHistoryManager()
    lazy var cacheManager: CacheManager = CacheManager.shared
    
    // Factory Methods
    func makeHomeCoordinator() -> HomeCoordinator {
        return HomeCoordinator(
            routeService: routeService,
            historyManager: historyManager,
            cacheManager: cacheManager
        )
    }
    
    // Mock Services for Testing
    func makeTestHomeCoordinator(
        routeService: RouteServiceProtocol? = nil,
        historyManager: RouteHistoryManagerProtocol? = nil
    ) -> HomeCoordinator {
        return HomeCoordinator(
            routeService: routeService ?? MockRouteService(),
            historyManager: historyManager ?? MockHistoryManager(),
            cacheManager: cacheManager
        )
    }
}
```

## 🎯 Benefits of New Architecture

### 🧪 Better Testability
- **Mock Services** easily injected for unit tests
- **Isolated Testing** of business logic without UI
- **Predictable State** management for test scenarios

### 🔧 Maintainability  
- **Single Responsibility** per component
- **Clear Dependencies** explicitly defined
- **Loose Coupling** between layers
- **Easy Refactoring** with protected interfaces

### 📈 Scalability
- **New Features** easier to add with clear patterns
- **Service Extension** without breaking existing code
- **State Management** centralized and predictable

### 🐛 Debugging
- **Centralized State** easier to inspect
- **Clear Data Flow** from Coordinator to Views
- **Isolated Responsibilities** easier to debug

## 🔄 Migration Strategy

### Phase 1: Create Protocols & Coordinator
- Define service protocols
- Implement HomeCoordinator with current logic
- No breaking changes to existing views

### Phase 2: Inject Coordinator in ContentView
- Replace direct service usage with coordinator
- Migrate state management to coordinator
- Keep sheet logic compatible

### Phase 3: Refactor Subviews
- Update RoutePlanningView to use coordinator callbacks
- Migrate ActiveRouteSheetView to coordinator pattern
- Remove direct service dependencies from views

### Phase 4: Add DI Container
- Centralize service creation
- Enable mock services for testing
- Prepare for testing framework

## 📊 Success Metrics

### Code Quality
- **Reduced ContentView size** by 50%+ lines
- **Zero direct service dependencies** in Views  
- **100% testable business logic** in Coordinator

### Architecture
- **Clear separation** of concerns (UI/Logic/Data)
- **Predictable state flow** View ← Coordinator ← Service
- **Injectable dependencies** for all services

### Testing Readiness
- **Mock services** available for all protocols
- **Unit tests** possible for Coordinator logic
- **Integration tests** with controlled dependencies

## 🛡️ Error Handling Strategy

### Coordinator Error Management
```swift
class HomeCoordinator {
    @Published var errorState: ErrorState?
    
    enum ErrorState {
        case routeGeneration(String)
        case locationAccess(String)
        case networkConnectivity(String)
        case cacheError(String)
    }
    
    func handleError(_ error: Error, context: String) {
        // Centralized error handling with user-friendly messages
    }
}
```

### View Error Display
- **Consistent error UI** across all views
- **Contextual error messages** based on ErrorState
- **Retry mechanisms** coordinated through Coordinator

## 🔮 Future Enhancements

### Advanced State Management
- **Redux-like patterns** for complex state flows
- **State persistence** across app launches
- **Undo/Redo capabilities** for user actions

### Enhanced DI
- **Service registration** for dynamic dependencies
- **Scoped services** (singleton, transient, scoped)
- **Configuration injection** for environment-specific behavior

### Testing Framework
- **Automated UI tests** with mock coordinators
- **State transition tests** for complex flows
- **Performance tests** with controlled dependencies

## 🚨 Migration Risks & Mitigation

### Risk: Breaking Existing Functionality
**Mitigation**: Incremental migration with feature flags

### Risk: Complex State Synchronization  
**Mitigation**: Clear state ownership and unidirectional data flow

### Risk: Over-Engineering
**Mitigation**: Start simple, add complexity only when needed

### Risk: Learning Curve
**Mitigation**: Clear documentation and examples for common patterns

## 🎛️ Feature Flags for Rollout

```swift
extension FeatureFlags {
    static let homeCoordinatorEnabled: Bool = true
    static let dependencyInjectionEnabled: Bool = true
    static let coordinatorErrorHandlingEnabled: Bool = true
}
```
