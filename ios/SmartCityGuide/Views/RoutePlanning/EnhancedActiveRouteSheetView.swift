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
    @State private var showingEndConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: DragGesture.Value?
    
    // Animation State
    @State private var progressAnimationPhase = 0.0
    @State private var waypointPulsePhase = 0.0
    
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
            let availableHeight = geometry.size.height
            
            VStack(spacing: 0) {
                // Sheet Handle with Mode Indicator
                VStack(spacing: 8) {
                    sheetHandle
                    modeIndicator
                }
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
            .gesture(dragGesture)
            .onChange(of: availableHeight) { _, newHeight in
                adaptToHeight(newHeight)
            }
            .onAppear {
                setupInitialState()
                startProgressTracking()
            }
        }
        .accessibilityIdentifier("EnhancedActiveRouteSheetView")
        .alert("Tour wirklich beenden?", isPresented: $showingEndConfirmation) {
            Button("Abbrechen", role: .cancel) { 
                RouteHaptics.lightImpact.trigger()
            }
            Button("Beenden", role: .destructive) { 
                RouteHaptics.routeCompleted.trigger()
                onEnd() 
            }
        } message: {
            Text("Deine aktuelle Tour wird geschlossen. Das kannst du nicht rückgängig machen.")
        }
    }
    
    // MARK: - Sheet Handle & Mode Indicator
    
    private var modeIndicator: some View {
        HStack(spacing: 6) {
            ForEach([ActiveRouteSheetMode.compact, .navigation, .overview], id: \.self) { mode in
                Circle()
                    .fill(currentMode == mode ? Color.blue : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: currentMode)
            }
        }
    }
    
    private var sheetHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.bottom, 8)
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
            // Progress Ring
            if let progress = progress {
                progressRing(progress)
                    .frame(width: 50, height: 50)
            }
            
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
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { switchMode(.navigation) }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { 
                    RouteHaptics.mediumImpact.trigger()
                    showingEndConfirmation = true 
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            switchMode(.navigation)
        }
    }
    
    // MARK: - Navigation Mode Content
    
    private var navigationContent: some View {
        VStack(spacing: 20) {
            // Next waypoint focus (primary content)
            nextWaypointCard
                .padding(.horizontal, 20)
            
            // Navigation assistance
            navigationHints
                .padding(.horizontal, 20)
            
            // Quick actions
            navigationActions
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Overview Mode Content
    
    private var overviewContent: some View {
        VStack(spacing: 24) {
            // Route progress overview (primary content)
            routeProgressOverview
                .padding(.horizontal, 20)
            
            // Waypoint list with modification tools
            waypointList
            
            // Route modification tools
            if let onModifyRoute = onModifyRoute {
                routeModificationTools(onModify: onModifyRoute)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Next Waypoint Card
    
    private var nextWaypointCard: some View {
        VStack(spacing: 12) {
            if let nextWaypoint = nextWaypoint {
                HStack(spacing: 16) {
                    // Waypoint icon with pulse animation
                    Image(systemName: nextWaypoint.category.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0 + sin(waypointPulsePhase) * 0.1)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: waypointPulsePhase)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextWaypoint.name)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .lineLimit(2)
                        
                        Text(nextWaypoint.address)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        if let distanceToNext = distanceToNext {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .font(.caption)
                                Text(formatDistance(distanceToNext))
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                
                                if let eta = estimatedArrival {
                                    Text("• \(formatETA(eta))")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .onAppear {
            waypointPulsePhase = 1.0
        }
    }
    
    // MARK: - Navigation Hints
    
    private var navigationHints: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Navigation")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(navigationHintText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.blue.opacity(0.1))
            )
        }
    }
    
    // MARK: - Navigation Actions
    
    private var navigationActions: some View {
        HStack(spacing: 16) {
            Button(action: markWaypointVisited) {
                Label("Angekommen", systemImage: "checkmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(.green)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: skipWaypoint) {
                Label("Überspringen", systemImage: "arrow.right.circle")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(.blue.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: - Route Progress Overview
    
    private var routeProgressOverview: some View {
        VStack(spacing: 16) {
            // Progress statistics
            HStack(spacing: 24) {
                progressStat(title: "Fortschritt", value: progressPercentageText, color: .blue)
                progressStat(title: "Verbleibend", value: remainingTimeText, color: .orange)
                progressStat(title: "Besucht", value: visitedWaypointsText, color: .green)
            }
            
            // Visual progress bar
            if let progress = progress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Route Fortschritt")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress.completionPercentage * 100))%")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: progress.completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2.0)
                        .animation(.progressUpdate, value: progress.completionPercentage)
                }
            }
        }
    }
    
    // MARK: - Waypoint List
    
    private var waypointList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deine Route")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(route.waypoints.enumerated()), id: \.offset) { index, waypoint in
                    waypointRow(waypoint: waypoint, index: index)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Route Modification Tools
    
    private func routeModificationTools(onModify: @escaping (RouteModification) -> Void) -> some View {
        VStack(spacing: 16) {
            Text("Route anpassen")
                .font(.system(.headline, design: .rounded, weight: .semibold))
            
            HStack(spacing: 16) {
                modificationButton(
                    title: "POI hinzufügen",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: { onModify(.addNearbyPOI) }
                )
                
                modificationButton(
                    title: "Pause einlegen",
                    icon: "cup.and.saucer.fill",
                    color: .orange,
                    action: { onModify(.addBreak) }
                )
                
                modificationButton(
                    title: "Route optimieren",
                    icon: "arrow.triangle.2.circlepath",
                    color: .green,
                    action: { onModify(.optimize) }
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func progressRing(_ progress: RouteProgress) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress.completionPercentage)
                .stroke(progress.progressRingData.strokeColor, style: progress.progressRingData.strokeStyle)
                .rotationEffect(.degrees(-90))
                .animation(.progressUpdate, value: progress.completionPercentage)
            
            Text("\(Int(progress.completionPercentage * 100))%")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(progress.progressRingData.strokeColor)
        }
    }
    
    private func progressStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
    }
    
    private func waypointRow(waypoint: RoutePoint, index: Int) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: waypointState(for: index).icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(waypointState(for: index).color)
                .frame(width: 24)
            
            // Waypoint info
            VStack(alignment: .leading, spacing: 2) {
                Text(waypoint.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .lineLimit(1)
                
                Text(waypoint.address)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action button for current waypoint
            if waypointState(for: index) == .current {
                Button(action: { switchMode(.navigation) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(waypointState(for: index) == .current ? .blue.opacity(0.1) : Color(.systemGray5))
        )
    }
    
    private func modificationButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            RouteHaptics.mediumImpact.trigger()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                lastDragValue = value
                
                // Only allow vertical dragging
                if abs(value.translation.height) > abs(value.translation.width) {
                    dragOffset = CGSize(width: 0, height: max(0, value.translation.height))
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndLocation.y - value.startLocation.y
                let threshold: CGFloat = 100
                
                if value.translation.height > threshold || velocity > 300 {
                    // Drag down - switch to more compact mode or dismiss
                    switchToNextMode(direction: .down)
                } else if value.translation.height < -threshold || velocity < -300 {
                    // Drag up - switch to more detailed mode
                    switchToNextMode(direction: .up)
                }
                
                // Reset drag offset
                withAnimation(.spring(response: 0.3)) {
                    dragOffset = .zero
                }
            }
    }
    
    // MARK: - Mode Management
    
    private func switchMode(_ newMode: ActiveRouteSheetMode) {
        print("🔄 Sheet mode switch: \(currentMode) → \(newMode)")
        withAnimation(.sheetModeTransition) {
            currentMode = newMode
        }
        RouteHaptics.selectionChanged.trigger()
    }
    
    private func switchToNextMode(direction: DragDirection) {
        let allModes: [ActiveRouteSheetMode] = [.compact, .navigation, .overview]
        guard let currentIndex = allModes.firstIndex(of: currentMode) else { return }
        
        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = min(currentIndex + 1, allModes.count - 1)
        case .down:
            nextIndex = max(currentIndex - 1, 0)
        }
        
        if nextIndex != currentIndex {
            switchMode(allModes[nextIndex])
        }
    }
    
    private enum DragDirection {
        case up, down
    }
    
    // MARK: - State Management
    
    private func setupInitialState() {
        // Start with compact mode as designed in UX flow
        currentMode = .compact
        
        // Setup mock progress for demonstration
        progress = RouteProgress(
            currentWaypointIndex: 1,
            distanceCompleted: 500,
            timeElapsed: 600, // 10 minutes
            estimatedTimeRemaining: 2400, // 40 minutes
            completionPercentage: 0.2,
            nextWaypointETA: Date().addingTimeInterval(600),
            totalWaypointsVisited: 1,
            currentUserLocation: nil
        )
    }
    
    private func startProgressTracking() {
        // Start animation phases
        DispatchQueue.main.async {
            progressAnimationPhase = 1.0
        }
    }
    
    private func adaptToHeight(_ height: CGFloat) {
        // Only auto-switch on initial setup, not during user interaction
        // Remove auto-switching to respect user gestures
        print("📏 Sheet height: \(height), current mode: \(currentMode)")
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
        return "\(km) km • \(time) • \(route.numberOfStops) Stopps"
    }
    
    private var progressPercentageText: String {
        guard let progress = progress else { return "0%" }
        return "\(Int(progress.completionPercentage * 100))%"
    }
    
    private var remainingTimeText: String {
        guard let progress = progress else { return "--" }
        return formatDuration(progress.estimatedTimeRemaining)
    }
    
    private var visitedWaypointsText: String {
        guard let progress = progress else { return "0" }
        return "\(progress.totalWaypointsVisited)/\(route.numberOfStops)"
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
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    private func formatETA(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func waypointState(for index: Int) -> WaypointProgressState {
        guard let progress = progress else { return .upcoming }
        
        if index < progress.currentWaypointIndex {
            return .visited
        } else if index == progress.currentWaypointIndex {
            return .current
        } else {
            return .upcoming
        }
    }
}

// MARK: - Route Modification Types

enum RouteModification {
    case addNearbyPOI
    case addBreak
    case optimize
    case skipWaypoint(Int)
    case reorderWaypoints([RoutePoint])
}

// MARK: - Preview

#Preview {
    EnhancedActiveRouteSheetView(
        route: GeneratedRoute.mockRoute,
        onEnd: {},
        onAddStop: {},
        onModifyRoute: nil
    )
    .presentationDetents([.height(84), .fraction(0.5), .large])
    .presentationDragIndicator(.visible)
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
