//
//  RouteEditView.swift
//  SmartCityGuide
//
//  Route Edit Feature - Main Tinder-Style Edit Interface
//

import SwiftUI
import CoreLocation

/// Main interface for editing route spots with Tinder-style swipe cards
struct RouteEditView: View {
    
    // MARK: - Properties
    
    /// The original route being edited
    let originalRoute: GeneratedRoute
    
    /// The specific spot being edited
    let editableSpot: EditableRouteSpot
    
    /// City name for POI cache lookups
    let cityName: String
    
    /// All discovered POIs for the city (unfiltered)
    let allDiscoveredPOIs: [POI]
    
    /// Callback when a spot is changed
    let onSpotChanged: (POI, GeneratedRoute?) -> Void
    
    /// Callback when editing is cancelled
    let onCancel: () -> Void
    
    // MARK: - State
    
    /// Route edit service instance
    @StateObject private var editService = RouteEditService()
    
    /// Available swipe cards
    @State private var availableCards: [SwipeCard] = []
    
    /// Whether cards are currently loading
    @State private var isLoadingCards: Bool = true
    
    /// Whether intro animation is showing
    @State private var showingIntroAnimation: Bool = false
    
    /// Selected POI (if any)
    @State private var selectedPOI: POI?
    
    /// Whether the view has appeared (for animation timing)
    @State private var hasAppeared: Bool = false
    
    /// Current top card for manual actions
    @State private var currentTopCard: SwipeCard?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                // Main content
                if isLoadingCards {
                    loadingView
                } else if availableCards.isEmpty {
                    noAlternativesView
                } else {
                    mainContentView
                }
                
