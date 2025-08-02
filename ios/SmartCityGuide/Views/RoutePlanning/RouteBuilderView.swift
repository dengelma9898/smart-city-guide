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
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          if routeService.isGenerating {
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
              
              Text("Route wird berechnet...")
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
          } else if let route = routeService.generatedRoute {
            // Success State - Show Generated Route
            VStack(spacing: 20) {
              
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
    .task {
      await routeService.generateRoute(
        startingCity: startingCity,
        numberOfPlaces: numberOfPlaces,
        endpointOption: endpointOption,
        customEndpoint: customEndpoint,
        routeLength: routeLength
      )
    }
  }
}