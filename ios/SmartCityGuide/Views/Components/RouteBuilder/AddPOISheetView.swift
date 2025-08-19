import SwiftUI
import MapKit

/// Sheet for adding new POIs to existing route with swipe card interface
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
  
  var body: some View {
    NavigationView {
      ZStack {
        // Background styling aligned with edit view
        LinearGradient(
          gradient: Gradient(colors: [
            Color(.systemBackground),
            Color(.systemGray6).opacity(0.3)
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
          let availablePOIs: [POI] = discoveredPOIs.filter { poi in
            !isAlreadyInRoute(poi)
          }
          
          if !availablePOIs.isEmpty {
            let referenceWaypoint: RoutePoint = {
              // Referenzpunkt nur für Distanzanzeige in Karten
              if route.waypoints.count > 1 {
                return route.waypoints[route.waypoints.count - 2] // letzter Zwischenstopp, falls vorhanden
              }
              return route.waypoints.first ?? RoutePoint(
                name: startingCity,
                coordinate: startingCoordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                address: startingCity,
                category: .attraction
              )
            }()
            
            // Main card area with similar sizing/margins as edit view
            SwipeCardStackView(
              pois: availablePOIs,
              enrichedData: enrichedPOIs,
              originalWaypoint: referenceWaypoint,
              onCardAction: { action in
                switch action {
                case .accept(let poi):
                  if !selectedPOIs.contains(where: { $0.id == poi.id }) {
                    selectedPOIs.append(poi)
                  }
                case .reject(_):
                  break
                case .skip:
                  break
                }
              },
              onStackEmpty: {
                // Nutzer kann über „Fertig" schließen; hier nichts erzwingen
              },
              onTopCardChanged: { top in
                topCard = top
              }
            )
            .accessibilityIdentifier("route.add-poi.sheet.swipe")
            .frame(maxHeight: 420)
            
            // Manual action bar styled like in edit view (red/green)
            HStack(spacing: 24) {
              // Reject/Skip
              Button(action: {
                if let top = topCard {
                  NotificationCenter.default.post(name: .manualCardExit, object: nil, userInfo: [
                    "cardId": top.id.uuidString,
                    "direction": "right"
                  ])
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    NotificationCenter.default.post(name: .manualCardRemoval, object: nil)
                  }
                }
              }) {
                VStack(spacing: 8) {
                  Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                  Text("Überspringen")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                }
              }
              .buttonStyle(PlainButtonStyle())
              .accessibilityIdentifier("route.add-poi.swipe.skip")
              
              Spacer()
              
              // Accept/Like
              Button(action: {
                if let top = topCard {
                  NotificationCenter.default.post(name: .manualCardExit, object: nil, userInfo: [
                    "cardId": top.id.uuidString,
                    "direction": "left"
                  ])
                  if !selectedPOIs.contains(where: { $0.id == top.poi.id }) {
                    selectedPOIs.append(top.poi)
                  }
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    NotificationCenter.default.post(name: .manualCardRemoval, object: nil)
                  }
                }
              }) {
                VStack(spacing: 8) {
                  Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                  Text("Nehmen")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
              }
              .buttonStyle(PlainButtonStyle())
              .accessibilityIdentifier("route.add-poi.swipe.like")
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )

            // Freundlicher CTA zur vollständigen Optimierung (TSP)
            if !selectedPOIs.isEmpty {
              Button {
                Task { await onOptimize() }
              } label: {
                HStack(spacing: 8) {
                  Image(systemName: "wand.and.stars")
                  Text("Jetzt optimieren")
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)
              .controlSize(.large)
              .padding(.bottom, 12)
              .accessibilityIdentifier("route.add-poi.cta.optimize")
            }
          } else {
            VStack(spacing: 12) {
              Text("Keine weiteren Orte zum Hinzufügen gefunden.")
                .font(.body)
                .foregroundColor(.secondary)
              Button("Schließen", action: onDismiss)
                .buttonStyle(.bordered)
            }
            .padding()
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
      }
      .navigationTitle("Neue Stopps entdecken")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Abbrechen", action: onDismiss)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          if !selectedPOIs.isEmpty {
            Text("Hinzugefügt: \(selectedPOIs.count)")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }
}
