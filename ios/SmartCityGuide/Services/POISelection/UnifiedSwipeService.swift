//
//  UnifiedSwipeService.swift
//  SmartCityGuide
//
//  Created on 2025-08-22
//  Unified service for managing POI selection across different flows
//

import Foundation
import os.log

/// Unified service for managing POI selection card logic across all flows
@MainActor
class UnifiedSwipeService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "UnifiedSwipe")
    
    @Published var swipeCards: [SwipeCard] = []
    @Published var currentCardIndex = 0
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false
    
    /// Current flow configuration
    private(set) var currentConfiguration: SwipeFlowConfiguration?
    
    /// Original cards before any processing (for recycling)
    private var originalCards: [SwipeCard] = []
    
    /// Cards that have been rejected (for recycling to back of stack)
    private var rejectedCards: [SwipeCard] = []
    
    // MARK: - Configuration
    
    /// Configure the service for a specific flow
    /// - Parameters:
    ///   - configuration: Flow configuration defining behavior
    ///   - availablePOIs: All available POIs for selection
    ///   - enrichedPOIs: Wikipedia enrichment data
    func configure(
        with configuration: SwipeFlowConfiguration,
        availablePOIs: [POI],
        enrichedPOIs: [String: WikipediaEnrichedPOI]
    ) {
        logger.info("🎴 Configuring UnifiedSwipeService for flow: \(configuration.description)")
        
        self.currentConfiguration = configuration
        
        // Filter POIs based on configuration
        let filteredPOIs = configuration.filterPOIs(availablePOIs)
        
        logger.info("🎴 Filtered \(availablePOIs.count) POIs to \(filteredPOIs.count) for current flow")
        
        // Create swipe cards
        let cards = filteredPOIs.map { poi in
            SwipeCard(
                poi: poi,
                enrichedData: enrichedPOIs[poi.id],
                distanceFromOriginal: 0, // Will be calculated based on context
                category: poi.category,
                wasReplaced: false
            )
        }
        
        self.swipeCards = cards
        self.originalCards = cards
        self.currentCardIndex = 0
        self.rejectedCards = []
        
        // Clear any existing toast
        self.showToast = false
        self.toastMessage = nil
        
        logger.info("🎴 Created \(self.swipeCards.count) swipe cards for flow")
    }
    
    // MARK: - Card Stack Management
    
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
            handleStackEmpty()
        }
    }
    
    /// Handle when the card stack becomes empty
    private func handleStackEmpty() {
        guard let config = currentConfiguration else { return }
        
        if config.isManualFlow && !self.rejectedCards.isEmpty {
            // For manual flows, we can recycle rejected cards
            logger.info("🎴 Stack empty, recycling available for \(self.rejectedCards.count) rejected cards")
        } else {
            logger.info("🎴 Stack empty, no more cards available")
        }
    }
    
    // MARK: - Card Action Handling
    
    /// Handle card action and advance based on flow configuration
    /// - Parameters:
    ///   - action: The swipe action performed
    ///   - selection: The manual POI selection manager
    func handleCardAction(
        _ action: SwipeAction,
        selection: ManualPOISelection
    ) {
        guard let currentPOI = getCurrentPOI(),
              let config = currentConfiguration else { return }
        
        switch action {
        case .accept(let poi):
            logger.debug("🎴 Accepting POI: \(poi.name)")
            handleAcceptAction(poi: poi, selection: selection, config: config)
            
        case .reject(let poi):
            logger.debug("🎴 Rejecting POI: \(poi.name)")
            handleRejectAction(poi: poi, selection: selection, config: config)
            
        case .skip:
            logger.debug("🎴 Skipping POI: \(currentPOI.name)")
            handleSkipAction(poi: currentPOI, config: config)
        }
        
        advanceToNextCard()
    }
    
    /// Handle accept action
    private func handleAcceptAction(
        poi: POI,
        selection: ManualPOISelection,
        config: SwipeFlowConfiguration
    ) {
        selection.selectPOI(poi)
        
        if config.showToastMessages {
            showToastMessage("POI zur Auswahl hinzugefügt")
        }
        
        // For edit flow, we might need additional handling
        if config.isEditFlow {
            logger.info("🎴 POI selected for edit flow: \(poi.name)")
        }
    }
    
    /// Handle reject action  
    private func handleRejectAction(
        poi: POI,
        selection: ManualPOISelection,
        config: SwipeFlowConfiguration
    ) {
        selection.rejectPOI(poi)
        
        // Add to rejected cards for potential recycling
        if let cardIndex = self.swipeCards.firstIndex(where: { $0.poi.id == poi.id }) {
            let rejectedCard = self.swipeCards[cardIndex]
            self.rejectedCards.append(rejectedCard)
        }
        
        if config.showToastMessages {
            showToastMessage("POI abgelehnt")
        }
    }
    
    /// Handle skip action
    private func handleSkipAction(poi: POI, config: SwipeFlowConfiguration) {
        // Add to rejected cards for potential recycling (skip = soft reject)
        if let cardIndex = self.swipeCards.firstIndex(where: { $0.poi.id == poi.id }) {
            let skippedCard = self.swipeCards[cardIndex]
            self.rejectedCards.append(skippedCard)
        }
        
        if config.showToastMessages {
            showToastMessage("POI übersprungen")
        }
    }
    
    // MARK: - Card Recycling
    
    /// Recycle rejected cards to the back of the stack
    func recycleRejectedCards() {
        guard !self.rejectedCards.isEmpty else { return }
        
        logger.info("🎴 Recycling \(self.rejectedCards.count) rejected cards to back of stack")
        
        // Reset the card stack with rejected cards appended
        let activeCards = Array(self.swipeCards.prefix(self.currentCardIndex))
        let remainingCards = Array(self.swipeCards.dropFirst(self.currentCardIndex))
        
        // Append rejected cards to the end
        self.swipeCards = activeCards + remainingCards + self.rejectedCards
        
        // Clear rejected cards since they're now back in the main stack
        self.rejectedCards = []
        
        // If we were at the end, reset to continue with recycled cards
        if self.currentCardIndex >= self.swipeCards.count - self.rejectedCards.count {
            self.currentCardIndex = self.swipeCards.count - self.rejectedCards.count
        }
        
        logger.info("🎴 Card recycling complete, \(self.swipeCards.count) total cards available")
    }
    
    /// Check if card recycling is available
    func canRecycleCards() -> Bool {
        return !self.rejectedCards.isEmpty
    }
    
    // MARK: - Manual Actions
    
    /// Manually select current card
    func selectCurrentCard(selection: ManualPOISelection) {
        guard let currentPOI = getCurrentPOI(),
              let config = currentConfiguration else { return }
        
        logger.debug("🎴 Manually selecting current POI: \(currentPOI.name)")
        handleAcceptAction(poi: currentPOI, selection: selection, config: config)
        advanceToNextCard()
    }
    
    /// Manually reject current card
    func rejectCurrentCard(selection: ManualPOISelection) {
        guard let currentPOI = getCurrentPOI(),
              let config = currentConfiguration else { return }
        
        logger.debug("🎴 Manually rejecting current POI: \(currentPOI.name)")
        handleRejectAction(poi: currentPOI, selection: selection, config: config)
        advanceToNextCard()
    }
    
    /// Manually skip current card
    func skipCurrentCard() {
        guard let currentPOI = getCurrentPOI(),
              let config = currentConfiguration else { return }
        
        logger.debug("🎴 Manually skipping current POI: \(currentPOI.name)")
        handleSkipAction(poi: currentPOI, config: config)
        advanceToNextCard()
    }
    
    // MARK: - Toast Messages
    
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
    
    // MARK: - Progress Tracking
    
    /// Get progress information
    /// - Returns: Tuple with current index and total count
    func getProgress() -> (current: Int, total: Int) {
        return (self.currentCardIndex, self.swipeCards.count)
    }
    
    /// Get selection progress for manual flows
    /// - Parameter selection: Current selection state
    /// - Returns: Number of selected POIs
    func getSelectionCount(selection: ManualPOISelection) -> Int {
        return selection.selectedPOIs.count
    }
    
    // MARK: - Reset and Cleanup
    
    /// Reset to beginning for restart
    func resetToBeginning() {
        logger.info("🎴 Resetting card selection to beginning")
        self.currentCardIndex = 0
        self.showToast = false
        self.toastMessage = nil
        
        // Reset to original cards
        self.swipeCards = self.originalCards
        self.rejectedCards = []
    }
    
    /// Clear all state
    func clearAll() {
        logger.info("🎴 Clearing all UnifiedSwipeService state")
        self.swipeCards = []
        self.originalCards = []
        self.rejectedCards = []
        self.currentCardIndex = 0
        self.currentConfiguration = nil
        self.showToast = false
        self.toastMessage = nil
    }
    
    // MARK: - Flow-Specific Helpers
    
    /// Check if the current flow allows continuous swiping
    var allowsContinuousSwipe: Bool {
        return currentConfiguration?.allowContinuousSwipe ?? true
    }
    
    /// Check if the current flow should auto-confirm selections
    var shouldAutoConfirm: Bool {
        return currentConfiguration?.autoConfirmSelection ?? false
    }
    
    /// Check if selection counter should be shown
    var shouldShowSelectionCounter: Bool {
        return currentConfiguration?.showSelectionCounter ?? true
    }
    
    /// Check if confirm button should be shown
    var shouldShowConfirmButton: Bool {
        return currentConfiguration?.showConfirmButton ?? true
    }
}
