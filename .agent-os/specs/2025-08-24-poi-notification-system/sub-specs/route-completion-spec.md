# Route Completion Notification Specification

Diese Spezifikation beschreibt die Implementierung der Route-Completion-Benachrichtigung bei vollständiger Absolvierung aller POIs einer aktiven Route.

## Feature Overview

**Goal:** Nutzer erhalten eine spezielle "Erfolgs"-Benachrichtigung, wenn sie alle geplanten POIs einer Route besucht haben.

**Trigger-Condition:** `visitedSpots.count == activeRoute.waypoints.count`

**Timing:** Direkt nach dem letzten POI-Visit, nur einmalig pro Route

## Technical Implementation

### ProximityService Enhancement

#### Neue Properties

```swift
private var routeCompletionNotificationSent: Bool = false
```

**Reset in startProximityMonitoring:**
```swift
func startProximityMonitoring(for route: GeneratedRoute) async {
    // Existing code...
    
    routeCompletionNotificationSent = false  // Reset für neue Route
    
    // Rest of existing implementation...
}
```

#### Route-Completion-Detection

**Neue Methode:**
```swift
private func checkRouteCompletion() async {
    guard isActive,
          let route = activeRoute,
          !routeCompletionNotificationSent else {
        return
    }
    
    // Check if all waypoints have been visited
    let totalWaypoints = route.waypoints.count
    let visitedCount = visitedSpots.count
    
    if visitedCount >= totalWaypoints {
        await triggerRouteCompletionNotification(
            visitedCount: visitedCount,
            totalWaypoints: totalWaypoints,
            route: route
        )
        routeCompletionNotificationSent = true
        logger.info("🎉 Route completion notification sent for route with \(totalWaypoints) waypoints")
    }
}
```

**Integration in checkProximityToSpots:**
```swift
func checkProximityToSpots() async {
    // Existing proximity detection code...
    
    if distance <= proximityThreshold {
        await triggerSpotNotification(for: waypoint, distance: distance)
        visitedSpots.insert(spotId)
        logger.info("✅ Spot visited: \(waypoint.name)")
        
        // NEW: Check for route completion after each POI visit
        await checkRouteCompletion()
    }
}
```

### Route-Completion-Notification

#### Notification Content

```swift
private func triggerRouteCompletionNotification(
    visitedCount: Int,
    totalWaypoints: Int,
    route: GeneratedRoute
) async {
    guard notificationPermissionStatus == .authorized,
          notificationsEnabled else {
        logger.info("📢 Route completion notification skipped - not authorized/enabled")
        return
    }
    
    let content = UNMutableNotificationContent()
    content.title = "🎉 Route abgeschlossen!"
    content.body = "Glückwunsch! Du hast alle \(totalWaypoints) Spots deiner Route besucht. Tap hier für deine Erfolgs-Übersicht."
    content.sound = .default
    content.badge = 1
    
    // Special userInfo for route completion
    content.userInfo = [
        "notificationType": "route_completion",
        "visitedCount": visitedCount,
        "totalWaypoints": totalWaypoints,
        "routeDistance": route.totalDistance,
        "routeDuration": route.estimatedDuration
    ]
    
    // Trigger immediately
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    let request = UNNotificationRequest(
        identifier: "route_completed_\(Date().timeIntervalSince1970)",
        content: content,
        trigger: trigger
    )
    
    do {
        try await notificationCenter.add(request)
        logger.info("🎉 Route completion notification triggered")
    } catch {
        logger.error("❌ Failed to schedule route completion notification: \(error)")
    }
}
```

## Notification Handling & App Opening

### Enhanced didReceive Response

