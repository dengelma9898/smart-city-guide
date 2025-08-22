import SwiftUI
import MapKit

/// Sheet for adding new POIs to existing route with unified swipe interface
struct AddPOISheetView: View {
  let route: GeneratedRoute
  let discoveredPOIs: [POI]
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  let startingCity: String
  let startingCoordinates: CLLocationCoordinate2D?
  
  @Binding var selectedPOIs: [POI]
  @Binding var topCard: SwipeCard?
  
  let isAlreadyInRoute: (POI) -> Bool
  let onOptimize: () async -> Void
  let onDismiss: () -> Void
  
  // Local state for UnifiedSwipeView
  @StateObject private var addPOISelection = ManualPOISelection()
  
  var body: some View {
    NavigationView {
      let availablePOIs: [POI] = discoveredPOIs.filter { poi in
        !isAlreadyInRoute(poi)
      }
      
      if !availablePOIs.isEmpty {
        UnifiedSwipeView(
          configuration: .addPOI,
          availablePOIs: availablePOIs,
          enrichedPOIs: enrichedPOIs,
          selection: addPOISelection,
          onSelectionComplete: {
            // Transfer selections to binding and trigger optimization
            selectedPOIs.append(contentsOf: addPOISelection.selectedPOIs)
            
            Task {
              await onOptimize()
              onDismiss()
            }
          },
          onDismiss: onDismiss
        )
      } else {
        // Empty state when no POIs available
        VStack(spacing: 20) {
          Image(systemName: "location.slash")
            .font(.system(size: 64))
            .foregroundColor(.secondary)
          
          VStack(spacing: 8) {
            Text("Keine neuen POIs verfügbar")
              .font(.title2)
              .fontWeight(.semibold)
            
            Text("Alle entdeckten POIs sind bereits in deiner Route enthalten.")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
        }
        .padding()
      }
    }
    .navigationTitle("POIs hinzufügen")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Abbrechen", action: onDismiss)
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        if addPOISelection.hasSelections {
          Text("Hinzugefügt: \(addPOISelection.selectedPOIs.count)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .accessibilityIdentifier("route.add-poi.sheet")
    .onAppear {
      // Clear any existing selections when sheet appears
      addPOISelection.reset()
    }
  }
}