import SwiftUI
import MapKit

/// Displays the generated route as a list with waypoints, summary, and action button
struct RouteListView: View {
  let route: GeneratedRoute
  let endpointOption: EndpointOption
  let customEndpoint: String
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  let isEnrichingAllPOIs: Bool
  let enrichmentProgress: Double
  
  let onRouteStart: () -> Void
  let onWaypointEdit: (Int) -> Void
  let onWaypointDelete: (Int) async -> Void
  let onWikipediaImageTap: (String, String, String) -> Void
  
  var body: some View {
    List {
      // Waypoints Section
      Section {
        ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
          Group {
            RouteWaypointRowView(
              route: route,
              index: index,
              waypoint: waypoint,
              endpointOption: endpointOption,
              customEndpoint: customEndpoint,
              enrichedPOIs: enrichedPOIs,
              onWikipediaImageTap: onWikipediaImageTap
            )
            .listRowBackground(Color(.systemGray6))
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              if index > 0 && index < route.waypoints.count - 1 {
                Button("Bearbeiten") { onWaypointEdit(index) }
                  .tint(.blue)
                Button(role: .destructive) {
                  Task { await onWaypointDelete(index) }
                } label: {
                  Text("Löschen")
                }
                .accessibilityIdentifier("route.delete-poi.action.\(index)")
              }
            }
            if index < route.waypoints.count - 1 {
              RouteWalkingRowView(route: route, index: index)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
          }
        }
      }

      // Route Summary Section
      Section {
        VStack(spacing: 12) {
          HStack(spacing: 24) {
            VStack {
              Text("\(Int(route.totalDistance / 1000)) km").font(.title3).fontWeight(.semibold)
              Text("Deine Strecke").font(.caption).foregroundColor(.secondary)
            }
            VStack {
              Text(formatExperienceTime(route.totalExperienceTime)).font(.title3).fontWeight(.semibold)
              Text("Deine Zeit").font(.caption).foregroundColor(.secondary)
            }
            VStack {
              Text("\(route.numberOfStops)").font(.title3).fontWeight(.semibold)
              Text("Coole Stopps").font(.caption).foregroundColor(.secondary)
            }
          }
        }
        .listRowBackground(Color(.systemGray6))
      }

      // Time Breakdown Section
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Text("So sieht's aus").font(.headline).fontWeight(.semibold)
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("🚶‍♂️ Laufen").font(.subheadline).fontWeight(.medium)
              Text(formatExperienceTime(route.totalTravelTime)).font(.title3).fontWeight(.semibold).foregroundColor(.blue)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
              Text("📍 Entdecken").font(.subheadline).fontWeight(.medium)
              Text(formatExperienceTime(route.totalVisitTime)).font(.title3).fontWeight(.semibold).foregroundColor(.orange)
            }
          }
          HStack {
            Text("⏱️ Dein ganzes Abenteuer:").font(.subheadline).fontWeight(.medium)
            Spacer()
            Text(formatExperienceTime(route.totalExperienceTime)).font(.title2).fontWeight(.bold).foregroundColor(.green)
          }
          .padding(.top, 8)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.1)))
          Text("💡 Rechnen mit 30-60 Min pro Stopp - ohne Start und Ziel").font(.caption).foregroundColor(.secondary).padding(.top, 4)
        }
        .listRowBackground(Color(.systemGray6))
      }

      // Background Enrichment Status Section
      if isEnrichingAllPOIs {
        Section {
          VStack(spacing: 8) {
            HStack(spacing: 8) {
              ProgressView().scaleEffect(0.8)
              Text("Wikipedia-Daten für weitere POIs werden im Hintergrund geladen...").font(.caption).foregroundColor(.secondary)
              Spacer()
            }
            ProgressView(value: enrichmentProgress).tint(.blue).scaleEffect(y: 0.8)
            Text("\(Int(enrichmentProgress * 100))% abgeschlossen").font(.caption2).foregroundColor(.secondary)
          }
        }
      }

      // Action Section
      Section {
        Button(action: onRouteStart) {
          HStack(spacing: 8) {
            Image(systemName: "map").font(.system(size: 18, weight: .medium))
            Text("Zeig mir die Tour!").font(.headline).fontWeight(.medium)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(RoundedRectangle(cornerRadius: 12).fill(.blue))
        }
        .accessibilityIdentifier("route.start.button")
        .accessibilityLabel("Zeig mir die Tour!")
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
  }
  
  // MARK: - Helper Functions
  
  private func formatExperienceTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = (Int(timeInterval) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)min"
    } else {
      return "\(minutes) min"
    }
  }
}
