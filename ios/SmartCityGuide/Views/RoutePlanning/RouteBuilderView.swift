import SwiftUI
import MapKit

// MARK: - Route Builder View (Next Step)
struct RouteBuilderView: View {
  @Environment(\.dismiss) private var dismiss
  let startingCity: String
  let startingCoordinates: CLLocationCoordinate2D? // NEW: Optional coordinates
  let numberOfPlaces: Int
  let endpointOption: EndpointOption
  let customEndpoint: String
  let customEndpointCoordinates: CLLocationCoordinate2D? // NEW: Optional endpoint coordinates
  let routeLength: RouteLength
  let onRouteGenerated: (GeneratedRoute) -> Void
  
  @StateObject private var routeService = RouteService()
  @StateObject private var historyManager = RouteHistoryManager()
  @StateObject private var geoapifyService = GeoapifyAPIService.shared
  
  @State private var discoveredPOIs: [POI] = []
  @State private var isLoadingPOIs = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          if isLoadingPOIs || routeService.isGenerating {
            // Header - only show during generation
            VStack(spacing: 12) {
              Text("Wir basteln deine Route!")
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("Suchen die coolsten \(numberOfPlaces) Stopps in \(startingCity) für dich!")
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
              
                          Text(isLoadingPOIs ? "Entdecke coole Orte..." : "Optimiere deine Route...")
              .font(.body)
              .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
          } else if let route = routeService.generatedRoute {
            // Success State - Show Generated Route
            VStack(spacing: 20) {
              
              // Waypoints List
              VStack(alignment: .leading, spacing: 12) {
                Text("Deine Tour im Detail")
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
                        
                        // E-Mail-Adresse
                        if let email = waypoint.emailAddress {
                          Button(action: {
                            if let emailURL = URL(string: "mailto:\(email)") {
                              UIApplication.shared.open(emailURL)
                            }
                          }) {
                            HStack(spacing: 4) {
                              Image(systemName: "envelope.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                              Text(email)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                            }
                          }
                        }
                        
                        // Öffnungszeiten
                        if let hours = waypoint.operatingHours, !hours.isEmpty {
                          HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                              .font(.system(size: 10))
                              .foregroundColor(.orange)
                            Text(hours)
                              .font(.caption)
                              .foregroundColor(.secondary)
                              .lineLimit(2)
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
                    Text("Deine Strecke")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text(formatExperienceTime(route.totalExperienceTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Deine Zeit")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  VStack {
                    Text("\(route.numberOfStops)")
                      .font(.title3)
                      .fontWeight(.semibold)
                    Text("Coole Stopps")
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
                Text("So sieht's aus")
                  .font(.headline)
                  .fontWeight(.semibold)
                
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("🚶‍♂️ Laufen")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalTravelTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.blue)
                  }
                  
                  Spacer()
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("📍 Entdecken")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text(formatExperienceTime(route.totalVisitTime))
                      .font(.title3)
                      .fontWeight(.semibold)
                      .foregroundColor(.orange)
                  }
                }
                
                HStack {
                  Text("⏱️ Dein ganzes Abenteuer:")
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
                
                Text("💡 Rechnen mit 30-60 Min pro Stopp - ohne Start und Ziel")
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
                  Text("Zeig mir die Tour!")
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
              
              Text("Ups, da lief was schief!")
                .font(.headline)
                .fontWeight(.semibold)
              
              Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
              
              Button("Nochmal probieren!") {
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
      .navigationTitle("Deine Tour entsteht!")
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
      // Step 1: Load POIs from Geoapify API (MIGRATION TESTING: Distance filtering disabled)
      isLoadingPOIs = true
      
      // 🚀 USE DIRECT COORDINATES if available (eliminates geocoding!)
      if let coordinates = startingCoordinates {
                    // Direct coordinates available - skip geocoding
        
        discoveredPOIs = try await geoapifyService.fetchPOIs(
          at: coordinates,
          cityName: startingCity,
          categories: PlaceCategory.geoapifyEssentialCategories
        )
      } else {
                    // No coordinates available - will use geocoding
        
        discoveredPOIs = try await geoapifyService.fetchPOIs(
          for: startingCity,
          categories: PlaceCategory.geoapifyEssentialCategories
        )
      }
      
                // POIs loaded successfully
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
                // Error will be displayed via errorMessage
      routeService.errorMessage = "Konnte keine coolen Orte finden: \(error.localizedDescription)"
    }
  }
}