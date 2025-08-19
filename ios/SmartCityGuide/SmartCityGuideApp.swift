import SwiftUI

@main
struct SmartCityGuideApp: App {
  // MARK: - App-Level Coordinator
  @StateObject private var appCoordinator = BasicHomeCoordinator()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appCoordinator)
        .id(UUID()) // sorgt für frischen Einstieg bei erneutem Öffnen (optional)
        .onAppear {
          setupCacheManager()
        }
    }
  }
  
  /// Initialize cache management on app startup
  private func setupCacheManager() {
    if FeatureFlags.unifiedCacheManagerEnabled {
      Task {
        await CacheManager.shared.loadFromDisk()
        
        // Schedule background maintenance
        if FeatureFlags.automaticCacheMaintenanceEnabled {
          Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { _ in // Every hour
            Task {
              await CacheManager.shared.performMaintenace()
            }
          }
        }
      }
    }
  }
}