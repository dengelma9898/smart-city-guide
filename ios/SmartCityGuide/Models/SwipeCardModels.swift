//
//  SwipeCardModels.swift
//  SmartCityGuide
//
//  Created on $(date)
//  Route Edit Feature - Tinder-Style Card Implementation
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Swipe Card Core Model

/// Individual swipe card representing a POI alternative
struct SwipeCard: Identifiable, Equatable {
    /// Unique identifier for the card
    let id = UUID()
    
    /// The POI this card represents
    let poi: POI
    
    /// Enriched Wikipedia data if available
    let enrichedData: WikipediaEnrichedPOI?
    
    /// Distance from the original route waypoint (in meters)
    let distanceFromOriginal: Double
    
    /// Category of the POI for display and filtering
    let category: PlaceCategory
    
    /// Whether this POI was previously replaced at this position
    let wasReplaced: Bool
    
    /// Current drag offset for animations
    var offset: CGSize = .zero
    
    /// Whether the card is currently animating
    var isAnimating: Bool = false
    
    /// Z-index for card stacking (lower values appear behind)
    var zIndex: Double = 0
    
    /// Scale factor for card depth effect
    var scale: CGFloat = 1.0
    
    /// Opacity for fade effects
    var opacity: Double = 1.0
    
    /// Initialize a swipe card
    /// - Parameters:
    ///   - poi: The POI this card represents
    ///   - enrichedData: Optional Wikipedia enrichment data
    ///   - distanceFromOriginal: Distance to original waypoint in meters
    ///   - category: PlaceCategory for display
    ///   - wasReplaced: Whether this POI was previously replaced at this position
    init(poi: POI, enrichedData: WikipediaEnrichedPOI? = nil, distanceFromOriginal: Double, category: PlaceCategory, wasReplaced: Bool = false) {
        self.poi = poi
        self.enrichedData = enrichedData
        self.distanceFromOriginal = distanceFromOriginal
        self.category = category
        self.wasReplaced = wasReplaced
    }
    
    // MARK: - Equatable
    
    static func == (lhs: SwipeCard, rhs: SwipeCard) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Swipe Direction & Gestures

/// Direction of swipe gesture
enum SwipeDirection: CaseIterable {
    /// Swipe left - Accept the POI
    case left
    /// Swipe right - Reject the POI  
    case right
    /// No clear direction
    case none
    
    /// Color associated with the swipe direction
    var indicatorColor: Color {
        switch self {
        case .left:
            return .green  // Accept = Green
        case .right:
            return .red    // Reject = Red
        case .none:
            return .clear
        }
    }
    
    /// Icon for the swipe direction
    var indicatorIcon: String {
        switch self {
        case .left:
            return "checkmark.circle.fill"  // Accept icon
        case .right:
            return "xmark.circle.fill"      // Reject icon
        case .none:
            return ""
        }
    }
    
    /// German text for the action
    var actionText: String {
        switch self {
        case .left:
            return "Nehmen"
        case .right:
            return "Überspringen"
        case .none:
            return ""
        }
    }
    
    /// Whether this direction represents acceptance
    var isAccept: Bool {
        return self == .left
    }
    
    /// Whether this direction represents rejection
    var isReject: Bool {
        return self == .right
    }
}

/// Swipe gesture data
struct SwipeGesture {
    /// Direction of the swipe
    let direction: SwipeDirection
    
    /// Velocity of the gesture
    let velocity: CGFloat
    
    /// Final translation when gesture ended
    let translation: CGSize
    
    /// Whether the gesture was strong enough to trigger action
    var isTriggerGesture: Bool {
        return abs(translation.width) >= SwipeThresholds.triggerDistance
    }
    
    /// Whether the gesture should auto-complete
    var shouldAutoComplete: Bool {
        return abs(translation.width) >= SwipeThresholds.autoCompleteDistance || 
               abs(velocity) >= SwipeThresholds.autoCompleteVelocity
    }
    
