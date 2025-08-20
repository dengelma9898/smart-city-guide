import SwiftUI

struct ActiveRouteSheetView: View {
  let route: GeneratedRoute
  let onEnd: () -> Void
  let onAddStop: () -> Void
  let enrichedPOIs: [String: WikipediaEnrichedPOI]?
  
  @State private var showingEndConfirmation = false
  @State private var currentStopIndex = 0 // Track which POI is next
  
  var body: some View {
    GeometryReader { proxy in
      let height = proxy.size.height
      
      VStack(spacing: 0) {
        // Handle indicator with proper spacing
        RoundedRectangle(cornerRadius: 2.5)
          .fill(Color.secondary.opacity(0.3))
          .frame(width: 36, height: 5)
          .padding(.top, 8)
          .padding(.bottom, 16)
        
        ScrollView(showsIndicators: false) {
          VStack(spacing: 12) {
            // Collapsed summary row
            HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
              Text(summaryLine)
                .font(.subheadline)
                .fontWeight(.medium)
              Text("\(route.numberOfStops) Stopps")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { showingEndConfirmation = true }) {
              HStack(spacing: 6) {
                Image(systemName: "stop.fill")
                  .font(.system(size: 14, weight: .medium))
                Text("Tour beenden")
                  .font(.subheadline)
                  .fontWeight(.medium)
              }
              .foregroundColor(.white)
              .padding(.horizontal, 14)
              .padding(.vertical, 10)
              .background(RoundedRectangle(cornerRadius: 18).fill(Color.red))
            }
            .accessibilityIdentifier("activeRoute.action.end")
          }
          .padding(.horizontal, 20)
          .padding(.top, 4)
          .padding(.bottom, height >= 220 ? 8 : 16)
          .accessibilityIdentifier("activeRoute.sheet.collapsed")

          // Medium & Large content (appears as soon as there is enough height)
          if height >= 220 {
            VStack(alignment: .leading, spacing: 10) {
              Text("Nächste Stopps")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

              VStack(spacing: 8) {
                let stops = Array(intermediateWaypoints().prefix(6))
                ForEach(stops.indices, id: \.self) { index in
                  let wp = stops[index]
                  let isNextStop = index == currentStopIndex
                  
                  VStack(spacing: 0) {
                    // POI Row
                    HStack(spacing: 12) {
                      // POI Image oder Index
                      if let imageURL = mockWikipediaImageURL(for: wp),
                         let url = URL(string: imageURL) {
                        AsyncImage(url: url) { imagePhase in
                          switch imagePhase {
                          case .success(let image):
                            image
                              .resizable()
                              .aspectRatio(contentMode: .fill)
                              .frame(width: 40, height: 40)
                              .clipShape(RoundedRectangle(cornerRadius: 8))
                              .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                  .stroke(isNextStop ? .blue : .clear, lineWidth: 2)
                              )
                          case .failure(_), .empty:
                            indexFallback(index: index + 1, isNext: isNextStop)
                          @unknown default:
                            indexFallback(index: index + 1, isNext: isNextStop)
                          }
                        }
                      } else {
                        indexFallback(index: index + 1, isNext: isNextStop)
                      }
                      
                      VStack(alignment: .leading, spacing: 2) {
                        Text(wp.name)
                          .font(isNextStop ? .body.weight(.bold) : .body)
                          .foregroundColor(isNextStop ? .primary : .primary)
                          .lineLimit(1)
                        Text(wp.address)
                          .font(.caption2)
                          .foregroundColor(.secondary)
                          .lineLimit(1)
                      }
                      
                      Spacer()
                      
                      if isNextStop {
                        Image(systemName: "arrow.right.circle.fill")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(.blue)
                      } else {
                        Image(systemName: "chevron.right")
                          .font(.system(size: 12, weight: .semibold))
                          .foregroundColor(.secondary)
                      }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                      RoundedRectangle(cornerRadius: 10)
                        .fill(isNextStop ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    )
                    
                    // Walking time to next stop
                    if index < stops.count - 1 {
                      walkingTimeIndicator(for: index)
                    }
                  }
                }
              }

              HStack {
                Spacer()
                Button(action: onAddStop) {
                  HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .semibold))
                    Text("Stopp hinzufügen").font(.body).fontWeight(.medium)
                  }
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.15)))
                }
                .accessibilityIdentifier("activeRoute.action.addStop")
              }
              .padding(.horizontal, 16)
              .padding(.top, 4)
              .padding(.bottom, 8)
            }
          }
          }
          .padding(.bottom, 8)
        }
        .background(Color.clear)
      }
    }
    .accessibilityIdentifier("ActiveRouteSheetView")
    .alert("Tour wirklich beenden?", isPresented: $showingEndConfirmation) {
      Button("Abbrechen", role: .cancel) { }
      Button("Beenden", role: .destructive) { onEnd() }
    } message: {
      Text("Deine aktuelle Tour wird geschlossen. Das kannst du nicht rückgängig machen.")
    }
  }
  
  private var summaryLine: String {
    let km = max(1, Int(route.totalDistance / 1000))
    let time = formatDuration(route.totalExperienceTime)
    return "\(km) km • \(time)"
  }
  
  private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds / 60)
    if minutes < 60 { return "\(minutes) min" }
    let hours = minutes / 60
    let remMin = minutes % 60
    return remMin == 0 ? "\(hours) h" : "\(hours) h \(remMin) min"
  }

  private func intermediateWaypoints() -> [RoutePoint] {
    let wps = route.waypoints
    guard wps.count > 2 else { return [] }
    return Array(wps.dropFirst().dropLast())
  }
  
  // MARK: - Helper Views & Functions
  
  private func indexFallback(index: Int, isNext: Bool) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(isNext ? Color.blue.opacity(0.2) : Color(.systemGray5))
        .frame(width: 40, height: 40)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(isNext ? .blue : .clear, lineWidth: 2)
        )
      
      Text("\(index)")
        .font(.footnote.weight(isNext ? .bold : .medium))
        .foregroundColor(isNext ? .blue : .secondary)
    }
  }
  
  private func wikipediaImageURL(for waypoint: RoutePoint) -> String? {
    guard let enrichedPOIs = enrichedPOIs else { return nil }
    
    // Find enriched POI by name match
    let matchingPOI = enrichedPOIs.values.first { enrichedPOI in
      enrichedPOI.basePOI.name.lowercased() == waypoint.name.lowercased() ||
      enrichedPOI.basePOI.name.contains(waypoint.name) ||
      waypoint.name.contains(enrichedPOI.basePOI.name)
    }
    
    return matchingPOI?.wikipediaImageURL
  }
  
  // Mock Wikipedia images for demonstration
  private func mockWikipediaImageURL(for waypoint: RoutePoint) -> String? {
    // Use Unsplash for demo images based on category
    let seed = waypoint.name.lowercased().replacingOccurrences(of: " ", with: "")
    
    switch waypoint.category {
    case .attraction:
      return "https://picsum.photos/seed/\(seed)/300/300"
    case .museum:
      return "https://picsum.photos/seed/museum\(seed)/300/300"
    case .park:
      return "https://picsum.photos/seed/park\(seed)/300/300"
    case .nationalPark:
      return "https://picsum.photos/seed/nature\(seed)/300/300"
    @unknown default:
      return "https://picsum.photos/seed/default\(seed)/300/300"
    }
  }
  
  private func walkingTimeIndicator(for index: Int) -> some View {
    HStack(spacing: 8) {
      // Connecting line
      Rectangle()
        .fill(Color(.systemGray4))
        .frame(width: 2, height: 16)
        .offset(x: 26) // Align with POI images/icons
      
      // Walking time info
      HStack(spacing: 6) {
        Image(systemName: "figure.walk")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.secondary)
        
        if index < route.walkingTimes.count && index < route.walkingDistances.count {
          let walkingTime = route.walkingTimes[index]
          let walkingDistance = route.walkingDistances[index]
          Text("\(Int(walkingTime / 60)) min • \(Int(walkingDistance)) m")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundColor(.secondary)
        } else {
          Text("~5 min • ~300 m")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundColor(.secondary)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        Capsule()
          .fill(Color(.systemGray6))
      )
      
      Spacer()
    }
    .padding(.top, 4)
  }
}