                // Service error overlay
                if let errorMessage = editService.errorMessage {
                    errorOverlay(message: errorMessage)
                }
            }
            .navigationTitle("Stopp bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    infoButton
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                loadAlternatives()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(spacing: 20) {
            // Original spot info
            originalSpotCard
            
            // Main content area
            ZStack {
                // Swipe card stack
                SwipeCardStackView(
                    initialCards: availableCards,
                    onCardAction: handleCardAction,
                    onStackEmpty: handleStackEmpty,
                    onTopCardChanged: { card in
                        currentTopCard = card
                    }
                )
                .frame(maxHeight: 420)
            }
            
            // Manual action buttons
            if !availableCards.isEmpty {
                manualActionButtons
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        // Intro animation removed - swipe pattern is well known
    }
    
    // MARK: - Original Spot Card
    
    private var originalSpotCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktueller Stopp")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(editableSpot.originalWaypoint.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 12) {
            Text("Finde besseren Stopp")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Swipe die Karten, um Alternativen zu entdecken")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Swipe gesture hints
            HStack(spacing: 24) {
                swipeHint(
                    direction: .left,
                    text: "Nehmen",
                    color: .green
                )
                
                swipeHint(
                    direction: .right,
                    text: "Überspringen",
                    color: .red
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func swipeHint(direction: SwipeDirection, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: direction.indicatorIcon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(direction == .left ? "Nach links" : "Nach rechts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            VStack(spacing: 8) {
                Text("Lade Alternativen...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Suche nach besseren Stopps in der Nähe")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - No Alternatives View
    
    private var noAlternativesView: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "location.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            
            // Content
            VStack(spacing: 8) {
                Text("Keine Alternativen gefunden")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Für diesen Stopp sind leider keine passenden Alternativen in der Nähe verfügbar.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action button
            Button("Verstanden") {
                onCancel()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Fehler")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Erneut versuchen") {
                editService.reset()
                loadAlternatives()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Abbrechen") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 20)
        )
        .padding(.horizontal, 40)
    }
    
    // MARK: - Toolbar Items
    
    private var cancelButton: some View {
        Button("Abbrechen") {
            onCancel()
        }
        .foregroundColor(.secondary)
    }
    
    private var infoButton: some View {
        Button {
            // Show info about route editing
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Manual Action Buttons
    
    private var manualActionButtons: some View {
        HStack(spacing: 24) {
            // Decline/Skip button
            Button(action: {
                // Handle manual reject (same as right swipe)
                handleManualReject()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    Text("Überspringen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Accept button
            Button(action: {
                // Handle manual accept (same as left swipe)
                handleManualAccept()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("Nehmen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Animation & Interaction
    

    
    private func loadAlternatives() {
        isLoadingCards = true
        
        Task {
            // Use ALL discovered POIs instead of filtered subset from RouteEditService
            let allAvailablePOIs = findAllAvailablePOIs()
            
            // Enrich with Wikipedia data (background task)
            let enrichedData = await editService.enrichAlternativesWithWikipedia(allAvailablePOIs, cityName: cityName)
            
            await MainActor.run {
                if allAvailablePOIs.isEmpty {
                    availableCards = []
                } else {
                    availableCards = editService.createSwipeCards(
                        from: allAvailablePOIs,
                        enrichedData: enrichedData,
                        originalWaypoint: editableSpot.originalWaypoint,
                        replacedPOIs: editableSpot.replacedPOIs
                    )
                }
                
                isLoadingCards = false
            }
        }
    }
    
    /// Find all available POIs (same logic as RouteBuilderView.findAlternativePOIsWithHistory)
    private func findAllAvailablePOIs() -> [POI] {
        // Get previously replaced POIs for this position
        let replacedPOIs = editableSpot.replacedPOIs
        
        // Combine all discovered POIs with replaced POIs
        let allPossiblePOIs = allDiscoveredPOIs + replacedPOIs
        
        return allPossiblePOIs.filter { poi in
            // Only exclude POIs already in route - NO distance restriction
            return !isAlreadyInRoute(poi)
        }
        .sorted { poi1, poi2 in
            // Prioritize previously replaced POIs (show them first)
            let poi1WasReplaced = replacedPOIs.contains { $0.id == poi1.id }
            let poi2WasReplaced = replacedPOIs.contains { $0.id == poi2.id }
            
            if poi1WasReplaced && !poi2WasReplaced {
                return true
            } else if !poi1WasReplaced && poi2WasReplaced {
                return false
            }
            
            // Then sort by category match
            let categoryMatch1 = poi1.category == editableSpot.originalWaypoint.category
            let categoryMatch2 = poi2.category == editableSpot.originalWaypoint.category
            
            if categoryMatch1 && !categoryMatch2 {
                return true
            } else if !categoryMatch1 && categoryMatch2 {
                return false
            }
            
            // Finally sort by distance
            let distance1 = calculateDistance(from: poi1.coordinate, to: editableSpot.originalWaypoint.coordinate)
            let distance2 = calculateDistance(from: poi2.coordinate, to: editableSpot.originalWaypoint.coordinate)
            return distance1 < distance2
        }
        .prefix(50) // Increased limit for maximum alternatives
        .map { $0 }
    }
    
    /// Check if POI is already in the current route
    private func isAlreadyInRoute(_ poi: POI) -> Bool {
        return originalRoute.waypoints.contains { waypoint in
            poi.name.lowercased() == waypoint.name.lowercased() &&
            calculateDistance(from: poi.coordinate, to: waypoint.coordinate) < 50 // 50m tolerance
        }
    }
    
    /// Calculate distance between two coordinates
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    private func handleCardAction(_ action: SwipeAction) {
        switch action {
        case .accept(let poi):
            selectedPOI = poi
            // Generate new route in background
            generateNewRoute(with: poi)
            
        case .reject, .skip:
            // Just continue to next card
            break
        }
    }
    
    private func handleStackEmpty() {
        // User went through all alternatives without selecting
        onCancel()
    }
    
    private func generateNewRoute(with poi: POI) {
        Task {
            await editService.generateUpdatedRoute(
                replacing: editableSpot.waypointIndex,
                with: poi,
                in: originalRoute
            )
            
            await MainActor.run {
                if let newRoute = editService.newRoute {
                    // Success - notify parent with the new route
                    onSpotChanged(poi, newRoute)
                } else if editService.errorMessage != nil {
                    // Error - show error overlay
                    // Error is already bound to the service
                } else {
                    // TODO: Handle case where route service integration is needed
                    // For now, just proceed with the POI change
                    onSpotChanged(poi, nil)
                }
            }
        }
    }
    
    // MARK: - Manual Action Handlers
    
    private func handleManualAccept() {
        // Get current top card and accept it
        guard let topCard = currentTopCard else { return }
        
        let action = SwipeAction.accept(topCard.poi)
        handleCardAction(action)
    }
    
    private func handleManualReject() {
        // Get current top card and reject it
        guard let topCard = currentTopCard else { return }
        
        let action = SwipeAction.reject(topCard.poi)
        handleCardAction(action)
    }
}

// MARK: - Preview

#Preview("Route Edit View") {
    @Previewable @State var showingEdit = true
    
    let sampleRoute = GeneratedRoute(
        waypoints: [
            RoutePoint(
                name: "Hauptmarkt",
                coordinate: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767),
                address: "Hauptmarkt, Nürnberg",
                category: .attraction
            ),
            RoutePoint(
                name: "Nürnberger Burg",
                coordinate: CLLocationCoordinate2D(latitude: 49.4577, longitude: 11.0751),
                address: "Burg 17, 90403 Nürnberg",
                category: .attraction
            ),
            RoutePoint(
                name: "Germanisches Nationalmuseum",
                coordinate: CLLocationCoordinate2D(latitude: 49.4481, longitude: 11.0661),
                address: "Kartäusergasse 1, 90402 Nürnberg",
                category: .museum
            )
        ],
        routes: [],
        totalDistance: 2500.0,
        totalTravelTime: 45.0,
        totalVisitTime: 135.0,
        totalExperienceTime: 180.0
    )
    
    let editableSpot = EditableRouteSpot(
        originalWaypoint: sampleRoute.waypoints[1],
        waypointIndex: 1,
        alternativePOIs: []
    )
    
    Color.clear
        .sheet(isPresented: $showingEdit) {
            RouteEditView(
                originalRoute: sampleRoute,
                editableSpot: editableSpot,
                cityName: "Nürnberg",
                allDiscoveredPOIs: [], // Empty for preview
                onSpotChanged: { poi, newRoute in
                    print("Selected POI: \(poi.name)")
                    if let route = newRoute {
                        print("New route has \(route.waypoints.count) waypoints")
                    }
                    showingEdit = false
                },
                onCancel: {
                    print("Cancelled")
                    showingEdit = false
                }
            )
        }
}