import SwiftUI

// MARK: - Route History View
struct RouteHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyManager: RouteHistoryManager
    @State private var showingDeleteAlert = false
    @State private var routeToDelete: SavedRoute?
    
    var body: some View {
        NavigationView {
            Group {
                if historyManager.savedRoutes.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("Noch keine Routen")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Geplante Routen werden hier automatisch gespeichert")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Route List
                    List {
                        ForEach(historyManager.savedRoutes) { route in
                            NavigationLink(destination: RouteHistoryDetailView(route: route)) {
                                RouteHistoryRowView(route: route)
                            }
                        }
                        .onDelete(perform: deleteRoutes)
                    }
                }
            }
            .navigationTitle("Route-Verlauf")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
                
                if !historyManager.savedRoutes.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button("Verlauf löschen", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Verlauf löschen", isPresented: $showingDeleteAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("Möchten Sie den gesamten Route-Verlauf löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
    
    private func deleteRoutes(offsets: IndexSet) {
        for index in offsets {
            historyManager.deleteRoute(historyManager.savedRoutes[index])
        }
    }
}

// MARK: - Route History Row View
struct RouteHistoryRowView: View {
    let route: SavedRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(route.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(route.formattedDistance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(route.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Route details
            HStack(spacing: 16) {
                // Start -> End
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text(route.startLocation)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let endLocation = route.endLocation {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text(endLocation)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Route type badge
                HStack(spacing: 4) {
                    Text(route.routeTypeDescription)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(route.isRoundtrip ? .blue : .orange)
                )
            }
            
            // Category stats
            if !route.categoryStats.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(route.categoryStats.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                        if let count = route.categoryStats[category], count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(category.color)
                                
                                Text("\(count)")
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(route.numberOfStops) Stopps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Last used indicator
            if let lastUsed = route.lastUsedAt {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("Zuletzt verwendet: \(lastUsed, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        RouteHistoryView()
            .environmentObject(RouteHistoryManager())
    }
}