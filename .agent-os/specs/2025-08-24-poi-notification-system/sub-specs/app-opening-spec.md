# App Opening & Navigation Specification

Diese Spezifikation beschreibt das verbesserte App-Opening-Verhalten beim Antippen von POI- und Route-Completion-Benachrichtigungen.

## Current State Analysis

**✅ Existing Implementation:**
- UNUserNotificationCenterDelegate in ProximityService
- Basic `didReceive response` handling mit Logging
- Keine Navigation oder App-Opening-Logic

**🚫 Missing Features:**
- App öffnet nicht automatisch zur Karten-Ansicht
- Keine Sheet-Dismissal bei Notification-Tap
- Keine Context-Wiederherstellung (aktive Route highlighting)

## Technical Requirements

### App State Management

**Ziel-Verhalten beim Notification-Tap:**
1. App öffnen (falls im Background/terminated)
2. Alle aktiven Sheets/Overlays dismissen
3. Zur Hauptkarte navigieren
4. Aktive Route hervorheben
5. Optional: Success-Message bei Route-Completion

### HomeCoordinator Integration

#### Sheet-Dismissal-Logic

```swift
// In HomeCoordinator neue Methode:
private func dismissActiveSheets() {
    // Dismiss RouteBuilder if active
    if showRouteBuilder {
        showRouteBuilder = false
    }
    
    // Dismiss ActiveRouteSheet if active  
    if showActiveRouteSheet {
        showActiveRouteSheet = false
    }
    
    // Dismiss any other modal presentations
    if showRoutePlanning {
        showRoutePlanning = false
    }
    
    logger.info("📱 Dismissed active sheets for notification navigation")
}
```

#### Map-Focus-Logic

```swift
private func focusOnActiveRoute() {
    // Ensure map is visible (dismiss sheets first)
    dismissActiveSheets()
    
    // If we have an active route, focus map on it
    if let route = activeRoute {
        // Center map on route bounds
        let coordinates = route.waypoints.map { $0.coordinate }
        if !coordinates.isEmpty {
            // Trigger map region update
            NotificationCenter.default.post(
                name: .focusMapOnRoute,
                object: nil,
                userInfo: ["coordinates": coordinates]
            )
        }
    }
    
    logger.info("📱 Focused map on active route")
}
```

### ContentView Map Integration

#### Map Region Update Handler

**ContentView.swift Erweiterung:**
```swift
// In ContentView Notification-Observer hinzufügen:
.onReceive(NotificationCenter.default.publisher(for: .focusMapOnRoute)) { notification in
    if let coordinates = notification.userInfo?["coordinates"] as? [CLLocationCoordinate2D],
       !coordinates.isEmpty {
        
        // Calculate region that fits all coordinates
        let mapRegion = calculateRegionFor(coordinates: coordinates)
        
        // Animate to new region
        withAnimation(.easeInOut(duration: 1.0)) {
            region = mapRegion
        }
    }
}

private func calculateRegionFor(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
    guard !coordinates.isEmpty else {
        return region // Return current region if no coordinates
    }
    
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }
    
    let minLat = latitudes.min()!
    let maxLat = latitudes.max()!
    let minLon = longitudes.min()!
    let maxLon = longitudes.max()!
    
    let center = CLLocationCoordinate2D(
        latitude: (minLat + maxLat) / 2,
        longitude: (minLon + maxLon) / 2
    )
    
    let span = MKCoordinateSpan(
        latitudeDelta: max(maxLat - minLat, 0.01) * 1.2, // 20% padding
        longitudeDelta: max(maxLon - minLon, 0.01) * 1.2
    )
    
    return MKCoordinateRegion(center: center, span: span)
}
```

### Enhanced Notification Handling

#### ProximityService Delegate Enhancement

```swift
// Enhanced didReceive method:
nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    let userInfo = response.notification.request.content.userInfo
    
    Task { @MainActor in
        // Log the interaction
        logger.info("📱 User tapped notification: \(response.notification.request.identifier)")
        
        // Determine notification type and handle accordingly
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "route_completion":
                await handleRouteCompletionNotificationTap(userInfo: userInfo)
            default:
                await handlePOINotificationTap(userInfo: userInfo)
            }
        } else {
            // Legacy POI notification handling
            await handlePOINotificationTap(userInfo: userInfo)
        }
    }
    
    completionHandler()
}

private func handlePOINotificationTap(userInfo: [AnyHashable: Any]) async {
    if let spotName = userInfo["spotName"] as? String {
        logger.info("📱 Handling POI notification tap for: \(spotName)")
    }
    
    // Trigger app opening to map
    NotificationCenter.default.post(
        name: .poiNotificationTapped,
        object: nil,
        userInfo: userInfo
    )
}

private func handleRouteCompletionNotificationTap(userInfo: [AnyHashable: Any]) async {
    logger.info("📱 Handling route completion notification tap")
    
    // Trigger app opening with success context
    NotificationCenter.default.post(
        name: .routeCompletionNotificationTapped,
        object: nil,
        userInfo: userInfo
    )
}
```

