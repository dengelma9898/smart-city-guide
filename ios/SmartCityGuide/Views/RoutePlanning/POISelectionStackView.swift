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
}

#Preview {
    POISelectionStackView(
        availablePOIs: .constant([]),
        selection: ManualPOISelection(),
        enrichedPOIs: [:],
        onSelectionComplete: { print("Selection completed") }
    )
}