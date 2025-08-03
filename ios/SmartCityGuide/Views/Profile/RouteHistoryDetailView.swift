import SwiftUI

// MARK: - Route History Detail View
struct RouteHistoryDetailView: View {
    let route: SavedRoute
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyManager: RouteHistoryManager
    @State private var showingReuseOptions = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Erstellt am \(route.createdAt, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(route.formattedDistance)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(route.formattedDuration)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Route Type & Length Badges
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: route.isRoundtrip ? "arrow.triangle.2.circlepath" : "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            
                            Text(route.routeTypeDescription)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(route.isRoundtrip ? .blue : .orange)
                        )
                        
                        HStack(spacing: 6) {
                            Image(systemName: "ruler")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            
                            Text(route.routeLengthDescription)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.green)
                        )
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Waypoints List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deine Tour im Detail")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                        VStack(spacing: 0) {
                            // Waypoint Card
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(index == 0 ? .green : (index == route.waypoints.count - 1 ? .red : waypoint.category.color))
                                        .frame(width: 32, height: 32)
                                    
                                    if index == 0 {
                                        Image(systemName: "figure.walk")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if index == route.waypoints.count - 1 {
                                        Image(systemName: "flag.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: waypoint.category.icon)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(waypoint.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        if index > 0 && index < route.waypoints.count - 1 {
                                            Text(waypoint.category.rawValue)
                                                .font(.system(size: 10))
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
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
                                    
                                    // Contact information will be added in future version
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            
                            // Connection line (if not last waypoint)
                            if index < route.waypoints.count - 1 {
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 2, height: 24)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistiken")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(route.numberOfStops)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Coole Stopps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(route.formattedDistance)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Deine Strecke")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(route.formattedDuration)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Deine Zeit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Category breakdown
                    if !route.categoryStats.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategorien")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 12) {
                                ForEach(Array(route.categoryStats.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                                    if let count = route.categoryStats[category], count > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 12))
                                                .foregroundColor(category.color)
                                            
                                            Text("\(count)x \(category.rawValue)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(category.color.opacity(0.1))
                                        )
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Usage Info
                if let lastUsed = route.lastUsedAt {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            
                            Text("Zuletzt erlebt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(lastUsed, style: .relative)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Reuse Route Button
                Button(action: {
                    showingReuseOptions = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Nochmal erleben!")
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
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationTitle("Dein Abenteuer")
        .navigationBarTitleDisplayMode(.inline)
        .actionSheet(isPresented: $showingReuseOptions) {
            ActionSheet(
                title: Text("Route nochmal machen?"),
                message: Text("Wie willst du diese Route nochmal erleben?"),
                buttons: [
                    .default(Text("Genauso nochmal!")) {
                        reuseRoute(withSameSettings: true)
                    },
                    .default(Text("Mit Änderungen")) {
                        reuseRoute(withSameSettings: false)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func reuseRoute(withSameSettings: Bool) {
        historyManager.markRouteAsUsed(route)
        
        // TODO: Implement route reuse functionality
        // This would need to navigate back to RoutePlanningView
        // with pre-filled values from this saved route
        
        dismiss()
    }
    
    // MARK: - Kontakt-Informationen View
    
    @ViewBuilder
    private func contactInfoView(for waypoint: RoutePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Telefonnummer
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
            
            // Website
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
    }
}

#Preview {
    NavigationView {
        RouteHistoryDetailView(route: SavedRoute(
            id: UUID(),
            name: "Berlin Sightseeing",
            startLocation: "Brandenburger Tor",
            endLocation: "Alexanderplatz",
            numberOfStops: 3,
            totalDistance: 5200,
            totalDuration: 7200,
            routeLength: .medium,
            endpointOption: .custom,
            waypoints: [],
            createdAt: Date().addingTimeInterval(-86400),
            lastUsedAt: Date().addingTimeInterval(-3600)
        ))
        .environmentObject(RouteHistoryManager())
    }
}