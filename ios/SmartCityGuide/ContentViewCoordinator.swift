import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    // MARK: - App Coordinator (Centralized State)
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ZStack {
                // Main Map View
                ContentMapView(
                    cameraPosition: .constant(.region(coordinator.mapRegion)),
                    locationService: coordinator.getLocationService(),
                    activeRoute: coordinator.activeRoute
                )
                
                // Top Overlay (Profile, Location)
                ContentTopOverlay(
                    onProfileTap: {
                        coordinator.presentSheet(.profile)
                    },
                    onLocationTap: {
                        coordinator.centerMapOnUserLocation()
                    }
                )
                
                // Active Route Banner (Legacy fallback)
                if let route = coordinator.activeRoute, !FeatureFlags.activeRouteBottomSheetEnabled {
                    ContentActiveRouteBanner(
                        route: route,
                        onTap: {
                            coordinator.presentSheet(.activeRoute)
                        }
                    )
                }
                
                // Bottom Action Bar
                ContentBottomActionBar(
                    onQuickPlanning: {
                        coordinator.startQuickPlanningFromCurrentLocation()
                    },
                    onRoutePlanning: {
                        coordinator.presentSheet(.routePlanning)
                    }
                )
                
                // Quick Planning Overlay
                if coordinator.isQuickPlanning {
                    ContentQuickPlanningOverlay(
                        message: coordinator.quickPlanningMessage
                    )
                }
            }
            .navigationDestination(for: String.self) { destination in
                destinationView(for: destination)
            }
        }
        .environmentObject(coordinator)
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetView(for: sheet.id)
        }
        .alert("Standort-Berechtigung erforderlich", isPresented: $coordinator.showingLocationPermissionAlert) {
            Button("Einstellungen", action: openLocationSettings)
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Bitte erlaube der App den Zugriff auf deinen Standort, um Routen in deiner Nähe zu finden.")
        }
        .alert(
            "Fehler",
            isPresented: .constant(coordinator.routeError != nil),
            actions: {
                Button("OK") { coordinator.clearError() }
            },
            message: {
                if let error = coordinator.routeError {
                    Text(error)
                }
            }
        )
    }
    
    // MARK: - Navigation Destinations
    
    @ViewBuilder
    private func destinationView(for destination: String) -> some View {
        switch destination {
        case "profile":
            ProfileView()
            
        case "routeHistory":
            RouteHistoryView()
            
        case "settings":
            ProfileSettingsView()
            
        case "help":
            HelpSupportView()
            
        default:
            Text("Unknown destination: \(destination)")
        }
    }
    
    // MARK: - Sheet Destinations
    
    @ViewBuilder
    private func sheetView(for sheet: String) -> some View {
        switch sheet {
        case "routePlanning":
            RoutePlanningView(
                presetMode: nil,
                onRouteGenerated: coordinator.handleRouteGenerated,
                onDismiss: coordinator.dismissSheet
            )
            
        case "activeRoute":
            if let route = coordinator.activeRoute {
                EnhancedActiveRouteSheetView(
                    route: route,
                    onEnd: coordinator.endActiveRoute,
                    onAddStop: {
                        // TODO: Implement add stop functionality
                        coordinator.dismissSheet()
                    },
                    onModifyRoute: { modification in
                        // TODO: Implement route modification
                        print("Route modification: \(modification)")
                    }
                )
                .presentationDetents([.height(84), .fraction(0.5), .large])
                .presentationDragIndicator(.visible)
            }
            
        case "profile":
            ProfileView()
            
        case "help":
            HelpSupportView()
            
        default:
            Text("Unknown sheet: \(sheet)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - AppCoordinator Extensions

extension AppCoordinator {
    
    func startQuickPlanningFromCurrentLocation() {
        guard let location = currentLocation else {
            showingLocationPermissionAlert = true
            return
        }
        
        startQuickPlanningAt(location: location)
    }
}

// MARK: - Error Alert Modifier

extension View {
    func errorAlert(
        message: String?,
        isPresented: Binding<Bool>,
        onDismiss: @escaping () -> Void
    ) -> some View {
        alert(
            "Fehler",
            isPresented: isPresented,
            actions: {
                Button("OK") { onDismiss() }
            },
            message: {
                if let message = message {
                    Text(message)
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
