import SwiftUI

// MARK: - Route Builder View (Next Step)
struct RouteBuilderView: View {
  @Environment(\.dismiss) private var dismiss
  let startingCity: String
  let numberOfPlaces: Int
  let endpointOption: EndpointOption
  let customEndpoint: String
  let routeLength: RouteLength
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  @StateObject private var routeService = RouteService()
  @StateObject private var historyManager = RouteHistoryManager()
  @StateObject private var hereService = HEREAPIService.shared
  
  @State private var discoveredPOIs: [POI] = []
  @State private var isLoadingPOIs = false
  @State private var showPOIDetails = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          if isLoadingPOIs || routeService.isGenerating {
            // Header - only show during generation
            VStack(spacing: 12) {
              Text("Route wird erstellt...")
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("Wir suchen die besten \(numberOfPlaces) Zwischenstopps in \(startingCity)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            
            // Loading State
            VStack(spacing: 16) {
              ProgressView()
                .scaleEffect(1.2)
              
                          Text(isLoadingPOIs ? "Suche nach POIs mit HERE API..." : "Route wird berechnet...")
              .font(.body)
              .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
          } else if let route = routeService.generatedRoute {
            // Success State - Show Generated Route
            VStack(spacing: 20) {
              
              // POI Information Summary
              if !discoveredPOIs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                  Text("Gefundene POIs")
                    .font(.headline)
                    .fontWeight(.semibold)
                  
                  let poisWithCity = discoveredPOIs.filter { $0.address?.city != nil }
                  let cityInfo = poisWithCity.isEmpty ? "keine Stadt-Info verfügbar" : "\(poisWithCity.count)/\(discoveredPOIs.count) mit Stadt-Info"
                  
                  Text("Es wurden \(discoveredPOIs.count) interessante Orte in \(startingCity) gefunden (\(cityInfo)):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                  
                  // Info about limited results
                  if discoveredPOIs.count > 0 {
                    HStack(spacing: 6) {
                      Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                      
                      Text("10 POIs mit nur 1 API-Call - ultraschnell & effizient")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                  }
                  
                  // POI Categories Summary
                  let categoryGroups = Dictionary(grouping: discoveredPOIs) { $0.category }
                  LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                  ], spacing: 8) {
                    ForEach(Array(categoryGroups.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                      HStack(spacing: 6) {
                        Image(systemName: category.icon)
                          .foregroundColor(category.color)
                          .font(.caption)
                        
                        Text("\(categoryGroups[category]?.count ?? 0)x \(category.rawValue)")
                          .font(.caption)
                          .foregroundColor(.secondary)
                      }
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .background(Color(.systemGray6))
                      .cornerRadius(8)
                    }
                  }
                  
                  // Expandable POI Details Button
                  Button(action: {
                    showPOIDetails.toggle()
                  }) {
                    HStack {
                      Text("POI-Details anzeigen")
                        .font(.caption)
                        .fontWeight(.medium)
                      
                      Spacer()
                      
                      Image(systemName: showPOIDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                    }
                    .foregroundColor(.blue)
                  }
                  .padding(.top, 8)
                  
                  // Expandable POI Details
                  if showPOIDetails {
                    VStack(spacing: 12) {
                      ForEach(discoveredPOIs.prefix(5)) { poi in
                        POIDetailView(poi: poi)
                      }
                      
                      if discoveredPOIs.count > 5 {
                        Text("... und \(discoveredPOIs.count - 5) weitere POIs")
                          .font(.caption)
                          .foregroundColor(.secondary)
                          .padding(.vertical, 8)
                      }
                    }
                    .padding(.top, 12)
                  }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
              }
              
              // Waypoints List
              VStack(alignment: .leading, spacing: 12) {
                Text("Route Details")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                  VStack(spacing: 0) {
                    // Waypoint info
                    HStack(spacing: 12) {
                      ZStack {
                        Circle()
                          .fill(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
                          .frame(width: 28, height: 28)
                        
                        if index == 0 {
                          Image(systemName: "figure.walk")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        } else if index == route.waypoints.count - 1 {
                          Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        } else {
                          Image(systemName: waypoint.category.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        }
                      }
                      
                      VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                          Text(waypoint.name)
                            .font(.body)
                            .fontWeight(.medium)
                          
                          // Category indicator (only for intermediate stops)
                          if index > 0 && index < route.waypoints.count - 1 {
                            HStack(spacing: 4) {
                              Text(waypoint.category.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                              Capsule()
                                .fill(waypoint.category.color)
                            )
                          }
                        }
                        
                        Text(waypoint.address)
                          .font(.caption)
                          .foregroundColor(.secondary)
                          .lineLimit(2)
                        
                        // Additional information if available
                        if let phoneNumber = waypoint.phoneNumber {
                          Button(action: {
                            if let phoneURL = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                              UIApplication.shared.open(phoneURL)
                            }
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "phone.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(phoneNumber)
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                          }
                        }
                        
                        if let url = waypoint.url {
                          Button(action: {
                            UIApplication.shared.open(url)
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "link")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(url.host ?? url.absoluteString)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                            }
                          }
                        }
                      }
                      
                      Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                    )
                    
                    // Walking time indicator (if not the last waypoint)
                    if index < route.waypoints.count - 1 {
                      VStack(spacing: 4) {
                        Rectangle()
                          .fill(Color(.systemGray4))
                          .frame(width: 2, height: 20)
                        
                        HStack(spacing: 6) {
                          Image(systemName: "figure.walk")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                          
                          let walkingTime = route.walkingTimes[index]
                          let walkingDistance = route.walkingDistances[index]
                          
                          Text("\(Int(walkingTime / 60)) min • \(Int(walkingDistance)) m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                          Capsule()
                            .fill(Color(.systemGray5))
                        )
                        
                        Rectangle()
                          .fill(Color(.systemGray4))
                          .frame(width: 2, height: 20)
                      }
                    }
                  }
                }
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Route Summary
              VStack(spacing: 12) {
                HStack(spacing: 24) {
                  VStack {
                    Text("\(Int(route.totalDistance / 1000)) km")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Gesamtstrecke")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text(formatExperienceTime(route.totalExperienceTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Gesamtzeit")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text("\(route.numberOfStops)")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Stopps")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Time Breakdown
              VStack(alignment: .leading, spacing: 12) {
                Text("Zeitaufteilung")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("🚶‍♂️ Gehzeit")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalTravelTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.blue)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("📍 Besichtigungszeit")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalVisitTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.orange)
                  }
                }
                
                HStack {
                  Text("⏱️ Gesamte Erlebniszeit:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                  Spacer()
                  Text(formatExperienceTime(route.totalExperienceTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                )
                
                Text("💡 Basiert auf 30-60 Minuten pro Stopp (ohne Start- und Endpunkt)")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.top, 4)
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemGray6))
              )
              
              // Use Route Button
              Button(action: {
                onRouteGenerated(route)
                dismiss()
              }) {
                HStack(spacing: 8) {
                  Image(systemName: "map")
                    .font(.system(size: 18, weight: .medium))
                  Text("Route auf Karte anzeigen")
                    .font(.headline)
                    .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(.blue)
                )
              }
            }
            
          } else if let error = routeService.errorMessage {
            // Error State
            VStack(spacing: 16) {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
              
              Text("Fehler beim Erstellen der Route")
                .font(.headline)
                .fontWeight(.semibold)
              
              Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
              
              Button("Erneut versuchen") {
                Task {
                  await routeService.generateRoute(
                    startingCity: startingCity,
                    numberOfPlaces: numberOfPlaces,
                    endpointOption: endpointOption,
                    customEndpoint: customEndpoint,
                    routeLength: routeLength
                  )
                }
              }
              .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 40)
          }
          
          Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
      }
      .navigationTitle("Route erstellen")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      routeService.setHistoryManager(historyManager)
    }
    .task {
      await loadPOIsAndGenerateRoute()
    }
  }
  
  // MARK: - POI Loading and Route Generation
  
  private func loadPOIsAndGenerateRoute() async {
    do {
      // Step 1: Load POIs from HERE API
      isLoadingPOIs = true
      print("RouteBuilderView: Loading POIs for city '\(startingCity)' using HERE API")
      
      discoveredPOIs = try await hereService.fetchPOIs(
        for: startingCity,
        categories: PlaceCategory.essentialCategories
      )
      
      print("RouteBuilderView: Loaded \(discoveredPOIs.count) POIs from HERE API")
      isLoadingPOIs = false
      
      // Step 2: Generate route using discovered POIs
      await routeService.generateRoute(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength,
        availablePOIs: discoveredPOIs
      )
      
    } catch {
      isLoadingPOIs = false
      print("RouteBuilderView Error: Failed to load POIs from HERE API - \(error.localizedDescription)")
      routeService.errorMessage = "Fehler beim Laden der POIs von HERE API: \(error.localizedDescription)"
    }
  }
}