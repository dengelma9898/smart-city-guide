import SwiftUI

/// Card stack view for displaying and managing POI swipe cards
struct POISelectionCardStackView: View {
    
    let visibleCards: [SwipeCard]
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    let onCardAction: (SwipeAction) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Render visible cards (max 3)
                ForEach(Array(visibleCards.enumerated()), id: \.element.id) { index, card in
                    SpotSwipeCardView(
                        card: .constant(card),
                        onSwipe: onCardAction
                    )
                    .overlay(alignment: .topLeading) {
                        // Wikipedia quality badge
                        if let enriched = enrichedPOIs[card.poi.id], 
                           let desc = enriched.shortDescription, 
                           !desc.isEmpty {
                            wikipediaQualityBadge
                        }
                    }
                    .zIndex(Double(visibleCards.count - index))
                    .scaleEffect(cardScale(for: index))
                    .offset(y: cardOffset(for: index))
                    .opacity(cardOpacity(for: index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.bottom, 24) // breathing space above bottom bar
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
    
    // MARK: - Card Stacking Effects
    
    private func cardScale(for index: Int) -> CGFloat {
        switch index {
        case 0: return 1.0      // Top card - full size
        case 1: return 0.95     // Second card - slightly smaller
        default: return 0.90    // Background cards - smallest
        }
    }
    
    private func cardOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0        // Top card - no offset
        case 1: return 8        // Second card - slight offset
        default: return 16      // Background cards - more offset
        }
    }
    
    private func cardOpacity(for index: Int) -> Double {
        switch index {
        case 0: return 1.0      // Top card - fully visible
        case 1: return 0.8      // Second card - slightly transparent
        default: return 0.6     // Background cards - more transparent
        }
    }
}

#Preview {
    // Create sample cards for preview
    let samplePOIs = [
        POI(
            id: "1",
            name: "Sample POI 1",
            latitude: 49.4521,
            longitude: 11.0767,
            category: .attraction,
            description: "A sample POI for preview",
            tags: [:],
            sourceType: "sample",
            sourceId: 1,
            address: nil,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        ),
        POI(
            id: "2", 
            name: "Sample POI 2",
            latitude: 49.4577,
            longitude: 11.0751,
            category: .museum,
            description: "Another sample POI",
            tags: [:],
            sourceType: "sample",
            sourceId: 2,
            address: nil,
            contact: nil,
            accessibility: nil,
            pricing: nil,
            operatingHours: nil,
            website: nil,
            geoapifyWikiData: nil
        )
    ]
    
    let sampleCards = samplePOIs.map { poi in
        SwipeCard(
            poi: poi,
            enrichedData: nil,
            distanceFromOriginal: 100.0,
            category: poi.category,
            wasReplaced: false
        )
    }
    
    POISelectionCardStackView(
        visibleCards: sampleCards,
        enrichedPOIs: [:],
        onCardAction: { action in
            print("Card action: \(action)")
        }
    )
    .frame(height: 500)
    .padding()
}
