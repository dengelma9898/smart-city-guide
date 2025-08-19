import SwiftUI
import CoreLocation

// MARK: - Planning Phase Enum
enum ManualPlanningPhase {
    case loading        // Discovering POIs
    case enriching      // Loading Wikipedia data
    case ready          // Ready for selection
    case selecting      // POI selection in progress
    case generating     // Generating route from selections
    case completed      // Route generated successfully
}

// MARK: - Manual Route Planning View
struct ManualRoutePlanningView: View {
    @Environment(\.dismiss) private var dismiss
    
    // CONFIG
    let config: ManualRouteConfig
    let onRouteGenerated: (GeneratedRoute) -> Void
    
    // MARK: - Coordinator (Centralized Services)
    @EnvironmentObject private var coordinator: BasicHomeCoordinator
    
    // MARK: - Services (Via Coordinator)
    private var geoapifyService: GeoapifyAPIService { coordinator.getGeoapifyService() }
    
    // MARK: - Specialized Services (Keep Local)
    @StateObject private var poiDiscoveryService = ManualRoutePOIDiscoveryService()
    @StateObject private var routeGenerationService = ManualRouteGenerationService()
    @StateObject private var poiSelection = ManualPOISelection()
    
    // STATE
    @State private var currentPhase: ManualPlanningPhase = .loading
    @State private var showingPOISelection = false
    
    // Preview Context for route completion
    struct ManualPreviewContext: Identifiable {
        let id = UUID()
        let route: GeneratedRoute
        let pois: [POI]
        let config: ManualRouteConfig
    }
    @State private var previewContext: ManualPreviewContext?
    @State private var generatedRoute: GeneratedRoute?
    @State private var forcePresentBuilder: Bool = false
    @State private var forceBuilderRoute: GeneratedRoute?
    @State private var showingOverviewSheet = false
    @State private var showingSelectionSheet = false
    @State private var showingHelpSheet = false
    