    /// Initialize a swipe gesture
    /// - Parameters:
    ///   - translation: Final drag translation
    ///   - velocity: Gesture velocity
    init(translation: CGSize, velocity: CGFloat) {
        self.translation = translation
        self.velocity = velocity
        
        // Determine direction based on translation
        if translation.width > SwipeThresholds.directionThreshold {
            self.direction = .right
        } else if translation.width < -SwipeThresholds.directionThreshold {
            self.direction = .left
        } else {
            self.direction = .none
        }
    }
}

// MARK: - Swipe Configuration & Thresholds

/// Configuration values for swipe behavior
enum SwipeThresholds {
    /// Minimum drag distance to determine direction
    static let directionThreshold: CGFloat = 30
    
    /// Minimum drag distance to trigger action
    static let triggerDistance: CGFloat = 100
    
    /// Distance for automatic completion
    static let autoCompleteDistance: CGFloat = 150
    
    /// Velocity threshold for auto-completion
    static let autoCompleteVelocity: CGFloat = 500
    
    /// Maximum rotation angle (in degrees)
    static let maxRotationAngle: Double = 15
    
    /// Scale factor for background cards
    static let backgroundCardScale: CGFloat = 0.95
    
    /// Offset for background cards (vertical)
    static let backgroundCardOffset: CGFloat = 8
}

// MARK: - Card Animation Configuration

/// Animation configuration for card interactions
struct CardAnimationConfig {
    /// Spring animation for card returns
    static let returnAnimation = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0.1
    )
    
    /// Animation for card removal
    static let removeAnimation = Animation.easeOut(duration: 0.3)
    
    /// Animation for new card appearance
    static let appearAnimation = Animation.easeIn(duration: 0.2)
    
    /// Animation for stack reorganization
    static let stackAnimation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.9,
        blendDuration: 0.05
    )
    
    /// Haptic feedback intensity
    static let hapticIntensity: CGFloat = 0.7
}

// MARK: - Card Stack State

/// State management for the card stack
@MainActor
class CardStackState: ObservableObject {
    /// Current cards in the stack
    @Published var cards: [SwipeCard] = []
    
    /// Index of the top card
    @Published var topCardIndex: Int = 0
    
    /// Whether cards are currently animating
    @Published var isAnimating: Bool = false
    
    /// Number of cards processed
    @Published var processedCount: Int = 0
    
    /// Total number of cards initially loaded
    @Published var totalCount: Int = 0
    
    /// Whether the stack is empty
    var isEmpty: Bool {
        return topCardIndex >= cards.count
    }
    
    /// Current top card (if any)
    var topCard: SwipeCard? {
        guard !isEmpty else { return nil }
        return cards[topCardIndex]
    }
    
    /// Visible cards (top 3 maximum)
    var visibleCards: [SwipeCard] {
        guard !isEmpty else { return [] }
        let endIndex = min(topCardIndex + 3, cards.count)
        return Array(cards[topCardIndex..<endIndex])
    }
    
    /// Initialize card stack
    /// - Parameter cards: Initial array of cards
    func initialize(with cards: [SwipeCard]) {
        self.cards = cards
        self.topCardIndex = 0
        self.processedCount = 0
        self.totalCount = cards.count
        updateCardPositions()
    }
    
