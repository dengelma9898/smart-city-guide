import SwiftUI

/// Debug view for monitoring cache performance and statistics
struct CacheDebugView: View {
    @StateObject private var cacheManager = CacheManager.shared
    @State private var cacheStats: CacheStatistics?
    @State private var cacheInfo: [String: Any] = [:]
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                // Route Cache Section
                Section("Route Cache") {
                    if let stats = cacheStats {
                        CacheStatRow(title: "Cache Size", value: "\(stats.routeCache.cacheSize) routes")
                        CacheStatRow(title: "Cache Hits", value: "\(stats.routeCache.cacheHits)")
                        CacheStatRow(title: "Cache Misses", value: "\(stats.routeCache.cacheMisses)")
                        CacheStatRow(title: "Hit Rate", value: String(format: "%.1f%%", stats.routeCache.hitRate * 100))
                        CacheStatRow(title: "API Calls Saved", value: "~\(stats.estimatedAPICallsSaved)")
                        CacheStatRow(title: "Total Distance", value: String(format: "%.1f km", stats.routeCache.totalDistance / 1000))
                        CacheStatRow(title: "Total Travel Time", value: String(format: "%.1f hours", stats.routeCache.totalTravelTime / 3600))
                    }
                }
                
                // POI Cache Section
                Section("POI Cache") {
                    if let stats = cacheStats {
                        CacheStatRow(title: "Cities Cached", value: "\(stats.poiCacheSize)")
                        CacheStatRow(title: "Total POIs", value: "\(stats.poiTotalCount)")
                    }
                }
                
                // Disk Cache Section
                Section("Disk Cache") {
                    if let stats = cacheStats {
                        CacheStatRow(title: "Files", value: "\(stats.diskCache.fileCount)")
                        CacheStatRow(title: "Total Size", value: stats.diskCache.formattedSize)
                        CacheStatRow(title: "Max Size", value: stats.diskCache.formattedMaxSize)
                        CacheStatRow(title: "Usage", value: String(format: "%.1f%%", stats.diskCache.usagePercentage))
                        
                        // Show directory path (useful for debugging)
                        if !stats.diskCache.cacheDirectory.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cache Directory")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(stats.diskCache.cacheDirectory)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                }
                
                // Actions Section
                Section("Cache Actions") {
                    Button("Refresh Statistics") {
                        refreshStats()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Force Cache Maintenance") {
                        performMaintenance()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Clear All Caches") {
                        clearAllCaches()
                    }
                    .foregroundColor(.red)
                }
                
                // Raw Cache Info (for debugging)
                Section("Debug Info") {
                    DisclosureGroup("Raw Cache Data") {
                        ForEach(Array(cacheInfo.keys.sorted()), id: \.self) { key in
                            if let value = cacheInfo[key] {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(key)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("\(value)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cache Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Refresh") {
                            refreshStats()
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshStats()
        }
    }
    
    private func refreshStats() {
        isLoading = true
        Task {
            let stats = await cacheManager.getCacheStatistics()
            let info = await cacheManager.getCacheInfo()
            
            await MainActor.run {
                self.cacheStats = stats
                self.cacheInfo = info
                self.isLoading = false
            }
        }
    }
    
    private func performMaintenance() {
        isLoading = true
        Task {
            await cacheManager.performMaintenace()
            refreshStats()
        }
    }
    
    private func clearAllCaches() {
        isLoading = true
        Task {
            await cacheManager.clearAllCaches()
            refreshStats()
        }
    }
}

struct CacheStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

#if DEBUG
struct CacheDebugView_Previews: PreviewProvider {
    static var previews: some View {
        CacheDebugView()
    }
}
#endif
