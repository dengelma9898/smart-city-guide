import Foundation
import CoreLocation
import UserNotifications
import UIKit
import os.log

// MARK: - Proximity Service for Location-based Notifications
/// Service für standortbasierte Benachrichtigungen bei Route-Spots
/// Überwacht GPS-Position und triggert Notifications bei Annäherung (25m Radius)
@MainActor
class ProximityService: NSObject, ObservableObject {
    static let shared = ProximityService()
    
    // MARK: - Published Properties
    @Published var isActive = false
    @Published var visitedSpots: Set<String> = []
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Proximity")
    private let proximityThreshold: CLLocationDistance = 25.0 // 25 meters
    private var activeRoute: GeneratedRoute?
    private var locationService = LocationManagerService.shared
    private var settingsManager = ProfileSettingsManager.shared

    
    override init() {
        super.init()
        setupNotificationCenter()
        setupSettingsObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .poiNotificationSettingChanged, object: nil)
    }
    
    // MARK: - Notification Permission Setup
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.notificationPermissionStatus = granted ? .authorized : .denied
            }
            
            logger.info("📢 Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("❌ Notification permission error: \(error)")
            await MainActor.run {
                self.notificationPermissionStatus = .denied
            }
            return false
        }
    }
    
    func checkNotificationPermission() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.notificationPermissionStatus = settings.authorizationStatus
        }
    }
    
    // MARK: - Active Route Management
    /// Startet Proximity Monitoring für eine aktive Route
    /// Fordert Notification + Location Permissions an und aktiviert Background Location
    func startProximityMonitoring(for route: GeneratedRoute) async {
        logger.info("🎯 Starting proximity monitoring for route with \(route.waypoints.count) spots")
        
        // Log current settings state
        if !shouldTriggerNotifications {
            logger.info("⚙️ POI notifications are disabled in settings - monitoring will track visits but skip notifications")
        }
        
        // Check notification permission first
        await checkNotificationPermission()
        
        if notificationPermissionStatus == .notDetermined {
            let granted = await requestNotificationPermission()
            if !granted {
                logger.warning("⚠️ Proximity monitoring without notifications - permission denied")
            }
        }
        
        activeRoute = route
        visitedSpots.removeAll()
        isActive = true
        
        // Offer Always Permission for Background Notifications
        await requestBackgroundLocationIfNeeded()
        
        // Start background location monitoring
        await startBackgroundLocationMonitoring()
    }
    
    func stopProximityMonitoring() {
        logger.info("⏹️ Stopping proximity monitoring")
        isActive = false
        activeRoute = nil
        visitedSpots.removeAll()
        
        // Stop background location updates
        locationService.stopBackgroundLocationUpdates()
    }
    
    // MARK: - Location Monitoring
    private func startLocationMonitoring() async {
        // Check if location is authorized
        guard locationService.isLocationAuthorized else {
            logger.warning("⚠️ Location not authorized for proximity monitoring")
            return
        }
        
        // Start monitoring user location changes
        // This will be triggered by LocationManagerService location updates
        logger.info("📍 Location monitoring active for proximity detection")
    }
    
    // MARK: - Background Location Methods
    private func requestBackgroundLocationIfNeeded() async {
        // Only ask for Always permission if user has POI notifications enabled in settings
        guard shouldTriggerNotifications else {
            logger.info("📱 Skipping Always location request - POI notifications disabled in settings")
            return
        }
        
        // Only ask for Always permission if user has notifications enabled
        guard notificationPermissionStatus == .authorized else {
            logger.info("📱 Skipping Always location request - notification permission not granted")
            return
        }
        
        // Only ask if not already Always
        guard locationService.authorizationStatus != .authorizedAlways else {
            logger.info("🌙 Always location permission already granted")
            await checkBackgroundAppRefresh()
            return
        }
        
        // For now, just request Always permission automatically
        // In production, you might want to show a user dialog first
        logger.info("📍 Requesting Always location permission for background notifications...")
        Task {
            await locationService.requestAlwaysLocationPermission()
        }
    }
    
    private func checkBackgroundAppRefresh() async {
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        
        switch backgroundRefreshStatus {
        case .available:
            logger.info("✅ Background App Refresh available")
        case .denied:
            logger.warning("❌ Background App Refresh denied - background notifications may not work")
        case .restricted:
            logger.warning("⚠️ Background App Refresh restricted")
        @unknown default:
            logger.warning("❓ Unknown Background App Refresh status")
        }
    }
    
    private func startBackgroundLocationMonitoring() async {
        // Check if location is authorized
        guard locationService.isLocationAuthorized else {
            logger.warning("⚠️ Location not authorized for background monitoring")
            return
        }
        
        // Start background location updates
        locationService.startBackgroundLocationUpdates()
        
        if locationService.authorizationStatus == .authorizedAlways {
            logger.info("🌙 Background location monitoring started with Always permission")
        } else {
            logger.info("📱 Foreground location monitoring started (upgrade to Always for background notifications)")
        }
    }
    
    // MARK: - Proximity Detection
    func checkProximityToSpots() async {
        guard isActive,
              let route = activeRoute,
              let userLocation = locationService.currentLocation else {
            return
        }
        
        for waypoint in route.waypoints {
            let spotId = generateSpotId(for: waypoint)
            
            // Skip if already visited
            if visitedSpots.contains(spotId) {
                continue
            }
            
            let spotLocation = CLLocation(
                latitude: waypoint.coordinate.latitude,
                longitude: waypoint.coordinate.longitude
            )
            
            let distance = userLocation.distance(from: spotLocation)
            
            if distance <= proximityThreshold {
                await triggerSpotNotification(for: waypoint, distance: distance)
                visitedSpots.insert(spotId)
                logger.info("✅ Spot visited: \(waypoint.name) at \(String(format: "%.1f", distance))m")
            }
        }
    }
    
    // MARK: - Notification Triggering
    private func triggerSpotNotification(for waypoint: RoutePoint, distance: CLLocationDistance) async {
        // Check if POI notifications are enabled in settings
        guard shouldTriggerNotifications else {
            logger.info("📢 POI notification for \(waypoint.name) skipped - disabled in settings")
            return
        }
        
        guard notificationPermissionStatus == .authorized else {
            logger.info("📢 Would trigger notification for \(waypoint.name) but permission not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Spot erreicht!"
        content.body = "Du bist bei \(waypoint.name) angekommen! Schau dich um und entdecke was Neues."
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "spotName": waypoint.name,
            "spotCoordinates": [
                "latitude": waypoint.coordinate.latitude,
                "longitude": waypoint.coordinate.longitude
            ],
            "distance": distance,
            "category": waypoint.category.rawValue
        ]
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "spot_\(waypoint.name)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("📢 Notification triggered for: \(waypoint.name)")
        } catch {
            logger.error("❌ Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Notification Center Setup
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
    }
    
    // MARK: - Settings Integration
    private func setupSettingsObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .poiNotificationSettingChanged,
            object: nil
        )
    }
    
    @objc private func handleSettingsChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let enabled = userInfo["enabled"] as? Bool else {
            return
        }
        
        logger.info("⚙️ POI notification setting changed to: \(enabled)")
        
        // If notifications are disabled while monitoring is active, gracefully handle
        if !enabled && isActive {
            logger.info("📢 POI notifications disabled during active monitoring - notifications will be skipped")
        }
    }
    
    /// Checks if POI notifications should be triggered based on user settings
    private var shouldTriggerNotifications: Bool {
        return settingsManager.settings.poiNotificationsEnabled
    }
    
    // MARK: - Utility Methods
    func getActiveRouteProgress() -> (visited: Int, total: Int) {
        guard let route = activeRoute else { return (0, 0) }
        return (visitedSpots.count, route.waypoints.count)
    }
    
    func isSpotVisited(_ waypoint: RoutePoint) -> Bool {
        let spotId = generateSpotId(for: waypoint)
        return visitedSpots.contains(spotId)
    }
    
    /// Generiert eine konsistente ID für einen RoutePoint
    private func generateSpotId(for waypoint: RoutePoint) -> String {
        return "\(waypoint.name)_\(waypoint.coordinate.latitude)_\(waypoint.coordinate.longitude)"
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension ProximityService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            if let spotName = userInfo["spotName"] as? String {
                self.logger.info("📱 User tapped notification for: \(spotName)")
                // Could navigate to spot detail or route view here
            }
        }
        
        completionHandler()
    }
}