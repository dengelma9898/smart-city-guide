import SwiftUI
import CoreLocation

// MARK: - POI Selection Stack View (Deprecated Wrapper)
struct POISelectionStackView: View {
    // BINDING DATA
    @Binding var availablePOIs: [POI]
    @ObservedObject var selection: ManualPOISelection
    let enrichedPOIs: [String: WikipediaEnrichedPOI]
    let onSelectionComplete: () -> Void
    
    var body: some View {
        // Delegate to UnifiedSwipeView to avoid duplication
        UnifiedSwipeView(
            configuration: .manual,
            availablePOIs: availablePOIs,
            enrichedPOIs: enrichedPOIs,
            selection: selection,
            onSelectionComplete: onSelectionComplete,
            onDismiss: {}
        )
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