### RouteSuccessView Display

#### HomeCoordinator Success Handling

```swift
// Neue Published Properties in HomeCoordinator:
@Published var showRouteSuccessView: Bool = false
@Published var routeSuccessStats: RouteCompletionStats?

private func showRouteCompletionSuccess(userInfo: [AnyHashable: Any]?) {
    guard let userInfo = userInfo else { return }
    
    // Create RouteCompletionStats from userInfo
    if let visitedCount = userInfo["visitedCount"] as? Int,
       let totalWaypoints = userInfo["totalWaypoints"] as? Int,
       let distance = userInfo["routeDistance"] as? CLLocationDistance,
       let travelTime = userInfo["routeTravelTime"] as? TimeInterval,
       let experienceTime = userInfo["routeExperienceTime"] as? TimeInterval,
       let timestamp = userInfo["completionTimestamp"] as? TimeInterval {
        
        routeSuccessStats = RouteCompletionStats(
            visitedPOIs: visitedCount,
            totalPOIs: totalWaypoints,
            totalWalkingDistance: distance,
            totalWalkingTime: travelTime,
            totalExperienceTime: experienceTime,
            completionTime: Date(timeIntervalSince1970: timestamp)
        )
        
        // Show RouteSuccessView as full-screen sheet
        showRouteSuccessView = true
    }
}
```

#### ContentView RouteSuccessView Sheet

```swift
// In ContentView sheet hinzufügen:
.sheet(isPresented: $coordinator.showRouteSuccessView) {
    if let stats = coordinator.routeSuccessStats,
       let route = coordinator.activeRoute {
        RouteSuccessView(
            completedRoute: route,
            routeStats: stats,
            onClose: {
                coordinator.showRouteSuccessView = false
                coordinator.routeSuccessStats = nil
                // Return to map view
            }
        )
    }
}
```

## App Lifecycle Considerations

### Cold Start Handling

**Wenn App nicht läuft:**
- System startet App durch Notification-Tap
- SmartCityGuideApp.swift Lifecycle triggert
- ProximityService.shared wird initialisiert
- Notification-Handling läuft normal

### Background → Foreground

**Wenn App im Background:**
- `didReceive response` wird direkt getriggert
- App kommt in Foreground
- Navigation-Logic läuft sofort

### Foreground mit aktiven Sheets

**Wenn App bereits sichtbar:**
- Sheet-Dismissal verhindert UI-Konflikte
- Map-Focus sorgt für klaren Context
- Success-Message überlagert andere UI-Elemente

## Testing Strategy

### Manual Testing Scenarios

1. **Cold Start:**
   - App nicht gestartet
   - POI-Notification tap → App öffnet auf Map

2. **Background Recovery:**
   - App im Background
   - Route-Completion-Notification tap → App im Foreground mit Success-Message

3. **Sheet-Dismissal:**
   - App offen mit ActiveRouteSheet
   - POI-Notification tap → Sheet dismissed, Map visible

4. **Map-Focus:**
   - App offen, Map aus Route-Region herausgescrollt
   - Notification tap → Map centered auf aktive Route

### Automated Testing

**UI-Tests for Notification Handling:**
```swift
func testPOINotificationOpensMap() {
    // Simulate notification tap
    // Verify: Map is visible, no sheets active
    // Verify: Map region shows active route
}

func testRouteCompletionShowsSuccess() {
    // Simulate route completion notification tap
    // Verify: Success banner appears
    // Verify: Map focused on completed route
}
```

## Error Handling

### No Active Route

```swift
private func focusOnActiveRoute() {
    dismissActiveSheets()
    
    guard let route = activeRoute else {
        logger.warning("📱 No active route to focus on")
        // Still show map, but without specific region
        return
    }
    
    // Rest of implementation...
}
```

### Invalid Coordinates

```swift
private func calculateRegionFor(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
    // Validate coordinates
    let validCoordinates = coordinates.filter { coord in
        CLLocationCoordinate2DIsValid(coord)
    }
    
    guard !validCoordinates.isEmpty else {
        logger.warning("📱 No valid coordinates for map region")
        return region // Fallback to current region
    }
    
    // Rest of implementation...
}
```

## Notification Names

```swift
extension Notification.Name {
    static let poiNotificationTapped = Notification.Name("poiNotificationTapped")
    static let routeCompletionNotificationTapped = Notification.Name("routeCompletionNotificationTapped")
    static let focusMapOnRoute = Notification.Name("focusMapOnRoute")
}
```

## Performance Considerations

- Map-Region-Updates nur bei tatsächlichen Notification-Taps
- Success-Message Auto-Hide verhindert dauerhafte UI-Overlay
- Sheet-Dismissal ist lightweight (boolean state changes)
- NotificationCenter-Events sind asynchron und blockieren nicht
