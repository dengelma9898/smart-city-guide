import SwiftUI
import UserNotifications

@main
struct SmartCityGuideApp: App {
  // MARK: - App-Level Coordinator
  @StateObject private var appCoordinator = BasicHomeCoordinator()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appCoordinator)
        // Removed .id(UUID()) as it causes view recreation and performance issues
        .onAppear {
          setupCacheManager()
          setupNotificationPermissions()
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
  
  /// Setup notification permissions für POI-Proximity-Benachrichtigungen
  private func setupNotificationPermissions() {
    Task {
      // Check current permission status
      await ProximityService.shared.checkNotificationPermission()
      
      // Delay the permission request a bit to not overwhelm first-time users
      try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
      
      // Only request if still not determined (nicht bei denied/authorized)
      if ProximityService.shared.notificationPermissionStatus == .notDetermined {
        let _ = await ProximityService.shared.requestNotificationPermission()
      }
    }
  }
}