    @State private var pushBuilder: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch currentPhase {
                case .loading:
                    ManualRouteLoadingView(cityName: config.startingCity)
                case .enriching:
                    ManualRouteEnrichingView(progress: poiDiscoveryService.enrichmentProgress)
                case .ready, .selecting:
                    poiSelectionView
                case .generating:
                    ManualRouteGeneratingView(selectedPOICount: poiSelection.selectedPOIs.count)
                case .completed:
                    ManualRouteCompletedView {
                        if let route = routeGenerationService.generatedRoute {
                            previewContext = ManualPreviewContext(route: route, pois: poiDiscoveryService.discoveredPOIs, config: config)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $pushBuilder) {
                if let route = routeGenerationService.generatedRoute {
                    RouteBuilderView(
                        manualRoute: route,
                        config: config,
                        discoveredPOIs: poiDiscoveryService.discoveredPOIs,
                        onRouteGenerated: onRouteGenerated
                    )
                } else {
                    EmptyView()
                }
            }
            .navigationTitle("POI Auswahl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") { dismiss() }
                }
                
                // Generate button (UITEST: always visible; otherwise from 1 selection)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if poiSelection.canGenerateRoute || ProcessInfo.processInfo.environment["UITEST"] == "1" {
                        Button("Route erstellen") {
                            currentPhase = .generating
                            Task {
                                await routeGenerationService.generateRoute(
                                    config: config, 
                                    selectedPOIs: poiSelection.selectedPOIs, 
                                    discoveredPOIs: poiDiscoveryService.discoveredPOIs
                                )
                                if routeGenerationService.generatedRoute != nil {
                                    currentPhase = .completed
                                }
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .accessibilityIdentifier("manual.generate.route.button")
                    }
                }
                
                // Overview button (only when ready)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentPhase == .ready && !poiDiscoveryService.discoveredPOIs.isEmpty {
                        Menu {
                            Button(action: { showingOverviewSheet = true }) {
                                Label("Kategorien anzeigen", systemImage: "square.grid.2x2")
                            }
                            Button(action: { showingSelectionSheet = true }) {
                                Label("Auswahl anzeigen", systemImage: "list.bullet")
                            }
                            Button(action: { showingHelpSheet = true }) {
                                Label("Rückgängig-Hilfe", systemImage: "questionmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Optionen")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) { 
                    ManualRouteSelectionCounterView(selectedCount: poiSelection.selectedPOIs.count)
                }
            }
            .sheet(isPresented: $showingOverviewSheet) { overviewSheet }
            .sheet(isPresented: $showingSelectionSheet) { selectionSheet }
            .sheet(isPresented: $showingHelpSheet) { undoHelpSheet }
            .fullScreenCover(item: $previewContext) { ctx in
                RouteBuilderView(
                    manualRoute: ctx.route,
                    config: ctx.config,
                    discoveredPOIs: ctx.pois,
                    onRouteGenerated: onRouteGenerated
                )
            }
            .onAppear {
                Task {
                    await poiDiscoveryService.discoverPOIs(config: config)
                    currentPhase = .enriching
                    
                    // Wait for enrichment to complete
                    while poiDiscoveryService.enrichmentProgress < 1.0 && poiDiscoveryService.errorMessage == nil {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    currentPhase = .ready
                }
                
                // UITEST autopilot: select first few POIs and trigger generation automatically
                if ProcessInfo.processInfo.arguments.contains("-UITEST_AUTOPILOT_MANUAL") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Step through 3 accepts (if available), then tap generate
                        let picks = min(3, poiDiscoveryService.discoveredPOIs.count)
                        for i in 0..<picks {
                            if i < poiDiscoveryService.discoveredPOIs.count {
                                poiSelection.selectPOI(poiDiscoveryService.discoveredPOIs[i])
                            }
                        }
                        if picks > 0 {
                            currentPhase = .generating
                            Task {
                                await routeGenerationService.generateRoute(
                                    config: config, 
                                    selectedPOIs: poiSelection.selectedPOIs, 
                                    discoveredPOIs: poiDiscoveryService.discoveredPOIs
                                )
                                if routeGenerationService.generatedRoute != nil {
                                    currentPhase = .completed
                                }
                            }
                        }
                    }
                }
            }
            .alert("Fehler", isPresented: .constant(poiDiscoveryService.errorMessage != nil)) {
                Button("Erneut versuchen") {
                    poiDiscoveryService.clearData()
                    currentPhase = .loading
                    Task {
                        await poiDiscoveryService.discoverPOIs(config: config)
                        currentPhase = .enriching
                        while poiDiscoveryService.enrichmentProgress < 1.0 && poiDiscoveryService.errorMessage == nil {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                        }
                        currentPhase = .ready
                    }
                }
                Button("Abbrechen") {
                    dismiss()
                }
            } message: {
                if let error = poiDiscoveryService.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - POI Selection View
    private var poiSelectionView: some View {
        POISelectionStackView(
            availablePOIs: .constant(poiDiscoveryService.discoveredPOIs),
            selection: poiSelection,
            enrichedPOIs: poiDiscoveryService.enrichedPOIs,
            onSelectionComplete: {
                currentPhase = .ready
            }
        )
    }

    // MARK: - Overview Sheet
    private var overviewSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    POICategoriesOverview(pois: poiDiscoveryService.discoveredPOIs)
                    
                    if !poiSelection.selectedPOIs.isEmpty {
                        Divider()
                        SelectedPOIsPreview(selectedPOIs: poiSelection.selectedPOIs)
                    }
                }
                .padding()
            }
            .navigationTitle("Übersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Fertig") { showingOverviewSheet = false } }
            }
        }
    }

    // MARK: - Selection Sheet
    private var selectionSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Aktuell ausgewählt (\(poiSelection.selectedPOIs.count))")) {
                    if poiSelection.selectedPOIs.isEmpty {
                        Text("Noch keine POIs ausgewählt")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(poiSelection.selectedPOIs, id: \.id) { poi in
                            VStack(alignment: .leading) {
                                Text(poi.name).font(.body).fontWeight(.medium)
                                Text(poi.fullAddress).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Deine Auswahl")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Fertig") { showingSelectionSheet = false } } }
        }
    }

    // MARK: - Undo Help Sheet
    private var undoHelpSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("So funktioniert \"Rückgängig\"")
                        .font(.headline)
                    Text("- Die letzte Aktion (Auswahl oder Ablehnung) wird zurückgenommen.")
                    Text("- Der betroffene Ort wird direkt wieder vor die aktuelle Karte einsortiert – du kannst ihn sofort neu bewerten.")
                    Text("- Der Auswahlzähler aktualisiert sich automatisch.")
                    Text("- Du kannst mehrere Aktionen nacheinander rückgängig machen, solange Verlauf vorhanden ist.")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Rückgängig – Hilfe")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Fertig") { showingHelpSheet = false } } }
        }
    }
}

// MARK: - Helper Views

struct POICategoriesOverview: View {
    let pois: [POI]
    
    private var categoryCount: [PlaceCategory: Int] {
        Dictionary(grouping: pois, by: \.category)
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entdeckte Kategorien:")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    if let count = categoryCount[category], count > 0 {
                        CategoryChip(category: category, count: count)
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let category: PlaceCategory
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(category.icon)
                .font(.caption)
            Text("\(category.displayName) (\(count))")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct SelectedPOIsPreview: View {
    let selectedPOIs: [POI]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deine Auswahl (\(selectedPOIs.count)):")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(selectedPOIs.prefix(5), id: \.id) { poi in
                HStack {
                    Text(poi.category.icon)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(poi.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(poi.fullAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            
            if selectedPOIs.count > 5 {
                Text("... und \(selectedPOIs.count - 5) weitere")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
        }
    }
}

#Preview {
    ManualRoutePlanningView(
        config: ManualRouteConfig(
            startingCity: "Berlin",
            startingCoordinates: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            usingCurrentLocation: false,
            endpointOption: .roundtrip,
            customEndpoint: "",
            customEndpointCoordinates: nil
        ),
        onRouteGenerated: { _ in }
    )
}