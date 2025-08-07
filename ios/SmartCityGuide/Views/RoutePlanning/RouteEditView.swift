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
    
    /// Callback when a spot is changed
    let onSpotChanged: (POI) -> Void
    
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
    @State private var showingIntroAnimation: Bool = true
    
    /// Selected POI (if any)
    @State private var selectedPOI: POI?
    
    /// Whether the view has appeared (for animation timing)
    @State private var hasAppeared: Bool = false
    
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
            
            // Instructions (with intro animation)
            if showingIntroAnimation {
                instructionsView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Swipe card stack
            SwipeCardStackView(
                initialCards: availableCards,
                onCardAction: handleCardAction,
                onStackEmpty: handleStackEmpty
            )
            .frame(maxHeight: 480)
            .opacity(showingIntroAnimation ? 0.7 : 1.0)
            .scaleEffect(showingIntroAnimation ? 0.95 : 1.0)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .onAppear {
            startIntroAnimation()
        }
    }
    
    // MARK: - Original Spot Card
    
    private var originalSpotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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
                
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: editableSpot.originalWaypoint.category.icon)
                        .font(.caption)
                    Text(editableSpot.originalWaypoint.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(editableSpot.originalWaypoint.category.color.opacity(0.1))
                )
                .foregroundColor(editableSpot.originalWaypoint.category.color)
            }
            
            if !editableSpot.originalWaypoint.address.isEmpty {
                Text(editableSpot.originalWaypoint.address)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
    
    // MARK: - Animation & Interaction
    
    private func startIntroAnimation() {
        // Small delay before starting intro
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Hide instructions after demonstration
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showingIntroAnimation = false
                }
            }
        }
    }
    
    private func loadAlternatives() {
        isLoadingCards = true
        
        Task {
            let (pois, enrichedData) = await editService.loadEnrichedAlternatives(
                for: editableSpot.originalWaypoint,
                avoiding: originalRoute,
                cityName: cityName
            )
            
            await MainActor.run {
                if pois.isEmpty {
                    availableCards = []
                } else {
                    availableCards = editService.createSwipeCards(
                        from: pois,
                        enrichedData: enrichedData,
                        originalWaypoint: editableSpot.originalWaypoint
                    )
                }
                
                isLoadingCards = false
            }
        }
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
                if editService.newRoute != nil {
                    // Success - notify parent
                    onSpotChanged(poi)
                } else if editService.errorMessage != nil {
                    // Error - show error overlay
                    // Error is already bound to the service
                } else {
                    // TODO: Handle case where route service integration is needed
                    // For now, just proceed with the POI change
                    onSpotChanged(poi)
                }
            }
        }
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
                onSpotChanged: { poi in
                    print("Selected POI: \(poi.name)")
                    showingEdit = false
                },
                onCancel: {
                    print("Cancelled")
                    showingEdit = false
                }
            )
        }
}