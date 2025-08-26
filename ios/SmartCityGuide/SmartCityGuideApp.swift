import SwiftUI
import UserNotifications

@main
struct SmartCityGuideApp: App {
  // MARK: - App-Level State
  @StateObject private var appCoordinator = BasicHomeCoordinator()
  @State private var showIntroFlow = !UserDefaults.standard.hasCompletedIntro
  
  var body: some Scene {
    WindowGroup {
      if showIntroFlow {
        IntroFlowView {
          // Called when intro is completed
          withAnimation(.easeInOut(duration: 0.5)) {
            showIntroFlow = false
          }
        }
      } else {
        ContentView()
          .environmentObject(appCoordinator)
          .onAppear {
            setupCacheManager()
            // Note: setupNotificationPermissions() removed - now handled in intro flow
            preloadProfileSettings()
          }
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
  
  /// Legacy notification permissions setup - now handled in intro flow
  /// This method is kept for potential fallback scenarios but not actively called
  private func legacySetupNotificationPermissions() {
    Task {
      // Check current permission status only (no automatic requests)
      await ProximityService.shared.checkNotificationPermission()
    }
  }
  
  /// Preload ProfileSettings beim App-Start für instant availability
  private func preloadProfileSettings() {
    Task {
      // Trigger ProfileSettingsManager initialization früh beim App-Start
      // Das stellt sicher, dass beim ersten Öffnen der RoutePlanningView 
      // die Settings bereits geladen sind
      let settingsManager = ProfileSettingsManager.shared
      
      // Warte bis das Loading abgeschlossen ist
      while settingsManager.isLoading {
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
      }
    }
  }
}