    /// Remove the top card and advance stack
    func removeTopCard() {
        guard !isEmpty else { return }
        
        isAnimating = true
        topCardIndex += 1
        processedCount += 1
        
        // Update positions of remaining cards
        updateCardPositions()
        
        // Animation delay to allow card removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }
    
    /// Reset top card position after bounce-back
    func resetTopCard() {
        guard let topCard = topCard else { return }
        
        withAnimation(CardAnimationConfig.returnAnimation) {
            if let index = cards.firstIndex(where: { $0.id == topCard.id }) {
                cards[index].offset = .zero
                cards[index].isAnimating = false
            }
        }
    }
    
    /// Update positions and properties of cards in stack
    private func updateCardPositions() {
        for (index, card) in cards.enumerated() {
            let relativeIndex = index - topCardIndex
            
            if let cardIndex = cards.firstIndex(where: { $0.id == card.id }) {
                if relativeIndex < 0 {
                    // Cards that have been swiped away
                    cards[cardIndex].opacity = 0
                    cards[cardIndex].zIndex = -1
                } else if relativeIndex == 0 {
                    // Top card
                    cards[cardIndex].scale = 1.0
                    cards[cardIndex].zIndex = Double(cards.count)
                    cards[cardIndex].opacity = 1.0
                } else if relativeIndex <= 2 {
                    // Background cards (up to 2 behind top)
                    let scaleReduction = CGFloat(relativeIndex) * 0.05
                    cards[cardIndex].scale = 1.0 - scaleReduction
                    cards[cardIndex].zIndex = Double(cards.count - relativeIndex)
                    cards[cardIndex].opacity = 1.0 - (Double(relativeIndex) * 0.1)
                } else {
                    // Cards too far back (hidden)
                    cards[cardIndex].opacity = 0
                    cards[cardIndex].zIndex = 0
                }
            }
        }
    }
    
    /// Reset the entire stack
    func reset() {
        cards.removeAll()
        topCardIndex = 0
        processedCount = 0
        totalCount = 0
        isAnimating = false
    }
}

// MARK: - Card Display Helpers

extension SwipeCard {
    /// Formatted distance text for display
    var distanceText: String {
        if distanceFromOriginal < 1000 {
            return String(format: "%.0f m", distanceFromOriginal)
        } else {
            return String(format: "%.1f km", distanceFromOriginal / 1000)
        }
    }
    
    /// Walking time estimate based on distance (3.5 km/h average)
    var walkingTimeText: String {
        let walkingSpeedKmH: Double = 3.5
        let walkingSpeedMs: Double = walkingSpeedKmH * 1000 / 3600  // m/s
        let timeSeconds = distanceFromOriginal / walkingSpeedMs
        
        if timeSeconds < 60 {
            return "< 1 min"
        } else {
            let minutes = Int(timeSeconds / 60)
            return "\(minutes) min"
        }
    }
    
    /// Image URL for the POI (Wikipedia or placeholder)
    var imageURL: URL? {
        // Try Wikipedia image first
        if let enrichedData = enrichedData,
           let imageURLString = enrichedData.wikipediaImageURL,
           let imageURL = URL(string: imageURLString) {
            return imageURL
        }
        
        // For now, Geoapify wiki data doesn't provide direct image URLs
        // but we might add this functionality later
        
        return nil
    }
    
    /// Description text for the card
    var descriptionText: String {
        // Try enriched Wikipedia data first
        if let enrichedData = enrichedData {
            return enrichedData.enhancedDescription
        }
        
        // Fallback: Wenn nur technische/irrelevante Infos vorhanden sind, dem Nutzer klar sagen,
        // dass wir keine weiteren Details gefunden haben.
        let text = poi.displayDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        // Heuristik: technische Geoapify-Tags erkennen und ausblenden
        let technicalTokens = [
            "leisure",
            "details",
            "place_of_worship",
            "wiki",
            "heritage",
            "facilities",
            "opening_hours",
            "amenity",
            "shop",
            "addr:",
            "addr.",
            "contact:"
        ]
        if text.isEmpty || text == poi.category.rawValue || technicalTokens.contains(where: { lower.contains($0) }) {
            return "Zu diesem Ort haben wir leider keine weiteren Infos gefunden."
        }
        return text
    }
    
    /// Whether the card has quality content (images + description)
    var hasQualityContent: Bool {
        return imageURL != nil && !descriptionText.isEmpty && descriptionText != category.rawValue
    }
}

// MARK: - Gesture Helper Extensions

extension CGSize {
    /// Magnitude of the size vector
    var magnitude: CGFloat {
        return sqrt(width * width + height * height)
    }
    
    /// Angle in radians
    var angle: Double {
        return atan2(Double(height), Double(width))
    }
}

extension SwipeDirection {
    /// Create direction from translation
    /// - Parameter translation: Drag translation
    /// - Returns: Appropriate swipe direction
    static func from(translation: CGSize) -> SwipeDirection {
        if translation.width > SwipeThresholds.directionThreshold {
            return .right
        } else if translation.width < -SwipeThresholds.directionThreshold {
            return .left
        } else {
            return .none
        }
    }
}