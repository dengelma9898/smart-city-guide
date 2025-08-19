import Foundation
import os.log

/// Service for managing POI selection card logic and state
@MainActor
class POISelectionCardService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "POISelectionCard")
    
    @Published var swipeCards: [SwipeCard] = []
    @Published var currentCardIndex = 0
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false
    
    // MARK: - Public Interface
    
    /// Setup swipe cards from available POIs
    /// - Parameters:
    ///   - availablePOIs: POIs to create cards from
    ///   - enrichedPOIs: Wikipedia enrichment data
    func setupSwipeCards(
        from availablePOIs: [POI],
        enrichedPOIs: [String: WikipediaEnrichedPOI]
    ) {
        logger.info("🎴 Setting up \(availablePOIs.count) swipe cards")
        
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
        
        logger.info("🎴 Created \(self.swipeCards.count) swipe cards")
    }
    
    /// Get currently visible cards (max 3)
    /// - Returns: Array of visible cards for rendering
    func getVisibleCards() -> [SwipeCard] {
        let remaining = Array(self.swipeCards.dropFirst(self.currentCardIndex))
        return Array(remaining.prefix(3)) // Show max 3 cards
    }
    
    /// Check if there are more cards available
    /// - Returns: True if current index is within bounds
    func hasCurrentCard() -> Bool {
        return currentCardIndex < swipeCards.count
    }
    
    /// Get current POI if available
    /// - Returns: Current POI or nil if no more cards
    func getCurrentPOI() -> POI? {
        guard hasCurrentCard() else { return nil }
        return swipeCards[currentCardIndex].poi
    }
    
    /// Advance to next card
    func advanceToNextCard() {
        guard currentCardIndex < swipeCards.count else { return }
        
        logger.debug("🎴 Advancing from card \(self.currentCardIndex) to \(self.currentCardIndex + 1)")
        currentCardIndex += 1
        
        if currentCardIndex >= swipeCards.count {
            logger.info("🎴 All cards processed")
        }
    }
    
    /// Show toast message with auto-hide
    /// - Parameter message: Message to display
    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        // Auto-hide after 2 seconds
        Task { [weak self] in
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                self?.showToast = false
            }
        }
    }
    
    /// Reset to beginning for restart
    func resetToBeginning() {
        logger.info("🎴 Resetting card selection to beginning")
        currentCardIndex = 0
        showToast = false
        toastMessage = nil
    }
    
    /// Get progress information
    /// - Returns: Tuple with current index and total count
    func getProgress() -> (current: Int, total: Int) {
        return (self.currentCardIndex, self.swipeCards.count)
    }
    
    /// Handle card action and advance
    /// - Parameters:
    ///   - action: The swipe action performed
    ///   - selection: The manual POI selection manager
    func handleCardAction(
        _ action: SwipeAction,
        selection: ManualPOISelection
    ) {
        guard let currentPOI = getCurrentPOI() else { return }
        
        switch action {
        case .accept(let poi):
            logger.debug("🎴 Accepting POI: \(poi.name)")
            selection.selectPOI(poi)
            showToastMessage("POI zur Auswahl hinzugefügt")
            advanceToNextCard()
            
        case .reject(let poi):
            logger.debug("🎴 Rejecting POI: \(poi.name)")
            selection.rejectPOI(poi)
            showToastMessage("POI abgelehnt")
            advanceToNextCard()
            
        case .skip:
            logger.debug("🎴 Skipping POI: \(currentPOI.name)")
            showToastMessage("POI übersprungen")
            advanceToNextCard()
        }
    }
    
    /// Manually select current card
    func selectCurrentCard(selection: ManualPOISelection) {
        guard let currentPOI = getCurrentPOI() else { return }
        
        logger.debug("🎴 Manually selecting current POI: \(currentPOI.name)")
        selection.selectPOI(currentPOI)
        showToastMessage("POI ausgewählt!")
        advanceToNextCard()
    }
    
    /// Manually reject current card
    func rejectCurrentCard(selection: ManualPOISelection) {
        guard let currentPOI = getCurrentPOI() else { return }
        
        logger.debug("🎴 Manually rejecting current POI: \(currentPOI.name)")
        selection.rejectPOI(currentPOI)
        showToastMessage("POI abgelehnt")
        advanceToNextCard()
    }
    
    /// Manually skip current card
    func skipCurrentCard() {
        guard getCurrentPOI() != nil else { return }
        
        logger.debug("🎴 Manually skipping current POI")
        showToastMessage("POI übersprungen")
        advanceToNextCard()
    }
}
