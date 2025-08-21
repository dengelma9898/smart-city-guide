import SwiftUI

struct ActiveRouteSheetView: View {
  let route: GeneratedRoute
  let onEnd: () -> Void
  let onAddStop: () -> Void
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  
  @State private var showingEndConfirmation = false
  @State private var currentStopIndex = 0 // Track which POI is next
  @State private var showingPOIEditSheet = false
  @State private var showingDeleteConfirmation = false
  @State private var selectedPOIForEdit: RoutePoint?
  @State private var selectedPOIForDelete: (index: Int, waypoint: RoutePoint)?
  @State private var hapticTrigger = false
  
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

              // SwiftUI List for native swipe actions
              let stops = Array(intermediateWaypoints().prefix(6))
              List {
                ForEach(stops.indices, id: \.self) { index in
                  let wp = stops[index]
                  let isNextStop = index == currentStopIndex
                  
                  POIRowView(
                    waypoint: wp,
                    index: index,
                    isNextStop: isNextStop,
                    enrichedPOIs: enrichedPOIs,
                    onEditPOI: { handleEditPOI(at: index, waypoint: wp) },
                    onDeletePOI: { handleDeletePOI(at: index, waypoint: wp) }
                  )
                  .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                  .listRowBackground(Color.clear)
                  .listRowSeparator(.hidden)
                  .accessibilityIdentifier("poi.row.\(index)")
                  
                  // Walking time to next stop as separate list item (if not last)
                  if index < stops.count - 1 {
                    walkingTimeIndicator(for: index)
                      .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
                      .listRowBackground(Color.clear)
                      .listRowSeparator(.hidden)
                  }
                }
              }
              .listStyle(.plain)
              .scrollDisabled(true)
              .frame(height: CGFloat(stops.count * 60 + (stops.count - 1) * 30)) // Approximate height
              .accessibilityIdentifier("activeRoute.pois.list")

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
    .alert("POI löschen", isPresented: $showingDeleteConfirmation) {
      Button("Abbrechen", role: .cancel) { }
      Button("Löschen", role: .destructive) { 
        if let selected = selectedPOIForDelete {
          confirmDeletePOI(at: selected.index, waypoint: selected.waypoint)
        }
      }
    } message: {
      if let selected = selectedPOIForDelete {
        Text("Möchtest du \"\(selected.waypoint.name)\" wirklich aus deiner Tour löschen?")
      }
    }
    .sheet(isPresented: $showingPOIEditSheet) {
      if let selectedPOI = selectedPOIForEdit {
        POIAlternativesSheetView(originalPOI: selectedPOI, enrichedPOIs: enrichedPOIs) { alternativePOI in
          replacePOI(original: selectedPOI, with: alternativePOI)
        }
        .accessibilityIdentifier("poi.alternatives.sheet")
      }
    }
    .sensoryFeedback(.selection, trigger: hapticTrigger)
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
  
  // MARK: - POI Management Actions
  
  private func handleEditPOI(at index: Int, waypoint: RoutePoint) {
    selectedPOIForEdit = waypoint
    showingPOIEditSheet = true
    hapticTrigger.toggle()
  }
  
  private func handleDeletePOI(at index: Int, waypoint: RoutePoint) {
    selectedPOIForDelete = (index: index, waypoint: waypoint)
    showingDeleteConfirmation = true
    hapticTrigger.toggle()
  }
  
  private func confirmDeletePOI(at index: Int, waypoint: RoutePoint) {
    // TODO: Implement actual POI deletion logic
    // This would involve updating the route state and potentially triggering reoptimization
    print("Deleting POI at index \(index): \(waypoint.name)")
    hapticTrigger.toggle()
  }
  
  private func replacePOI(original: RoutePoint, with alternative: RoutePoint) {
    // TODO: Implement POI replacement logic
    // This would involve updating the route and triggering reoptimization
    print("Replacing POI \(original.name) with \(alternative.name)")
    showingPOIEditSheet = false
    hapticTrigger.toggle()
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

// MARK: - POI Row View with Swipe Actions
struct POIRowView: View {
  let waypoint: RoutePoint
  let index: Int
  let isNextStop: Bool
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  let onEditPOI: () -> Void
  let onDeletePOI: () -> Void
  
  var body: some View {
    HStack(spacing: 12) {
      // POI Image oder Index (Real Wikipedia images with fallback)
      if let imageURL = wikipediaImageURL(for: waypoint) ?? mockWikipediaImageURL(for: waypoint),
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
            indexFallback()
          @unknown default:
            indexFallback()
          }
        }
      } else {
        indexFallback()
      }
      
      VStack(alignment: .leading, spacing: 2) {
        Text(waypoint.name)
          .font(isNextStop ? .body.weight(.bold) : .body)
          .foregroundColor(isNextStop ? .primary : .primary)
          .lineLimit(1)
        Text(waypoint.address)
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
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button(action: onDeletePOI) {
        Label("Löschen", systemImage: "trash")
      }
      .tint(.red)
      .accessibilityIdentifier("poi.action.delete")
      
      Button(action: onEditPOI) {
        Label("Bearbeiten", systemImage: "pencil")
      }
      .tint(.blue)
      .accessibilityIdentifier("poi.action.edit")
    }
  }
  
  private func indexFallback() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(isNextStop ? Color.blue.opacity(0.2) : Color(.systemGray5))
        .frame(width: 40, height: 40)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(isNextStop ? .blue : .clear, lineWidth: 2)
        )
      
      Text("\(index + 1)")
        .font(.footnote.weight(isNextStop ? .bold : .medium))
        .foregroundColor(isNextStop ? .blue : .secondary)
    }
  }
  
  private func wikipediaImageURL(for waypoint: RoutePoint) -> String? {
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
}

// MARK: - POI Alternatives Sheet (Placeholder)
struct POIAlternativesSheetView: View {
  let originalPOI: RoutePoint
  let enrichedPOIs: [String: WikipediaEnrichedPOI]
  let onSelectAlternative: (RoutePoint) -> Void
  
  var body: some View {
    NavigationView {
      VStack {
        Text("POI-Alternativen für")
          .font(.headline)
        Text(originalPOI.name)
          .font(.title2)
          .fontWeight(.bold)
        
        Spacer()
        
        // TODO: Implement swipe card view for alternatives
        Text("Hier werden alternative POIs als Swipe-Cards angezeigt")
          .foregroundColor(.secondary)
          .padding()
        
        Button("Alternative auswählen") {
          // Placeholder: select first alternative
          onSelectAlternative(originalPOI)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("poi.alternative.card")
        
        Spacer()
      }
      .navigationTitle("POI ersetzen")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Abbrechen") {
            // Will be handled by parent sheet dismissal
          }
        }
      }
    }
  }
}

