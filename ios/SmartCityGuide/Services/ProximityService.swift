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
    private var routeCompletionTriggered = false

    
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
        logger.info("🗺️ Route waypoints:")
        for (index, waypoint) in route.waypoints.enumerated() {
            logger.info("  \(index + 1). \(waypoint.name) at \(waypoint.coordinate.latitude), \(waypoint.coordinate.longitude)")
        }
        
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
        routeCompletionTriggered = false // Reset completion flag for new route
        isActive = true
        
        logger.info("✅ ProximityService activated - isActive: \(self.isActive), hasRoute: \(self.activeRoute != nil)")
        
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
        routeCompletionTriggered = false // Reset completion flag
        
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
        // Always permission requests now handled in intro flow
        // Only check for existing permissions and setup background monitoring
        
        guard shouldTriggerNotifications else {
            logger.info("📱 POI notifications disabled in settings - background monitoring disabled")
            return
        }
        
        guard notificationPermissionStatus == .authorized else {
            logger.info("📱 Notification permission not granted - background monitoring limited")
            return
        }
        
        if locationService.authorizationStatus == .authorizedAlways {
            logger.info("🌙 Always location permission available - enabling background monitoring")
            await checkBackgroundAppRefresh()
        } else {
            logger.info("📱 Always location permission not available - limited to foreground monitoring")
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
        let appState = UIApplication.shared.applicationState
        let stateText = appState == .background ? "BACKGROUND" : (appState == .inactive ? "INACTIVE" : "FOREGROUND")
        
        guard isActive,
              let route = activeRoute,
              let userLocation = locationService.currentLocation else {
            logger.warning("🔍 checkProximityToSpots skipped (\(stateText)) - isActive: \(self.isActive), route: \(self.activeRoute != nil), location: \(self.locationService.currentLocation != nil)")
            return
        }
        
        logger.info("🔍 Checking proximity for \(route.waypoints.count) waypoints from location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude) (\(stateText))")
        
        for (index, waypoint) in route.waypoints.enumerated() {
            let spotId = generateSpotId(for: waypoint)
            
            // Skip start and end points - only notify for actual POIs
            let isStartPoint = (index == 0)
            let isEndPoint = (index == route.waypoints.count - 1)
            
            if isStartPoint || isEndPoint {
                logger.info("📍 Skipping \(isStartPoint ? "START" : "END") point: \(waypoint.name) (index: \(index))")
                continue
            }
            
            // Skip if already visited
            if visitedSpots.contains(spotId) {
                continue
            }
            
            let spotLocation = CLLocation(
                latitude: waypoint.coordinate.latitude,
                longitude: waypoint.coordinate.longitude
            )
            
            let distance = userLocation.distance(from: spotLocation)
            logger.info("📍 Distance to \(waypoint.name): \(String(format: "%.1f", distance))m (threshold: \(self.proximityThreshold)m)")
            
            if distance <= proximityThreshold {
                logger.info("🎯 Triggering notification for \(waypoint.name) - within threshold!")
                await triggerSpotNotification(for: waypoint, distance: distance)
                visitedSpots.insert(spotId)
                logger.info("✅ Spot visited: \(waypoint.name) at \(String(format: "%.1f", distance))m")
                
                // Check for route completion after each spot visit
                await checkRouteCompletion()
            }
        }
    }
    
    // MARK: - Route Completion Detection
    private func checkRouteCompletion() async {
        guard let route = activeRoute else { return }
        
        // Route is complete when all POIs (excluding start/end points) have been visited
        let totalPOIs = max(0, route.waypoints.count - 2) // Exclude start and end points
        let visitedCount = visitedSpots.count
        
        logger.info("🎯 Route progress: \(visitedCount)/\(totalPOIs) POIs visited (excluding start/end points)")
        
        if visitedCount >= totalPOIs && totalPOIs > 0 && !routeCompletionTriggered {
            logger.info("🎉 Route completed! All \(totalPOIs) POIs visited")
            routeCompletionTriggered = true // Prevent multiple completions
            await triggerRouteCompletionNotification()
            
            // Stop proximity monitoring after completion
            stopProximityMonitoring()
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
        
        // Request background execution time for notification processing
        let appState = UIApplication.shared.applicationState
        let backgroundTaskId: UIBackgroundTaskIdentifier?
        
        if appState == .background || appState == .inactive {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "POI Notification") { [weak self] in
                self?.logger.warning("⏰ Background task for POI notification expired")
            }
            logger.info("🌙 Started background task for POI notification")
        } else {
            backgroundTaskId = nil
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Spot erreicht!"
        content.body = "Du bist bei \(waypoint.name) angekommen! Schau dich um und entdecke was Neues."
        content.sound = .default
        content.badge = 1
        
        // Critical for background delivery
        content.interruptionLevel = .active // Show even when device is locked or in Do Not Disturb
        content.relevanceScore = 1.0 // High priority
        
        // Add custom data
        content.userInfo = [
            "notificationType": "poi",
            "spotName": waypoint.name,
            "spotCoordinates": [
                "latitude": waypoint.coordinate.latitude,
                "longitude": waypoint.coordinate.longitude
            ],
            "distance": distance,
            "category": waypoint.category.rawValue
        ]
        
        // Trigger immediately - nil trigger for background delivery
        let request = UNNotificationRequest(
            identifier: "spot_\(waypoint.name)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // nil = immediate delivery, critical for background notifications
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("📢 Notification triggered for: \(waypoint.name)")
        } catch {
            logger.error("❌ Failed to schedule notification: \(error)")
        }
        
        // End background task if started
        if let taskId = backgroundTaskId, taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
            logger.info("🌙 Ended background task for POI notification")
        }
    }
    
    private func triggerRouteCompletionNotification() async {
        guard let route = activeRoute else { return }
        
        // Always trigger route completion notifications (independent of POI notification settings)
        guard notificationPermissionStatus == .authorized else {
            logger.info("🎉 Route completed but notification permission not granted")
            return
        }
        
        // Request background execution time for notification processing
        let appState = UIApplication.shared.applicationState
        let backgroundTaskId: UIBackgroundTaskIdentifier?
        
        if appState == .background || appState == .inactive {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Route Completion Notification") { [weak self] in
                self?.logger.warning("⏰ Background task for route completion notification expired")
            }
            logger.info("🌙 Started background task for route completion notification")
        } else {
            backgroundTaskId = nil
        }
        
        let stats = RouteCompletionStats.from(route: route, visitedCount: visitedSpots.count)
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Tour abgeschlossen!"
        content.body = "Super! Du hast alle \(stats.visitedSpotsCount) Stops besucht. \(stats.formattedDistance) in \(stats.formattedWalkingTime) geschafft!"
        content.sound = .default
        content.badge = 1
        
        // Critical for background delivery
        content.interruptionLevel = .active // Show even when device is locked or in Do Not Disturb
        content.relevanceScore = 1.0 // High priority
        
        // Add route completion metadata
        content.userInfo = [
            "notificationType": "routeCompletion",
            "routeStats": (try? JSONEncoder().encode(stats)) as Any,
            "completionDate": stats.completionDate.timeIntervalSince1970,
            "visitedSpotsCount": stats.visitedSpotsCount,
            "totalDistance": stats.totalDistance,
            "routeName": stats.routeName
        ].compactMapValues { $0 }
        
        // Trigger immediately - nil trigger for background delivery
        let request = UNNotificationRequest(
            identifier: "route_completion_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // nil = immediate delivery, critical for background notifications
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("🎉 Route completion notification triggered for: \(stats.routeName)")
            
            // Also notify HomeCoordinator via NotificationCenter
            NotificationCenter.default.post(
                name: .routeCompletionSuccess,
                object: nil,
                userInfo: ["routeStats": try JSONEncoder().encode(stats)]
            )
            
        } catch {
            logger.error("❌ Failed to schedule route completion notification: \(error)")
        }
        
        // End background task if started
        if let taskId = backgroundTaskId, taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
            logger.info("🌙 Ended background task for route completion notification")
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