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
    
    // SERVICES
    @StateObject private var geoapifyService = GeoapifyAPIService.shared
    @StateObject private var wikipediaService = WikipediaService.shared
    @StateObject private var poiSelection = ManualPOISelection()
    
    // STATE
    @State private var currentPhase: ManualPlanningPhase = .loading
    @State private var discoveredPOIs: [POI] = []
    @State private var enrichedPOIs: [String: WikipediaEnrichedPOI] = [:]
    @State private var showingPOISelection = false
    @State private var showingRouteBuilder = false
    @State private var generatedRoute: GeneratedRoute?
    @State private var enrichmentProgress: Double = 0.0
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                switch currentPhase {
                case .loading:
                    loadingPOIsView
                case .enriching:
                    enrichingPOIsView
                case .ready, .selecting:
                    // Direkt den Card-Stack anzeigen
                    poiSelectionView
                case .generating:
                    generatingRouteView
                case .completed:
                    routeCompletedView
                }
            }
            .navigationTitle("POI Auswahl")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Info opens overview sheet from within the stack
                        Button {
                            showingOverviewSheet = true
                        } label: { Image(systemName: "info.circle") }
                        selectionCounterView
                    }
                }
            }
            .sheet(isPresented: $showingOverviewSheet) { overviewSheet }
            .onAppear {
                startPOIDiscovery()
            }
            .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
                Button("Erneut versuchen") {
                    errorMessage = nil
                    currentPhase = .loading
                    startPOIDiscovery()
                }
                Button("Abbrechen") {
                    dismiss()
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Loading POIs View
    
    private var loadingPOIsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Entdecke POIs in \(config.startingCity)...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Ich suche nach interessanten Orten für deine Tour")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Enriching POIs View
    
    private var enrichingPOIsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView(value: enrichmentProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 200)
                
                Text("Lade Wikipedia-Infos...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Bereite interessante Details zu den Orten vor")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(enrichmentProgress * 100))% abgeschlossen")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Selection Counter (toolbar)
    private var selectionCounterView: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text("\(poiSelection.selectedPOIs.count)").fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(.systemGray6)))
    }
    
    // MARK: - POI Selection View
    
    private var poiSelectionView: some View {
        POISelectionStackView(
            availablePOIs: .constant(discoveredPOIs),
            selection: poiSelection,
            enrichedPOIs: enrichedPOIs,
            onSelectionComplete: {
                currentPhase = .ready
            }
        )
    }
    
    // MARK: - Generating Route View
    
    private var generatingRouteView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Erstelle deine Route...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Optimiere die Reihenfolge deiner \(poiSelection.selectedPOIs.count) ausgewählten POIs")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Route Completed View
    
    private var routeCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Route erstellt!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Deine manuelle Route ist bereit")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                if let route = generatedRoute {
                    onRouteGenerated(route)
                    dismiss()
                }
            }) {
                Text("Route anzeigen")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }

    // MARK: - Overview Sheet
    @State private var showingOverviewSheet = false
    private var overviewSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(discoveredPOIs.count) interessante Orte in \(config.startingCity)")
                        .font(.headline)
                        .padding(.top, 8)
                    POICategoriesOverview(pois: discoveredPOIs)
                    if poiSelection.hasSelections {
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
    
    // MARK: - Business Logic
    
    private func startPOIDiscovery() {
        currentPhase = .loading
        Task {
            await discoverPOIs()
        }
    }
    
    private func discoverPOIs() async {
        do {
            // Use starting coordinates if available, otherwise get from city name
            let coordinates: CLLocationCoordinate2D
            if let startCoords = config.startingCoordinates {
                print("🌍 Manual Route: Using provided coordinates: \(startCoords.latitude), \(startCoords.longitude)")
                coordinates = startCoords
            } else {
                print("🌍 Manual Route: No coordinates provided, using fallback for city: \(config.startingCity)")
                // For now, use GeoapifyAPIService to geocode the city
                let pois = try await geoapifyService.fetchPOIs(
                    for: config.startingCity,
                    categories: PlaceCategory.geoapifyEssentialCategories
                )
                
                await MainActor.run {
                    self.discoveredPOIs = pois
                    if pois.isEmpty {
                        self.errorMessage = "Keine POIs in \(config.startingCity) gefunden. Versuche eine andere Stadt."
                    } else {
                        self.currentPhase = .enriching
                        Task {
                            await enrichPOIs()
                        }
                    }
                }
                return
            }
            
            // Discover POIs using GeoapifyAPIService
            let pois = try await geoapifyService.fetchPOIs(
                at: coordinates,
                cityName: config.startingCity,
                categories: PlaceCategory.geoapifyEssentialCategories
            )
            
            await MainActor.run {
                self.discoveredPOIs = pois
                if pois.isEmpty {
                    self.errorMessage = "Keine POIs in \(config.startingCity) gefunden. Versuche eine andere Stadt."
                } else {
                    self.currentPhase = .enriching
                    Task {
                        await enrichPOIs()
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der POIs: \(error.localizedDescription)"
            }
        }
    }
    
    private func enrichPOIs() async {
        let totalPOIs = discoveredPOIs.count
        guard totalPOIs > 0 else {
            await MainActor.run {
                currentPhase = .ready
            }
            return
        }
        
        var enrichedData: [String: WikipediaEnrichedPOI] = [:]
        
        for (index, poi) in discoveredPOIs.enumerated() {
            do {
                let enriched = try await wikipediaService.enrichPOI(poi, cityName: config.startingCity)
                enrichedData[poi.id] = enriched
            } catch {
                // Continue with other POIs even if one fails
                print("Failed to enrich POI \(poi.name): \(error)")
            }
            
            // Update progress
            let progress = Double(index + 1) / Double(totalPOIs)
            await MainActor.run {
                enrichmentProgress = progress
            }
        }
        
        await MainActor.run {
            self.enrichedPOIs = enrichedData
            self.currentPhase = .ready
        }
    }
    
    private func generateRoute() {
        // Placeholder for Phase 3 - will be implemented with ManualRouteService
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Mock route for now
            let mockRoute = GeneratedRoute(
                waypoints: [],
                routes: [],
                totalDistance: 0,
                totalTravelTime: 0,
                totalVisitTime: 0,
                totalExperienceTime: 0
            )
            generatedRoute = mockRoute
            currentPhase = .completed
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CategoryChip: View {
    let category: PlaceCategory
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Text(category.icon)
                .font(.system(size: 14))
            
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
        )
    }
}

struct SelectedPOIsPreview: View {
    let selectedPOIs: [POI]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Deine Auswahl:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedPOIs.count) POIs")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.2))
                    )
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedPOIs.prefix(5), id: \.id) { poi in
                        VStack(spacing: 4) {
                            Text(poi.category.icon)
                                .font(.system(size: 20))
                            
                            Text(poi.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    if selectedPOIs.count > 5 {
                        VStack {
                            Text("+\(selectedPOIs.count - 5)")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("mehr")
                                .font(.caption2)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.2))
                        )
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Preview
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