**ProximityService UNUserNotificationCenterDelegate:**
```swift
nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    let userInfo = response.notification.request.content.userInfo
    
    Task { @MainActor in
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "route_completion":
                await handleRouteCompletionNotificationTap(userInfo: userInfo)
            default:
                await handlePOINotificationTap(userInfo: userInfo)
            }
        } else {
            // Legacy POI notification (no type specified)
            await handlePOINotificationTap(userInfo: userInfo)
        }
    }
    
    completionHandler()
}

private func handleRouteCompletionNotificationTap(userInfo: [AnyHashable: Any]) async {
    logger.info("📱 User tapped route completion notification")
    
    // Notify HomeCoordinator to show success view
    NotificationCenter.default.post(
        name: .routeCompletionNotificationTapped,
        object: nil,
        userInfo: userInfo
    )
}

private func handlePOINotificationTap(userInfo: [AnyHashable: Any]) async {
    if let spotName = userInfo["spotName"] as? String {
        logger.info("📱 User tapped POI notification for: \(spotName)")
    }
    
    // Notify HomeCoordinator to open map
    NotificationCenter.default.post(
        name: .poiNotificationTapped,
        object: nil,
        userInfo: userInfo
    )
}
```

## HomeCoordinator Integration

### Notification Observers

**Setup in HomeCoordinator.setupObservers():**
```swift
// Route completion notification handling
NotificationCenter.default.addObserver(
    forName: .routeCompletionNotificationTapped,
    object: nil,
    queue: .main
) { [weak self] notification in
    Task { @MainActor in
        self?.handleRouteCompletionNotificationTap(notification.userInfo)
    }
}

// POI notification handling  
NotificationCenter.default.addObserver(
    forName: .poiNotificationTapped,
    object: nil,
    queue: .main
) { [weak self] notification in
    Task { @MainActor in
        self?.handlePOINotificationTap()
    }
}
```

### App-Opening Logic

```swift
private func handleRouteCompletionNotificationTap(_ userInfo: [AnyHashable: Any]?) {
    // Dismiss any active sheets first
    dismissActiveSheets()
    
    // Show success message/sheet
    showRouteCompletionSuccess(userInfo: userInfo)
    
    // Focus on map with completed route highlighted
    focusOnActiveRoute()
}

private func handlePOINotificationTap() {
    // Dismiss any active sheets
    dismissActiveSheets()
    
    // Focus on map with active route
    focusOnActiveRoute()
}

private func showRouteCompletionSuccess(userInfo: [AnyHashable: Any]?) {
    // Could show a success sheet/banner or navigate to route history
    // For MVP: Simple banner/toast message
    if let visitedCount = userInfo?["visitedCount"] as? Int {
        self.successMessage = "🎉 Route mit \(visitedCount) Spots erfolgreich abgeschlossen!"
        showSuccessMessage = true
    }
}
```

## Edge Cases & Error Handling

### Double-Completion Prevention

- `routeCompletionNotificationSent` Flag verhindert mehrfache Notifications
- Reset bei neuer Route in `startProximityMonitoring`

### Rapid POI Visits

- Completion-Check läuft nach jedem einzelnen POI-Visit
- Thread-safe durch @MainActor Annotation
- Atomare visitedSpots.insert() Operation

### Route Changes

```swift
// In stopProximityMonitoring:
func stopProximityMonitoring() {
    logger.info("⏹️ Stopping proximity monitoring")
    isActive = false
    activeRoute = nil
    visitedSpots.removeAll()
    routeCompletionNotificationSent = false  // Reset completion state
    
    locationService.stopBackgroundLocationUpdates()
}
```

### Settings-Interaction

- Route-Completion respektiert `notificationsEnabled` Setting
- Keine separaten Settings für Route-Completion (Teil der POI-Notifications)

## Testing Strategy

### Unit Tests

1. **Completion-Detection:**
   - Route mit 3 POIs, alle besucht → Completion-Notification
   - Route mit 3 POIs, nur 2 besucht → Keine Completion-Notification

2. **Double-Completion-Prevention:**
   - Completion-Notification nur einmal pro Route-Session

3. **Settings-Respect:**
   - Mit disabled POI-Notifications → Keine Route-Completion-Notification

### Integration Tests

1. **Real Route Scenario:**
   - Vollständige Route absolvieren
   - Completion-Notification tapping
   - App öffnet auf Map mit highlighted Route

2. **Edge Cases:**
   - Route-Wechsel während Completion-Eligible-State
   - App-Kill nach Completion vor Notification-Tap

## Notification Names Extension

```swift
extension Notification.Name {
    static let routeCompletionNotificationTapped = Notification.Name("routeCompletionNotificationTapped")
    static let poiNotificationTapped = Notification.Name("poiNotificationTapped")
}
```
