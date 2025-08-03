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
                    // Enhanced Empty State
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                            
                            VStack(spacing: 8) {
                                Text("Noch kein Abenteuer erlebt!")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Deine Touren werden hier automatisch gespeichert - leg einfach los!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        
                        VStack(spacing: 12) {
                            Text("💡 Tipp:")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Plane deine erste Tour und erkunde deine Stadt wie nie zuvor!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Enhanced Route List
                    List {
                        // Summary Header
                        Section {
                            VStack(spacing: 12) {
                                HStack(spacing: 20) {
                                    VStack(spacing: 4) {
                                        Text("\(historyManager.savedRoutes.count)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("Abenteuer")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(totalDistanceAll)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        Text("km gelaufen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Routes List
                        Section("Deine Touren") {
                            ForEach(historyManager.savedRoutes) { route in
                                NavigationLink(destination: RouteHistoryDetailView(route: route)) {
                                    RouteHistoryRowView(route: route)
                                }
                            }
                            .onDelete(perform: deleteRoutes)
                        }
                    }
                    .listStyle(.grouped)
                }
            }
            .navigationTitle("Deine Abenteuer")
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
                            Button("Alles löschen", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Alles weg?", isPresented: $showingDeleteAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("Willst du wirklich alle deine Abenteuer löschen? Das kann nicht rückgängig gemacht werden!")
            }
        }
    }
    
    private func deleteRoutes(offsets: IndexSet) {
        for index in offsets {
            historyManager.deleteRoute(historyManager.savedRoutes[index])
        }
    }
    
    private var totalDistanceAll: String {
        let total = historyManager.savedRoutes.reduce(0) { $0 + $1.totalDistance }
        return String(format: "%.1f", total / 1000)
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
                    
                    Text("\(route.numberOfStops) coole Stopps")
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
                    
                    Text("Zuletzt: \(lastUsed, style: .relative)")
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