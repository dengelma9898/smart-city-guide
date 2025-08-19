import SwiftUI
import CoreLocation
import Foundation

/// Enhanced Active Route Sheet with multi-mode presentation and delightful UX
struct EnhancedActiveRouteSheetView: View {
    let route: GeneratedRoute
    let onEnd: () -> Void
    let onAddStop: () -> Void
    let onModifyRoute: ((RouteModification) -> Void)?
    
    // UX State Management
    @State private var currentMode: ActiveRouteSheetMode = .navigation
    @State private var progress: RouteProgress?
    @State private var dragOffset: CGSize = .zero
    
    // User Context
    @State private var userContext = UserNavigationContext(
        isActivelyNavigating: true,
        lastMovementTime: Date(),
        currentSpeed: 1.4, // Average walking speed
        isStationary: false,
        timeOfDay: .afternoon,
        weatherCondition: .sunny
    )
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Sheet Handle with Mode Indicator
                ActiveRouteSheetHandle(
                    currentMode: currentMode,
                    onModeChange: { mode in
                        withAnimation(.sheetModeTransition) {
                            currentMode = mode
                        }
                    }
                )
                .padding(.top, 8)
                
                // Mode-specific content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch currentMode {
                        case .compact:
                            compactContent
                        case .navigation:
                            navigationContent
                        case .overview:
                            overviewContent
                        case .hidden:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                .clipped()
            }
            .background(backgroundMaterial)
            .offset(y: dragOffset.height)
            .animation(.sheetModeTransition, value: currentMode)
            .animation(.spring(response: 0.3), value: dragOffset)
            .onAppear {
                setupInitialState()
            }
        }
        .accessibilityIdentifier("EnhancedActiveRouteSheetView")
    }
    
    // MARK: - Background Material
    
    private var backgroundMaterial: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.regularMaterial)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Compact Mode Content
    
    private var compactContent: some View {
        HStack(spacing: 16) {
            // Route Summary
            VStack(alignment: .leading, spacing: 4) {
                Text(routeSummaryTitle)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(routeSummarySubtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick action button
            Button(action: { onAddStop() }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.sheetModeTransition) {
                currentMode = .navigation
            }
        }
    }
    
    // MARK: - Navigation Mode Content
    
    private var navigationContent: some View {
        VStack(spacing: 20) {
            // Next waypoint focus (primary content)
            if let nextWaypoint = nextWaypoint {
                ActiveRouteNextWaypointCard(
                    waypoint: nextWaypoint,
                    distanceToNext: distanceToNext,
                    estimatedArrival: estimatedArrival
                )
                .padding(.horizontal, 20)
            }
            
            // Navigation assistance
            ActiveRouteNavigationHints(
                userContext: userContext,
                navigationHintText: navigationHintText
            )
            .padding(.horizontal, 20)
            
            // Quick actions
            quickActions
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Overview Mode Content
    
    private var overviewContent: some View {
        VStack(spacing: 24) {
            // Route progress overview (primary content)
            ActiveRouteProgressTracking(
                route: route,
                progress: progress
            )
            .padding(.horizontal, 20)
            
            // Route modification tools
            ActiveRouteModificationTools(
                route: route,
                onModify: onModifyRoute,
                onEnd: onEnd,
                onAddStop: onAddStop
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 16) {
            Button("Erreicht", action: markWaypointVisited)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            
            Button("Überspringen", action: skipWaypoint)
                .buttonStyle(.bordered)
                .controlSize(.regular)
        }
    }
    
    // MARK: - State Management
    
    private func setupInitialState() {
        // Create mock progress for demo
        progress = RouteProgress(
            completedWaypoints: 1,
            currentWaypointIndex: 1,
            totalWaypoints: route.waypoints.count,
            elapsedTime: 15 * 60, // 15 minutes
            remainingTime: 45 * 60 // 45 minutes
        )
    }
    
    // MARK: - Actions
    
    private func markWaypointVisited() {
        RouteHaptics.waypointReached.trigger()
        // TODO: Implement waypoint visited logic
    }
    
    private func skipWaypoint() {
        RouteHaptics.routeModified.trigger()
        // TODO: Implement waypoint skipping logic
    }
    
    // MARK: - Computed Properties
    
    private var nextWaypoint: RoutePoint? {
        // Return next unvisited waypoint (simulate current progress)
        let currentIndex = progress?.currentWaypointIndex ?? 0
        guard currentIndex < route.waypoints.count else { return nil }
        return route.waypoints[currentIndex]
    }
    
    private var distanceToNext: CLLocationDistance? {
        // Mock realistic distance for demo
        return 250
    }
    
    private var estimatedArrival: Date? {
        return Date().addingTimeInterval(300) // 5 minutes
    }
    
    private var routeSummaryTitle: String {
        if let nextWaypoint = nextWaypoint {
            return "Weiter zu \(nextWaypoint.name)"
        }
        return route.waypoints.first?.name ?? "Aktive Route"
    }
    
    private var routeSummarySubtitle: String {
        let km = max(1, Int(route.totalDistance / 1000))
        let time = formatDuration(route.totalExperienceTime)
        return "\(km) km • \(time) • \(route.waypoints.count) Stopps"
    }
    
    private var navigationHintText: String {
        // Mock navigation hint - in real implementation, use turn-by-turn navigation
        return "Geradeaus 200m, dann links zum Hauptmarkt"
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remMin = minutes % 60
        return remMin == 0 ? "\(hours) h" : "\(hours) h \(remMin) min"
    }
}

// MARK: - Preview

#Preview {
    EnhancedActiveRouteSheetView(
        route: GeneratedRoute.mockRoute,
        onEnd: {},
        onAddStop: {},
        onModifyRoute: { _ in }
    )
}

// MARK: - Mock Data Extension

extension GeneratedRoute {
    static var mockRoute: GeneratedRoute {
        let waypoints = [
            RoutePoint(name: "Hauptbahnhof", coordinate: CLLocationCoordinate2D(latitude: 49.4454, longitude: 11.0820), address: "Bahnhofsplatz 1", category: .attraction),
            RoutePoint(name: "Hauptkirche St. Sebald", coordinate: CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767), address: "Sebalder Platz", category: .attraction),
            RoutePoint(name: "Nürnberger Rathaus", coordinate: CLLocationCoordinate2D(latitude: 49.4530, longitude: 11.0770), address: "Hauptmarkt 18", category: .attraction),
            RoutePoint(name: "Kaiserburg", coordinate: CLLocationCoordinate2D(latitude: 49.4590, longitude: 11.0750), address: "Auf der Burg 17", category: .attraction)
        ]
        
        return GeneratedRoute(
            waypoints: waypoints,
            routes: [], // Mock empty routes
            totalDistance: 2500.0,
            totalTravelTime: 1800.0,
            totalVisitTime: 3600.0,
            totalExperienceTime: 5400.0
        )
    }
}
