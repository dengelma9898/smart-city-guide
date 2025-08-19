import SwiftUI
import CoreLocation

// MARK: - POI Selection Stack View
struct POISelectionStackView: View {
    // BINDING DATA
    @Binding var availablePOIs: [POI]
    @ObservedObject var selection: ManualPOISelection
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    let onSelectionComplete: () -> Void
    
    // SERVICES
    @StateObject private var cardService = POISelectionCardService()
    
    // STATE
    @State private var showingSelectionSummary = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Content
            Group {
                if cardService.hasCurrentCard() {
                    POISelectionCardStackView(
                        visibleCards: cardService.getVisibleCards(),
                        enrichedPOIs: enrichedPOIs,
                        onCardAction: { action in
                            cardService.handleCardAction(action, selection: selection)
                        }
                    )
                } else {
                    POISelectionCompletionView(
                        hasSelections: selection.hasSelections,
                        selectionCount: selection.selectedPOIs.count,
                        onComplete: onSelectionComplete,
                        onRestart: {
                            cardService.resetToBeginning()
                        }
                    )
                }
            }
        }
        // Top progress indicator
        .safeAreaInset(edge: .top) {
            if cardService.hasCurrentCard() {
                let progress = cardService.getProgress()
                POISelectionProgressView(
                    currentIndex: progress.current,
                    totalCount: progress.total
                )
            }
        }
        // Bottom action bar
        .safeAreaInset(edge: .bottom) {
            if cardService.hasCurrentCard() {
                POISelectionActionBar(
                    hasCurrentCard: cardService.hasCurrentCard(),
                    selectionCount: selection.selectedPOIs.count,
                    onAccept: {
                        cardService.selectCurrentCard(selection: selection)
                    },
                    onReject: {
                        cardService.rejectCurrentCard(selection: selection)
                    },
                    onSkip: {
                        cardService.skipCurrentCard()
                    },
                    onViewSelections: {
                        showingSelectionSummary = true
                    }
                )
            }
        }
        // Toast overlay
        .overlay(alignment: .bottom) {
            POISelectionToastView(
                message: cardService.toastMessage ?? "",
                isVisible: cardService.showToast
            )
        }
        .onAppear { 
            cardService.setupSwipeCards(from: availablePOIs, enrichedPOIs: enrichedPOIs)
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
                    .overlay(alignment: .topLeading) {
                        // Small metrics badge (polish)
                        if let enriched = enrichedPOIs[card.poi.id], let desc = enriched.shortDescription, !desc.isEmpty {
                            Text("📖 Wiki")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(.systemBackground).opacity(0.8)))
                                .padding(8)
                        }
                    }
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
            // Undo (if possible)
            if selection.canUndo {
                Button(action: handleUndo) {
                    Image(systemName: "arrow.uturn.left.circle")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Aktion rückgängig machen")
                .accessibilityIdentifier("manual.undo.button")
            }
            // Reject
            Button(action: rejectCurrentCard) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.red)
            }
            .accessibilityLabel("POI ablehnen")
            .accessibilityIdentifier("manual.reject.button")

            Spacer()

            // Live selection counter
            selectionCounter

            // Accept
            Button(action: selectCurrentCard) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.green)
            }
            .accessibilityLabel("POI auswählen")
            .accessibilityIdentifier("manual.select.button")
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

    private func handleUndo() {
        guard let last = selection.undoLast() else { return }
        var message = ""
        switch last {
        case .select(let poi):
            // Re-add the POI just before the current card to re-consider
            if let idx = availablePOIs.firstIndex(where: { $0.id == poi.id }) {
                // Ensure there is a card for it
                let card = SwipeCard(poi: poi, enrichedData: enrichedPOIs[poi.id], distanceFromOriginal: 0, category: poi.category, wasReplaced: false)
                swipeCards.insert(card, at: max(currentCardIndex, 0))
                availablePOIs.remove(at: idx)
            }
            message = "Zurückgenommen: Auswahl von \(poi.name)."
        case .reject(let poi):
            // Make rejected POI available again (insert next)
            let card = SwipeCard(poi: poi, enrichedData: enrichedPOIs[poi.id], distanceFromOriginal: 0, category: poi.category, wasReplaced: false)
            swipeCards.insert(card, at: max(currentCardIndex, 0))
            message = "Zurückgenommen: Ablehnung von \(poi.name)."
        case .undo:
            message = "Letzte Aktion zurückgenommen."
        }
        toast(message: message + " • Ausgewählt: \(selection.selectedPOIs.count)")
    }

    private func toast(message: String) {
        withAnimation {
            toastMessage = message
            showToast = true
        }
        // auto hide after 1.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showToast = false
            }
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
                    let addr = card.poi.address?.fullAddress ?? ""
                    Text("Interessanter Ort in \(addr)")
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