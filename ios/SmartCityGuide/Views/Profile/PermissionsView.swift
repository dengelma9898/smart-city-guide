import SwiftUI

// MARK: - Permissions Management View
struct PermissionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManagerService.shared
    @StateObject private var proximityService = ProximityService.shared
    @StateObject private var settingsManager = ProfileSettingsManager.shared
    @StateObject private var biometricService = BiometricAuthenticationService.shared
    
    var body: some View {
        Form {
            // Header Section
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Berechtigungen")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Verwalte deine App-Berechtigungen für die beste Erfahrung!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            // MARK: - Location When In Use Section
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(getLocationToggleColor(for: .whenInUse))
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Standort (App-Nutzung)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(getLocationStatusText(for: .whenInUse))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { getLocationToggleState(for: .whenInUse) },
                                set: { newValue in
                                    Task {
                                        await handleLocationToggle(for: .whenInUse, enabled: newValue)
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                        }
                        
                        Text("Ermöglicht die Routenplanung von deinem aktuellen Standort aus.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Standort")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            // MARK: - POI Notifications Section (Combined Location Always + Notifications)
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(getPOINotificationToggleColor())
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("POI-Mitteilungen")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(getPOINotificationStatusText())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { getPOINotificationToggleState() },
                                set: { newValue in
                                    Task {
                                        await handlePOINotificationToggle(enabled: newValue)
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                        }
                        
                        Text("Erhalte Benachrichtigungen wenn du während einer aktiven Route interessante Orte erreichst. Benötigt Standort-Berechtigung im Hintergrund und Mitteilungen.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Mitteilungen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } footer: {
                Text("Der Toggle fragt automatisch beide benötigten System-Berechtigungen an (Standort im Hintergrund + Mitteilungen). Anschließend können POI-Benachrichtigungen jederzeit aktiviert/deaktiviert werden.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // MARK: - Biometric Security Section
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: biometricIconName)
                        .foregroundColor(biometricSecurityEnabled ? .green : .gray)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Biometrische Sicherung")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(biometricStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { biometricSecurityEnabled },
                                set: { newValue in
                                    settingsManager.updateBiometricSecuritySetting(enabled: newValue)
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                        }
                        
                        Text("Schütze deine persönlichen Bereiche 'Abenteuer' und 'Lieblingsorte' mit \(biometricTypeString). Wenn deaktiviert, ist direkter Zugriff möglich.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Sicherheit")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } footer: {
                Text("Die biometrische Sicherung schützt sensible Profilbereiche. \(biometricAvailabilityText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Berechtigungen")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("profile.permissions.screen")
    }
    
    // MARK: - Hybrid Toggle System Methods
    
    enum LocationPermissionType {
        case whenInUse
        case always
    }
    
    // MARK: - Location Toggle Methods
    
    private func getLocationToggleState(for type: LocationPermissionType) -> Bool {
        switch type {
        case .whenInUse:
            return locationManager.isLocationAuthorized && settingsManager.settings.useCurrentLocationAsDefault
        case .always:
            // This case is now handled by POI notification toggle
            return false
        }
    }
    
    private func getLocationToggleColor(for type: LocationPermissionType) -> Color {
        let isEnabled = getLocationToggleState(for: type)
        return isEnabled ? .green : .gray
    }
    
    private func getLocationStatusText(for type: LocationPermissionType) -> String {
        let systemGranted = type == .whenInUse ? 
            locationManager.isLocationAuthorized : 
            locationManager.authorizationStatus == .authorizedAlways
        let appEnabled = getLocationToggleState(for: type)
        
        if !systemGranted {
            return "Nicht erlaubt"
        } else if appEnabled {
            return "Aktiviert"
        } else {
            return "Deaktiviert"
        }
    }
    
    private func handleLocationToggle(for type: LocationPermissionType, enabled: Bool) async {
        if type == .whenInUse {
            if enabled {
                // User wants to enable - check if system permission exists
                if !locationManager.isLocationAuthorized {
                    // Request system permission first
                    await locationManager.requestLocationPermission()
                    if locationManager.isLocationAuthorized {
                        settingsManager.updateLocationDefault(useCurrentLocation: true)
                    }
                } else {
                    // System permission exists, just enable app setting
                    settingsManager.updateLocationDefault(useCurrentLocation: true)
                }
            } else {
                // User wants to disable - just disable app setting (keep system permission)
                settingsManager.updateLocationDefault(useCurrentLocation: false)
            }
        }
        // .always case is now handled by POI notification toggle
    }
    
    // MARK: - POI Notification Toggle Methods (Combined Location Always + Notifications)
    
    private func getPOINotificationToggleState() -> Bool {
        let hasLocationAlways = locationManager.authorizationStatus == .authorizedAlways
        let hasNotifications = proximityService.notificationPermissionStatus == .authorized
        let appEnabled = settingsManager.settings.poiNotificationsEnabled
        
        return hasLocationAlways && hasNotifications && appEnabled
    }
    
    private func getPOINotificationToggleColor() -> Color {
        return getPOINotificationToggleState() ? .green : .gray
    }
    
    private func getPOINotificationStatusText() -> String {
        let hasLocationAlways = locationManager.authorizationStatus == .authorizedAlways
        let hasNotifications = proximityService.notificationPermissionStatus == .authorized
        let appEnabled = settingsManager.settings.poiNotificationsEnabled
        
        if !hasLocationAlways && !hasNotifications {
            return "Beide Berechtigungen benötigt"
        } else if !hasLocationAlways {
            return "Standort (Hintergrund) benötigt"
        } else if !hasNotifications {
            return "Mitteilungen benötigt"
        } else if appEnabled {
            return "Aktiviert"
        } else {
            return "Deaktiviert"
        }
    }
    
    private func handlePOINotificationToggle(enabled: Bool) async {
        if enabled {
            // User wants to enable - check both system permissions
            let hasLocationAlways = locationManager.authorizationStatus == .authorizedAlways
            let hasNotifications = proximityService.notificationPermissionStatus == .authorized
            
            // Request location permission first if needed
            if !hasLocationAlways {
                await locationManager.requestLocationPermission()
            }
            
            // Request notification permission if needed
            if !hasNotifications {
                let _ = await proximityService.requestNotificationPermission()
            }
            
            // Check if both permissions are now granted
            let finalLocationCheck = locationManager.authorizationStatus == .authorizedAlways
            let finalNotificationCheck = proximityService.notificationPermissionStatus == .authorized
            
            if finalLocationCheck && finalNotificationCheck {
                settingsManager.updatePOINotificationSetting(enabled: true)
            }
        } else {
            // User wants to disable - just disable app setting (keep system permissions)
                        settingsManager.updatePOINotificationSetting(enabled: false)
        }
    }
    
    // MARK: - Biometric Security Helper Properties
    
    private var biometricSecurityEnabled: Bool {
        return settingsManager.isBiometricSecurityEnabled
    }
    
    private var biometricIconName: String {
        return biometricService.authenticationIcon
    }
    
    private var biometricTypeString: String {
        return biometricService.biometryTypeString
    }
    
    private var biometricStatusText: String {
        if !biometricService.isAvailable {
            return "Nicht verfügbar"
        } else if biometricSecurityEnabled {
            return "Aktiviert"
        } else {
            return "Deaktiviert"
        }
    }
    
    private var biometricAvailabilityText: String {
        if biometricService.isSimulator {
            return "Im Simulator ist biometrische Authentifizierung nicht verfügbar."
        } else if !biometricService.isAvailable {
            return "Dein Gerät unterstützt keine biometrische Authentifizierung."
        } else {
            return "\(biometricTypeString) ist verfügbar und einsatzbereit."
        }
    }


}

// MARK: - Preview
#Preview {
    NavigationView {
        PermissionsView()
    }
}
