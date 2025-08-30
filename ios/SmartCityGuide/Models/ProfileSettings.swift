import Foundation
import SwiftUI
import os.log

// MARK: - Profile Settings Model
struct ProfileSettings: Codable {
    // Legacy fields (für Backwards Compatibility)
    var defaultNumberOfPlaces: Int
    var defaultEndpointOption: EndpointOption
    var defaultRouteLength: RouteLength
    var customEndpointDefault: String
    
    // Neue Filter-Einstellungen
    var defaultMaximumStops: MaximumStops
    var defaultMaximumWalkingTime: MaximumWalkingTime
    var defaultMinimumPOIDistance: MinimumPOIDistance
    
    // Phase 3: Location-basierte Einstellungen
    var useCurrentLocationAsDefault: Bool
    
    // Phase 4: POI-Notification-Einstellungen
    var poiNotificationsEnabled: Bool
    
    // Phase 5: Biometric Security Settings
    var biometricSecurityEnabled: Bool?
    
    init() {
        // Legacy Werte für Backwards Compatibility
        self.defaultNumberOfPlaces = 3
        self.defaultEndpointOption = .roundtrip
        self.defaultRouteLength = .medium
        self.customEndpointDefault = ""
        
        // Neue Default-Werte (bessere Defaults für neue User)
        self.defaultMaximumStops = .five      // 5 Stopps ist ein guter Default
        self.defaultMaximumWalkingTime = .sixtyMin  // 60min ist vernünftig
        self.defaultMinimumPOIDistance = .twoFifty  // 250m verhindert zu nah gelegene POIs
        
        // Phase 3: Location-basierte Defaults
        self.useCurrentLocationAsDefault = false  // Konservativ: User muss opt-in
        
        // Phase 4: POI-Notification Defaults
        self.poiNotificationsEnabled = true  // Opt-Out-Approach: POI-Notifications sind ein Core-Feature
        
        // Phase 5: Biometric Security Defaults
        self.biometricSecurityEnabled = true  // Default: Biometrische Sicherung aktiviert
    }
    
    // Migration von alten zu neuen Settings (nur für bestehende User die upgrades)
    mutating func migrateToNewSettings() {
        // Diese Migration sollte nur einmal ausgeführt werden für bestehende User
        // Neue User bekommen bereits die korrekten Defaults im init()
        
        // Migration: numberOfPlaces -> maximumStops (nur wenn noch nicht konvertiert)
        // Überprüfe ob es sich um Legacy-Daten handelt (alle defaults sind noch original)
        let isLegacyData = (defaultMaximumStops == .five && 
                           defaultMaximumWalkingTime == .sixtyMin && 
                           defaultMinimumPOIDistance == .twoFifty)
        
        if isLegacyData {
            // Migration: numberOfPlaces -> maximumStops
            if defaultNumberOfPlaces <= 3 {
                defaultMaximumStops = .three
            } else if defaultNumberOfPlaces <= 5 {
                defaultMaximumStops = .five
            } else {
                defaultMaximumStops = .eight
            }
            
            // Migration: routeLength -> maximumWalkingTime
            switch defaultRouteLength {
            case .short:
                defaultMaximumWalkingTime = .thirtyMin
            case .medium:
                defaultMaximumWalkingTime = .sixtyMin
            case .long:
                defaultMaximumWalkingTime = .twoHours
            }
            
            // Standard-Wert für neuen Filter (bleibt .twoFifty)
            defaultMinimumPOIDistance = .twoFifty
        }
        // Wenn bereits migriert oder customized, nichts tun
    }
}

// MARK: - ProfileSettings Manager with Secure Keychain Storage
@MainActor
class ProfileSettingsManager: ObservableObject {
    static let shared = ProfileSettingsManager()
    
