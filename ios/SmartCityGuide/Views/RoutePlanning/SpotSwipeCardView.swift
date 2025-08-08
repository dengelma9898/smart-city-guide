//
//  SpotSwipeCardView.swift
//  SmartCityGuide
//
//  Route Edit Feature - Individual Tinder-Style Swipe Card
//

import SwiftUI
import CoreLocation

/// Individual swipe card for POI alternatives in route editing
struct SpotSwipeCardView: View {
    /// Binding to the card data (for offset updates)
    @Binding var card: SwipeCard
    
    /// Callback when swipe action is performed
    let onSwipe: (SwipeAction) -> Void
    
    /// State for drag gesture
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    /// Environment values
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Main card content
            cardContent
                .frame(width: 320, height: 420)
                .background(cardBackground)
                .cornerRadius(16)
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            // Swipe direction indicators
            swipeIndicators
        }
        .offset(x: dragOffset.width, y: dragOffset.height * 0.1) // Slight vertical dampening
        .rotationEffect(.degrees(dragOffset.width / 15)) // Rotation based on horizontal drag
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .gesture(swipeGesture)
        .onChange(of: card.offset) { oldValue, newValue in
            // Sync external offset changes
            if !isDragging {
                dragOffset = newValue
            }
        }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Hero image section
            heroImageSection
                .frame(height: 200)
                .clipped()
            
            // Content section  
            VStack(alignment: .leading, spacing: 12) {
                // Title and category
                titleSection
                
                // Distance badge
                distanceBadge
                
                // Description
                descriptionSection
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
    }
    
    // MARK: - Hero Image Section
    
    private var heroImageSection: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    card.category.color.opacity(0.3),
                    card.category.color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Image content
            if let imageURL = card.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    categoryFallbackImage
                }
            } else {
                categoryFallbackImage
            }
            
            // Badge overlays
            VStack {
                HStack {
                    // Replaced indicator (top-left)
                    if card.wasReplaced {
                        replacedIndicator
                            .padding(.top, 12)
                            .padding(.leading, 12)
                    }
                    
                    Spacer()
                    
                    // Category badge (top-right)
                    categoryBadge
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
                Spacer()
            }
        }
    }
    
    private var categoryFallbackImage: some View {
        ZStack {
            // Background with category color
            RoundedRectangle(cornerRadius: 12)
                .fill(card.category.color.opacity(0.2))
            
            // Category icon
            VStack(spacing: 8) {
                Image(systemName: card.category.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(card.category.color)
                
                Text(card.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(card.category.color)
            }
        }
        .padding(20)
    }
    
    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: card.category.icon)
                .font(.caption2)
            Text(card.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.regularMaterial)
        )
        .foregroundColor(.primary)
    }
    
    private var replacedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.caption)
            Text("Ersetzt")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.orange)
        )
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.poi.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if !card.poi.fullAddress.isEmpty {
                Text(card.poi.fullAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Distance Badge
    
    private var distanceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(card.distanceText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            
            Text("•")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(card.walkingTimeText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        Text(card.descriptionText)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Swipe Indicators
    
    private var swipeIndicators: some View {
        HStack {
            // Left indicator (Accept)
            swipeIndicator(
                direction: .left,
                isVisible: dragOffset.width < -SwipeThresholds.directionThreshold
            )
            
            Spacer()
            
            // Right indicator (Reject)  
            swipeIndicator(
                direction: .right,
                isVisible: dragOffset.width > SwipeThresholds.directionThreshold
            )
        }
        .padding(.horizontal, 40)
    }
    
    private func swipeIndicator(direction: SwipeDirection, isVisible: Bool) -> some View {
        ZStack {
            Circle()
                .fill(direction.indicatorColor.opacity(0.9))
                .frame(width: 60, height: 60)
            
            Image(systemName: direction.indicatorIcon)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .scaleEffect(isVisible ? 1.0 : 0.5)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
                
                // Mark card as animating for UI state
                card.isAnimating = true
                
                // Haptic feedback at threshold
                if abs(value.translation.width) > SwipeThresholds.triggerDistance {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
            .onEnded { value in
                isDragging = false
                
                let swipeGesture = SwipeGesture(
                    translation: value.translation,
                    velocity: value.velocity.width
                )
                
                if swipeGesture.shouldAutoComplete || swipeGesture.isTriggerGesture {
                    // Perform swipe action
                    performSwipeAction(gesture: swipeGesture)
                } else {
                    // Bounce back to center
                    bounceBack()
                }
            }
    }
    
    // MARK: - Gesture Actions
    
    private func performSwipeAction(gesture: SwipeGesture) {
        let action: SwipeAction
        
        switch gesture.direction {
        case .left:
            action = .accept(card.poi)
        case .right:
            action = .reject(card.poi)
        case .none:
            // Shouldn't happen with shouldAutoComplete/isTriggerGesture
            bounceBack()
            return
        }
        
        // Animate card exit
        let exitDistance: CGFloat = gesture.direction == .left ? -400 : 400
        
        withAnimation(CardAnimationConfig.removeAnimation) {
            dragOffset = CGSize(width: exitDistance, height: dragOffset.height)
        }
        
        // Haptic feedback for action
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Call completion handler after animation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(action)
        }
    }
    
    private func bounceBack() {
        withAnimation(CardAnimationConfig.returnAnimation) {
            dragOffset = .zero
        }
        
        // Update card state outside animation to avoid conflicts
        card.isAnimating = false
    }
}

// MARK: - Preview

#Preview("Swipe Card - Attraction") {
    @Previewable @State var sampleCard = SwipeCard(
        poi: POI(
            id: "sample_1",
            name: "Nürnberger Burg",
            latitude: 49.4577,
            longitude: 11.0751,
            category: .attraction,
            description: "Eine mittelalterliche Burg auf einem Sandsteinfelsen im Nordwesten der Altstadt von Nürnberg.",
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
        distanceFromOriginal: 250.0,
        category: .attraction,
        wasReplaced: false
    )
    
    VStack {
        SpotSwipeCardView(card: $sampleCard) { action in
            print("Swipe action: \(action)")
        }
        .padding()
        
        Spacer()
        
        // Debug info
        VStack {
            Text("Offset: \(sampleCard.offset.width, specifier: "%.1f")")
            Text("Animating: \(sampleCard.isAnimating ? "Yes" : "No")")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .background(Color(.systemGray6))
}

#Preview("Swipe Card - Museum") {
    @Previewable @State var sampleCard = SwipeCard(
        poi: POI(
            id: "sample_2", 
            name: "Germanisches Nationalmuseum",
            latitude: 49.4481,
            longitude: 11.0661,
            category: .museum,
            description: "Das größte kulturhistorische Museum Deutschlands mit Kunstschätzen aus dem deutschsprachigen Raum.",
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
        distanceFromOriginal: 420.0,
        category: .museum,
        wasReplaced: true // Demo for replaced indicator
    )
    
    SpotSwipeCardView(card: $sampleCard) { action in
        print("Swipe action: \(action)")
    }
    .padding()
    .background(Color(.systemGray6))
}