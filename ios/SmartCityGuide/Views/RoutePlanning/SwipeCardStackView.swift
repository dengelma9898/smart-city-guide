//
//  SwipeCardStackView.swift
//  SmartCityGuide
//
//  Route Edit Feature - Tinder-Style Card Stack Container
//

import SwiftUI
import CoreLocation

// MARK: - Notification Names

extension Notification.Name {
    static let manualCardRemoval = Notification.Name("manualCardRemoval")
    static let manualCardExit = Notification.Name("manualCardExit") // userInfo: ["cardId": String, "direction": "left"|"right"]
}

/// Container view that manages a stack of swipeable cards
struct SwipeCardStackView: View {
    /// Observable state for the card stack
    @StateObject private var stackState = CardStackState()
    
    /// Initial cards to display
    let initialCards: [SwipeCard]
    
    /// Callback when a card action is performed
    let onCardAction: (SwipeAction) -> Void
    
    /// Callback when stack is empty
    let onStackEmpty: () -> Void
    
    /// Callback to expose current top card for manual actions
    let onTopCardChanged: ((SwipeCard?) -> Void)?
    
    // Manual removal is handled via NotificationCenter
    
    /// Animation namespace for card transitions
    @Namespace private var cardNamespace
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                
                // Card stack or empty state
                if stackState.isEmpty {
                    emptyStateView
                } else {
                    cardStackView(in: geometry)
                }
                // Remove loading overlay for fluid UX; card transitions are visible anyway
            }
        }
        .onAppear {
            initializeStack()
        }
        .onChange(of: stackState.topCard) { oldCard, newCard in
            // Notify parent about top card changes for manual actions
            onTopCardChanged?(newCard)
        }
        .onReceive(NotificationCenter.default.publisher(for: .manualCardRemoval)) { _ in
            // Trigger manual card removal when notification is received
            stackState.removeTopCard()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.clear)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Card Stack
    
    private func cardStackView(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Render visible cards (max 3)
            ForEach(Array(stackState.visibleCards.enumerated()), id: \.element.id) { index, card in
                SwipeCardView(card: card, index: index)
                    .matchedGeometryEffect(id: card.id, in: cardNamespace)
            }
        }
        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.85)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    
    // MARK: - Individual Card in Stack
    
    private func SwipeCardView(card: SwipeCard, index: Int) -> some View {
        SpotSwipeCardView(
            card: .constant(card),
            onSwipe: handleCardAction
        )
        .onReceive(NotificationCenter.default.publisher(for: .manualCardExit)) { note in
            guard let dir = note.userInfo?["direction"] as? String, index == 0 else { return }
            // Animate top card off-screen in requested direction
            let exit: CGFloat = (dir == "left") ? -400 : 400
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                // Ensure starting at current stacked position (no snap back)
            }
            withAnimation(CardAnimationConfig.removeAnimation) {
                // Use zIndex/scales already set; the individual SpotSwipeCardView animates by
                // reading its own totalOffset via external notifications handled above
            }
        }
        .scaleEffect(card.scale)
        .opacity(card.opacity)
        .offset(y: CGFloat(index) * SwipeThresholds.backgroundCardOffset)
        .zIndex(card.zIndex)
        // Remove conflicting animation - card animations are handled individually
        // .animation removed to prevent timing conflicts with gesture animations
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            // Text content
            VStack(spacing: 8) {
                Text("Alle Alternativen durchgeschaut!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Du hast alle verfügbaren Alternativen für diesen Stopp gesehen.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Stats
            if stackState.totalCount > 0 {
                statsView
            }
            
            // Action button
            Button("Fertig") {
                onStackEmpty()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
    
    private var statsView: some View {
        HStack(spacing: 16) {
            statItem(
                icon: "eye.fill",
                label: "Angeschaut",
                value: "\(stackState.processedCount)"
            )
            
            Divider()
                .frame(height: 20)
            
            statItem(
                icon: "rectangle.stack.fill",
                label: "Gesamt",
                value: "\(stackState.totalCount)"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // Loading overlay removed (not shown) to keep interactions snappy
    
    // MARK: - Stack Management
    
    private func initializeStack() {
        let cardsWithPositions = initialCards.enumerated().map { index, card in
            var positionedCard = card
            
            // Set initial positions for stack effect
            if index == 0 {
                // Top card
                positionedCard.scale = 1.0
                positionedCard.zIndex = Double(initialCards.count)
                positionedCard.opacity = 1.0
            } else if index <= 2 {
                // Background cards
                let scaleReduction = CGFloat(index) * 0.05
                positionedCard.scale = 1.0 - scaleReduction
                positionedCard.zIndex = Double(initialCards.count - index)
                positionedCard.opacity = 1.0 - (Double(index) * 0.1)
            } else {
                // Hidden cards
                positionedCard.scale = 0.9
                positionedCard.zIndex = 0
                positionedCard.opacity = 0.0
            }
            
            return positionedCard
        }
        
        stackState.initialize(with: cardsWithPositions)
        
        // Notify parent about initial top card
        onTopCardChanged?(stackState.topCard)
    }
    
    private func handleCardAction(_ action: SwipeAction) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: action.isAccept ? .medium : .light)
        impactFeedback.impactOccurred()
        
        // Remove top card with animation
        withAnimation(CardAnimationConfig.removeAnimation) {
            stackState.removeTopCard()
        }
        
        // Check if stack is empty after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if stackState.isEmpty {
                onStackEmpty()
            }
        }
        
        // Notify parent about the action
        onCardAction(action)
    }
}

// MARK: - Convenience Initializers

extension SwipeCardStackView {
    /// Initialize with POIs and enriched data
    /// - Parameters:
    ///   - pois: Array of POIs to create cards from
    ///   - enrichedData: Dictionary of enriched Wikipedia data
    ///   - originalWaypoint: The original waypoint for distance calculation
    ///   - onCardAction: Callback for card actions
    ///   - onStackEmpty: Callback when stack becomes empty
    ///   - onTopCardChanged: Optional callback for top card changes
    init(
        pois: [POI],
        enrichedData: [String: WikipediaEnrichedPOI],
        originalWaypoint: RoutePoint,
        onCardAction: @escaping (SwipeAction) -> Void,
        onStackEmpty: @escaping () -> Void,
        onTopCardChanged: ((SwipeCard?) -> Void)? = nil
    ) {
        self.onCardAction = onCardAction
        self.onStackEmpty = onStackEmpty
        self.onTopCardChanged = onTopCardChanged
        
        // Create cards from POIs
        self.initialCards = pois.map { poi in
            // Calculate distance to original waypoint
            let fromLocation = CLLocation(
                latitude: poi.coordinate.latitude,
                longitude: poi.coordinate.longitude
            )
            let toLocation = CLLocation(
                latitude: originalWaypoint.coordinate.latitude,
                longitude: originalWaypoint.coordinate.longitude
            )
            let distance = fromLocation.distance(from: toLocation)
            
            // Create card
            return SwipeCard(
                poi: poi,
                enrichedData: enrichedData[poi.id],
                distanceFromOriginal: distance,
                category: poi.category,
                wasReplaced: false // Default for new cards from convenience init
            )
        }
    }
}

// MARK: - Preview

#Preview("Card Stack - Multiple Cards") {
    @Previewable @State var actionLog: [String] = []
    
    let samplePOIs = [
        POI(
            id: "sample_1",
            name: "Nürnberger Burg",
            latitude: 49.4577,
            longitude: 11.0751,
            category: .attraction,
            description: "Eine mittelalterliche Burg auf einem Sandsteinfelsen.",
            tags: [:],
            sourceType: "sample",
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
            id: "sample_2",
            name: "Germanisches Nationalmuseum",
            latitude: 49.4481,
            longitude: 11.0661,
            category: .museum,
            description: "Das größte kulturhistorische Museum Deutschlands.",
            tags: [:],
            sourceType: "sample",
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
        ),
        POI(
            id: "sample_3",
            name: "Stadtpark Nürnberg",
            latitude: 49.4521,
            longitude: 11.0631,
            category: .park,
            description: "Ein schöner Stadtpark im Herzen von Nürnberg.",
            tags: [:],
            sourceType: "sample",
            sourceId: 3,
            address: POIAddress(
                street: "Stadtparkstraße",
                houseNumber: nil,
                city: "Nürnberg",
                postcode: "90408",
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
    
    let originalWaypoint = RoutePoint(
        name: "Hauptmarkt",
        coordinate: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767),
        address: "Hauptmarkt, Nürnberg",
        category: .attraction
    )
    
    VStack {
        SwipeCardStackView(
            pois: samplePOIs,
            enrichedData: [:],
            originalWaypoint: originalWaypoint,
            onCardAction: { action in
                actionLog.append("Action: \(action)")
            },
            onStackEmpty: {
                actionLog.append("Stack empty!")
            }
        )
        .frame(height: 500)
        
        // Action log
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Action Log:")
                    .font(.headline)
                
                ForEach(actionLog.indices, id: \.self) { index in
                    Text(actionLog[index])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(height: 100)
    }
    .background(Color(.systemGray6))
}

#Preview("Card Stack - Empty State") {
    SwipeCardStackView(
        initialCards: [],
        onCardAction: { _ in },
        onStackEmpty: { print("Empty!") },
        onTopCardChanged: nil
    )
    .frame(height: 500)
    .background(Color(.systemGray6))
}