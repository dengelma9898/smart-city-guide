//
//  UnifiedSwipeView.swift
//  SmartCityGuide
//
//  Created on 2025-08-22
//  Unified Tinder-Style Swipe Interface for POI Selection
//

import SwiftUI
import CoreLocation

/// Unified SwiftUI component for POI selection across all flows
struct UnifiedSwipeView: View {
    
    // MARK: - Configuration
    
    /// Flow configuration defining behavior
    let configuration: SwipeFlowConfiguration
    
    /// Available POIs for selection
    let availablePOIs: [POI]
    
    /// Wikipedia enrichment data
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    
    /// Manual POI selection state (for manual/add flows)
    @ObservedObject var selection: ManualPOISelection
    
    // MARK: - Callbacks
    
    /// Called when selection is completed (manual/add flows)
    let onSelectionComplete: () -> Void
    
    /// Called when POI is selected (edit flow)
    let onPOISelected: ((POI) -> Void)?
    
    /// Called when view should be dismissed
    let onDismiss: () -> Void
    
    // MARK: - State
    
    @StateObject private var swipeService = UnifiedSwipeService()
    @State private var showingConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    /// Initialize unified swipe view
    /// - Parameters:
    ///   - configuration: Flow configuration
    ///   - availablePOIs: POIs available for selection
    ///   - enrichedPOIs: Wikipedia enrichment data
    ///   - selection: Manual POI selection state
    ///   - onSelectionComplete: Completion callback for manual/add flows
    ///   - onPOISelected: POI selection callback for edit flow
    ///   - onDismiss: Dismiss callback
    init(
        configuration: SwipeFlowConfiguration,
        availablePOIs: [POI],
        enrichedPOIs: [String: WikipediaEnrichedPOI] = [:],
        selection: ManualPOISelection,
        onSelectionComplete: @escaping () -> Void = {},
        onPOISelected: ((POI) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.availablePOIs = availablePOIs
        self.enrichedPOIs = enrichedPOIs
        self.selection = selection
        self.onSelectionComplete = onSelectionComplete
        self.onPOISelected = onPOISelected
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Main content area - leaves space for bottom buttons
            VStack(spacing: 0) {
                // Top progress/counter area
                if configuration.showSelectionCounter {
                    topProgressArea
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                }
                
                // Card stack area - takes available space minus button area
                if swipeService.hasCurrentCard() {
                    cardStackArea
                        .frame(maxHeight: configuration.isEditFlow ? 300 : 380)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                } else {
                    // Auto-recycle for edit flow, otherwise show empty state
                    if configuration.isEditFlow && swipeService.canRecycleCards() {
                        emptyStackViewWithRecycle
                    } else {
                        emptyStackView
                    }
                }
                
                // Fill remaining space
                Spacer()
            }
            
            // Bottom action buttons - fixed to bottom of screen
            VStack {
                Spacer()
                
                if swipeService.hasCurrentCard() || (configuration.isManualFlow && !swipeService.hasCurrentCard()) {
                    bottomActionArea
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34) // Safe area bottom padding
                        .background(
                            Rectangle()
                                .fill(Color(.systemBackground))
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
        }
        .onAppear {
            setupSwipeService()
        }
        .overlay(alignment: .bottom) {
            // Toast overlay
            if swipeService.showToast, let message = swipeService.toastMessage {
                toastView(message: message)
                    .padding(.bottom, 100)
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
    
    // MARK: - Top Progress Area
    
    private var topProgressArea: some View {
        VStack(spacing: 12) {
            // Progress indicator
            let progress = swipeService.getProgress()
            
            HStack {
                Text("POI-Auswahl")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(progress.current + 1) / \(progress.total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
            }
            
            // Selection counter
            if configuration.showSelectionCounter {
                let selectionCount = swipeService.getSelectionCount(selection: selection)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("\(selectionCount) POIs ausgewählt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Card Stack Area
    
    private var cardStackArea: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(swipeService.getVisibleCards().enumerated()), id: \.element.id) { index, card in
                    SpotSwipeCardView(
                        card: .constant(card),
                        onSwipe: { action in
                            handleSwipeAction(action)
                        }
                    )
                    .overlay(alignment: .topLeading) {
                        // Wikipedia quality badge
                        if let enriched = enrichedPOIs[card.poi.id], 
                           let desc = enriched.shortDescription, 
                           !desc.isEmpty {
                            wikipediaQualityBadge
                        }
                    }
                    .zIndex(Double(swipeService.getVisibleCards().count - index))
                    .scaleEffect(cardScale(for: index))
                    .offset(y: cardOffset(for: index))
                    .opacity(cardOpacity(for: index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty Stack View
    
    private var emptyStackView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Alle POIs durchgesehen!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if configuration.isManualFlow && swipeService.canRecycleCards() {
                    Text("Du kannst übersprungene POIs erneut durchgehen oder deine Auswahl bestätigen.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if configuration.isManualFlow {
                    Text("Bestätige deine Auswahl oder starte von vorn.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Recycle option for manual flows
            if configuration.isManualFlow && swipeService.canRecycleCards() {
                Button(action: {
                    swipeService.recycleRejectedCards()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Übersprungene POIs erneut durchgehen")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty Stack View with Auto-Recycle
    
    private var emptyStackViewWithRecycle: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Alternativen werden neu gemischt...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Übersprungene POIs werden erneut angezeigt.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            // Auto-recycle for edit flow after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if configuration.isEditFlow && swipeService.canRecycleCards() {
                    swipeService.recycleRejectedCards()
                }
            }
        }
    }
    
    // MARK: - Bottom Action Area
    
    private var bottomActionArea: some View {
        VStack(spacing: 16) {
            // Manual action buttons (only when current card available)
            if swipeService.hasCurrentCard() {
                manualActionButtons
            }
            
            // Flow-specific buttons
            if configuration.showConfirmButton && selection.hasSelections {
                confirmButton
            } else if !swipeService.hasCurrentCard() && configuration.isManualFlow {
                finalActionButtons
            }
        }
    }
    
    // MARK: - Manual Action Buttons
    
    private var manualActionButtons: some View {
        HStack(spacing: 32) {
            // Reject/Skip Button (Red)
            Button(action: {
                triggerManualReject()
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
            .accessibilityIdentifier("unified.swipe.reject")
            
            Spacer()
            
            // Accept Button (Green)
            Button(action: {
                triggerManualAccept()
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
            .accessibilityIdentifier("unified.swipe.accept")
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button(action: {
            if configuration.autoConfirmSelection {
                onSelectionComplete()
            } else {
                showingConfirmation = true
            }
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                
                let count = selection.selectedPOIs.count
                Text("\(count) POI\(count == 1 ? "" : "s") bestätigen")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green)
            )
        }
        .accessibilityIdentifier("unified.swipe.confirm")
        .confirmationDialog(
            "POI-Auswahl bestätigen?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Bestätigen") {
                onSelectionComplete()
            }
            
            Button("Abbrechen", role: .cancel) { }
        } message: {
            let count = selection.selectedPOIs.count
            Text("Du hast \(count) POI\(count == 1 ? "" : "s") ausgewählt. Möchtest du fortfahren?")
        }
    }
    
    // MARK: - Final Action Buttons
    
    private var finalActionButtons: some View {
        VStack(spacing: 12) {
            // Confirm selection (if any)
            if selection.hasSelections {
                confirmButton
            }
            
            // Reset option
            Button(action: {
                swipeService.resetToBeginning()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Von vorne beginnen")
                }
                .foregroundColor(.blue)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 1)
                )
            }
            .accessibilityIdentifier("unified.swipe.reset")
        }
    }
    
    // MARK: - Wikipedia Quality Badge
    
    private var wikipediaQualityBadge: some View {
        Text("📖 Wiki")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color(.systemBackground).opacity(0.8)))
            .foregroundColor(.primary)
            .padding(.leading, 12)
            .padding(.top, 12)
    }
    
    // MARK: - Toast View
    
    private func toastView(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.8))
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: swipeService.showToast)
    }
    
    // MARK: - Card Stacking Effects
    
    private func cardScale(for index: Int) -> CGFloat {
        let scaleReduction = CGFloat(index) * 0.05
        return 1.0 - scaleReduction
    }
    
    private func cardOffset(for index: Int) -> CGFloat {
        return CGFloat(index) * 8
    }
    
    private func cardOpacity(for index: Int) -> Double {
        return 1.0 - (Double(index) * 0.1)
    }
    
    // MARK: - Action Handling
    
    private func handleSwipeAction(_ action: SwipeAction) {
        swipeService.handleCardAction(action, selection: selection)
        
        // Handle edit flow auto-confirmation
        if configuration.autoConfirmSelection {
            switch action {
            case .accept(let poi):
                // For edit flow, call POI selection callback and dismiss immediately
                onPOISelected?(poi)
                
                // Brief delay for animation, then dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + configuration.autoCloseDelay) {
                    onDismiss()
                }
            default:
                break
            }
        }
    }
    
    private func triggerManualAccept() {
        guard let currentPOI = swipeService.getCurrentPOI() else { return }
        
        // Trigger card exit animation via notification
        NotificationCenter.default.post(
            name: .manualCardExit,
            object: nil,
            userInfo: [
                "cardId": swipeService.getVisibleCards().first?.id.uuidString ?? "",
                "direction": "left"
            ]
        )
        
        // Handle the action after animation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(name: .manualCardRemoval, object: nil)
            handleSwipeAction(.accept(currentPOI))
        }
    }
    
    private func triggerManualReject() {
        guard let currentPOI = swipeService.getCurrentPOI() else { return }
        
        // Trigger card exit animation via notification
        NotificationCenter.default.post(
            name: .manualCardExit,
            object: nil,
            userInfo: [
                "cardId": swipeService.getVisibleCards().first?.id.uuidString ?? "",
                "direction": "right"
            ]
        )
        
        // Handle the action after animation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(name: .manualCardRemoval, object: nil)
            handleSwipeAction(.reject(currentPOI))
        }
    }
    
    // MARK: - Setup
    
    private func setupSwipeService() {
        swipeService.configure(
            with: configuration,
            availablePOIs: availablePOIs,
            enrichedPOIs: enrichedPOIs
        )
    }
}

// MARK: - Preview

#Preview("Manual Flow") {
    @Previewable @State var mockSelection = ManualPOISelection()
    
    let samplePOIs = [
        POI(
            id: "1",
            name: "Nürnberger Burg",
            latitude: 49.4577,
            longitude: 11.0751,
            category: .attraction,
            description: "Eine mittelalterliche Burg auf einem Sandsteinfelsen.",
            tags: [:],
            sourceType: "preview",
            sourceId: 1,
            address: POIAddress(
                street: "Burg",
                houseNumber: "17",
                city: "Nürnberg",
                postcode: "90403",
                country: "Deutschland"
            ),
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        ),
        POI(
            id: "2",
            name: "Germanisches Nationalmuseum",
            latitude: 49.4481,
            longitude: 11.0661,
            category: .museum,
            description: "Das größte kulturhistorische Museum Deutschlands.",
            tags: [:],
            sourceType: "preview",
            sourceId: 2,
            address: POIAddress(
                street: "Kartäusergasse",
                houseNumber: "1",
                city: "Nürnberg",
                postcode: "90402",
                country: "Deutschland"
            ),
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
    ]
    
    UnifiedSwipeView(
        configuration: .manual,
        availablePOIs: samplePOIs,
        enrichedPOIs: [:],
        selection: mockSelection,
        onSelectionComplete: {
            print("Selection completed with \(mockSelection.selectedPOIs.count) POIs")
        },
        onDismiss: {
            print("View dismissed")
        }
    )
}

#Preview("Edit Flow") {
    @Previewable @State var mockSelection = ManualPOISelection()
    
    let samplePOIs = [
        POI(
            id: "1",
            name: "Alternative POI 1",
            latitude: 49.4577,
            longitude: 11.0751,
            category: .attraction,
            description: "Ein alternativer Ort.",
            tags: [:],
            sourceType: "preview",
            sourceId: 1,
            address: POIAddress(
                street: "Alternative Street",
                houseNumber: "1",
                city: "Nürnberg",
                postcode: "90403",
                country: "Deutschland"
            ),
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
    ]
    
    UnifiedSwipeView(
        configuration: .editPOI(excludedPOIs: []),
        availablePOIs: samplePOIs,
        enrichedPOIs: [:],
        selection: mockSelection,
        onPOISelected: { poi in
            print("POI selected for replacement: \(poi.name)")
        },
        onDismiss: {
            print("Edit view dismissed")
        }
    )
}