    @Published var settings: ProfileSettings
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let secureStorage = SecureStorageService.shared
    private let secureKey = "profile_settings_secure"
    private let legacyUserDefaultsKey = "profile_settings" // For migration
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "ProfileSettings")
    
    private init() {
        self.settings = ProfileSettings() // Temporary default
        Task {
            await loadSettings()
        }
    }
    
    /// Lädt ProfileSettings aus sicherem Keychain (mit automatischer Migration)
    private func loadSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Versuche Migration von UserDefaults falls nötig
            if let migratedSettings = try secureStorage.migrateFromUserDefaults(
                ProfileSettings.self,
                userDefaultsKey: legacyUserDefaultsKey,
                secureKey: secureKey,
                requireBiometrics: false // Settings sind weniger sensitiv
            ) {
                settings = migratedSettings
                logger.info("⚙️ ProfileSettings: Successfully migrated from UserDefaults")
            }
            // Sonst lade aus Keychain
            else if let savedSettings = try? secureStorage.load(
                ProfileSettings.self,
                forKey: secureKey,
                promptMessage: nil  // Kein automatischer Biometric Prompt
            ) {
                settings = savedSettings
                logger.info("⚙️ ProfileSettings: Loaded from secure storage")
                
                // Migration: Wenn biometricSecurityEnabled fehlt, setze default und speichere
                if settings.biometricSecurityEnabled == nil {
                    settings.biometricSecurityEnabled = true  // Default aktiviert
                    try await saveSettings()
                    logger.info("⚙️ ProfileSettings: Migrated biometricSecurityEnabled to default (true)")
                }
            }
            // Falls nichts existiert, behalte default und speichere
            else {
                settings = ProfileSettings()
                try await saveSettings()
                logger.info("⚙️ ProfileSettings: Created new default settings")
            }
            
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen: \(error.localizedDescription)"
            logger.error("❌ ProfileSettings Load Error: \(error)")
            // Bei Fehler: behalte default settings
            settings = ProfileSettings()
        }
        
        isLoading = false
    }
    
    /// Speichert ProfileSettings sicher im Keychain
    func saveSettings() async throws {
        do {
            try secureStorage.save(
                settings,
                forKey: secureKey,
                requireBiometrics: false // Settings sind weniger sensitiv
            )
            logger.info("⚙️ ProfileSettings: Saved securely")
        } catch {
            errorMessage = "Fehler beim Speichern der Einstellungen: \(error.localizedDescription)"
            logger.error("❌ ProfileSettings Save Error: \(error)")
            throw error
        }
    }
    
    /// Synchrone save-Funktion für Kompatibilität
    func save() {
        Task {
            try? await saveSettings()
        }
    }
    
    func updateDefaults(
        numberOfPlaces: Int? = nil,
        endpointOption: EndpointOption? = nil,
        routeLength: RouteLength? = nil,
        customEndpoint: String? = nil,
        maximumStops: MaximumStops? = nil,
        maximumWalkingTime: MaximumWalkingTime? = nil,
        minimumPOIDistance: MinimumPOIDistance? = nil
    ) {
        // Legacy parameters
        if let numberOfPlaces = numberOfPlaces {
            settings.defaultNumberOfPlaces = numberOfPlaces
        }
        if let endpointOption = endpointOption {
            settings.defaultEndpointOption = endpointOption
        }
        if let routeLength = routeLength {
            settings.defaultRouteLength = routeLength
        }
        if let customEndpoint = customEndpoint {
            settings.customEndpointDefault = customEndpoint
        }
        
        // Neue Parameter
        if let maximumStops = maximumStops {
            settings.defaultMaximumStops = maximumStops
        }
        if let maximumWalkingTime = maximumWalkingTime {
            settings.defaultMaximumWalkingTime = maximumWalkingTime
        }
        if let minimumPOIDistance = minimumPOIDistance {
            settings.defaultMinimumPOIDistance = minimumPOIDistance
        }
        save()
    }
    
    // Phase 3: Update Location Default Setting
    func updateLocationDefault(useCurrentLocation: Bool) {
        settings.useCurrentLocationAsDefault = useCurrentLocation
        save()
    }
    
    // Phase 4: Update POI Notification Setting
    func updatePOINotificationSetting(enabled: Bool) {
        settings.poiNotificationsEnabled = enabled
        save()
        
        // Notify ProximityService about setting change
        NotificationCenter.default.post(
            name: .poiNotificationSettingChanged,
            object: nil,
            userInfo: ["enabled": enabled]
        )
    }
    
    // Phase 5: Update Biometric Security Setting
    func updateBiometricSecuritySetting(enabled: Bool) {
        settings.biometricSecurityEnabled = enabled
        save()
    }
    
    // Helper property für biometric security mit default fallback
    var isBiometricSecurityEnabled: Bool {
        return settings.biometricSecurityEnabled ?? true  // Default: aktiviert
    }
    
    func resetToDefaults() {
        settings = ProfileSettings()
        save()
    }
}

// MARK: - Settings Configuration Helpers
extension ProfileSettings {
    var numberOfPlacesRange: ClosedRange<Int> {
        return 2...5
    }
    
    var isValidNumberOfPlaces: Bool {
        return numberOfPlacesRange.contains(defaultNumberOfPlaces)
    }
    
    func getDefaultsForRoutePlanning() -> (Int, EndpointOption, RouteLength, String) {
        return (
            defaultNumberOfPlaces,
            defaultEndpointOption,
            defaultRouteLength,
            customEndpointDefault
        )
    }
    
    // Neue Helper-Funktion für die neuen Filter
    func getNewDefaultsForRoutePlanning() -> (MaximumStops, EndpointOption, MaximumWalkingTime, MinimumPOIDistance, String) {
        return (
            defaultMaximumStops,
            defaultEndpointOption,
            defaultMaximumWalkingTime,
            defaultMinimumPOIDistance,
            customEndpointDefault
        )
    }
}