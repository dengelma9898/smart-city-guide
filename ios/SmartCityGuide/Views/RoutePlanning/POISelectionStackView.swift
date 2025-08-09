import SwiftUI
import CoreLocation

// MARK: - POI Selection Stack View
struct POISelectionStackView: View {
    // BINDING DATA
    @Binding var availablePOIs: [POI]
    @ObservedObject var selection: ManualPOISelection
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    let onSelectionComplete: () -> Void
    
    // STATE
    @State private var swipeCards: [SwipeCard] = []
    @State private var currentCardIndex = 0
    @State private var showingSelectionSummary = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            Group {
                if currentCardIndex < swipeCards.count {
                    cardStackView
                        .padding(.bottom, 24) // breathing space above bottom bar
                } else {
                    completionView
                }
            }
        }
        // Top index badge below the navigation bar
        .safeAreaInset(edge: .top) {
            if currentCardIndex < swipeCards.count {
                HStack {
                    indexBadge
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        // Bottom action bar for primary actions (does not overlap content)
        .safeAreaInset(edge: .bottom) {
            if currentCardIndex < swipeCards.count {
                actionBar
            }
        }
        .onAppear { setupSwipeCards() }
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
    
    // MARK: - Card Stack
    
    private var cardStackView: some View {
        GeometryReader { geometry in
            ZStack {
                // Render visible cards (max 3)
                ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                    POISwipeCardView(
                        card: .constant(card),
                        enrichedData: enrichedPOIs[card.poi.id],
                        onSwipe: handleCardAction
                    )
                    .scaleEffect(1.0 - CGFloat(index) * 0.05)
                    .opacity(1.0 - Double(index) * 0.3)
                    .offset(y: CGFloat(index) * 10)
                    .zIndex(Double(visibleCards.count - index))
                }
            }
            .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    // MARK: - Selection Status Overlay
    
    private var indexBadge: some View {
        HStack(spacing: 6) {
            Text("\(currentCardIndex + 1)")
                .font(.subheadline).fontWeight(.semibold)
            Text("von \(swipeCards.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.regularMaterial))
    }
    
    // MARK: - Action Buttons Overlay
    
    private var actionBar: some View {
        HStack(spacing: 28) {
            // Reject
            Button(action: rejectCurrentCard) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.red)
            }
            .accessibilityLabel("POI ablehnen")

            Spacer()

            // Accept
            Button(action: selectCurrentCard) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.green)
            }
            .accessibilityLabel("POI auswählen")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(
            Divider().background(Color.primary.opacity(0.1)), alignment: .top
        )
    }
    
    // MARK: - Selection Counter
    
    private var selectionCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("\(selection.selectedPOIs.count)")
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: selection.hasSelections ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(selection.hasSelections ? .green : .orange)
                
                Text(selection.hasSelections ? "Auswahl abgeschlossen!" : "Keine POIs ausgewählt")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if selection.hasSelections {
                    Text("Du hast \(selection.selectedPOIs.count) interessante Orte ausgewählt")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Du kannst trotzdem fortfahren oder nochmal durch die POIs swipen")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    onSelectionComplete()
                }) {
                    Text(selection.hasSelections ? "Weiter zur Route" : "Ohne POIs fortfahren")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selection.hasSelections ? .blue : .gray)
                        )
                }
                
                Button(action: {
                    resetAndRestart()
                }) {
                    Text("Nochmal von vorne")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var visibleCards: [SwipeCard] {
        let remaining = Array(swipeCards.dropFirst(currentCardIndex))
        return Array(remaining.prefix(3)) // Show max 3 cards
    }
    
    // MARK: - Business Logic
    
    private func setupSwipeCards() {
        // Create swipe cards from available POIs
        swipeCards = availablePOIs.map { poi in
            SwipeCard(
                poi: poi,
                enrichedData: enrichedPOIs[poi.id],
                distanceFromOriginal: 0, // Not relevant for manual selection
                category: poi.category,
                wasReplaced: false
            )
        }
        currentCardIndex = 0
    }
    
    private func handleCardAction(_ action: SwipeAction) {
        guard currentCardIndex < swipeCards.count else { return }
        
        switch action {
        case .accept(let poi):
            // Left swipe = Select POI
            selection.selectPOI(poi)
            advanceToNextCard()
        case .reject(let poi):
            // Right swipe = Reject POI
            selection.rejectPOI(poi)
            advanceToNextCard()
        case .skip:
            // Skip without decision
            advanceToNextCard()
        }
    }
    
    private func selectCurrentCard() {
        guard currentCardIndex < swipeCards.count else { return }
        let currentPOI = swipeCards[currentCardIndex].poi
        selection.selectPOI(currentPOI)
        advanceToNextCard()
    }
    
    private func rejectCurrentCard() {
        guard currentCardIndex < swipeCards.count else { return }
        let currentPOI = swipeCards[currentCardIndex].poi
        selection.rejectPOI(currentPOI)
        advanceToNextCard()
    }
    
    private func advanceToNextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardIndex += 1
        }
    }
    
    private func resetAndRestart() {
        selection.reset()
        currentCardIndex = 0
        setupSwipeCards()
    }
}

// MARK: - POI Swipe Card View
struct POISwipeCardView: View {
    @Binding var card: SwipeCard
    let enrichedData: WikipediaEnrichedPOI?
    let onSwipe: (SwipeAction) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            AsyncImage(url: URL(string: enrichedData?.wikipediaData?.thumbnail?.source ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        VStack {
                            Text(card.category.icon)
                                .font(.system(size: 48))
                            Text(card.category.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                    )
            }
            .frame(height: 300)
            .clipped()
            
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(card.poi.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                // Category
                HStack {
                    Text(card.category.icon)
                        .font(.system(size: 20))
                    Text(card.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                // Wikipedia Description
                if let enriched = enrichedData,
                   let description = enriched.wikipediaData?.extract {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                } else {
                    Text("Interessanter Ort in \(card.poi.address)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .overlay(
            // Swipe Direction Indicators
            Group {
                if abs(offset.width) > 50 {
                    swipeIndicator
                }
            }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 10)
                }
                .onEnded { value in
                    handleSwipeEnd(value.translation)
                }
        )
    }
    
    private var swipeIndicator: some View {
        VStack {
            HStack {
                if offset.width > 0 {
                    // Right swipe indicator (reject)
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        )
                        .opacity(min(1.0, abs(offset.width) / swipeThreshold))
                } else {
                    // Left swipe indicator (select)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        )
                        .opacity(min(1.0, abs(offset.width) / swipeThreshold))
                    Spacer()
                }
            }
            Spacer()
        }
        .padding(30)
    }
    
    private func handleSwipeEnd(_ translation: CGSize) {
        let swipeDirection: SwipeDirection
        
        if abs(translation.width) > swipeThreshold {
            swipeDirection = translation.width > 0 ? .right : .left
            
            // Animate card off screen
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(
                    width: translation.width > 0 ? 400 : -400,
                    height: translation.height
                )
                rotation = translation.width > 0 ? 15 : -15
            }
            
            // Trigger callback after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [card] in
                let action: SwipeAction = swipeDirection == .left ? .accept(card.poi) : .reject(card.poi)
                onSwipe(action)
            }
        } else {
            // Snap back to center
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    POISelectionStackView(
        availablePOIs: .constant([]),
        selection: ManualPOISelection(),
        enrichedPOIs: [:],
        onSelectionComplete: {}
    )
}