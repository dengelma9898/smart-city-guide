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
    
    init() {
        // Legacy Werte für Backwards Compatibility
        self.defaultNumberOfPlaces = 3
        self.defaultEndpointOption = .roundtrip
        self.defaultRouteLength = .medium
        self.customEndpointDefault = ""
        
        // Neue Default-Werte
        self.defaultMaximumStops = .five
        self.defaultMaximumWalkingTime = .sixtyMin
        self.defaultMinimumPOIDistance = .twoFifty
    }
    
    // Migration von alten zu neuen Settings
    mutating func migrateToNewSettings() {
        // Migration: numberOfPlaces -> maximumStops
        if defaultNumberOfPlaces <= 3 {
            defaultMaximumStops = .three
        } else if defaultNumberOfPlaces <= 5 {
            defaultMaximumStops = .five
        } else {
            defaultMaximumStops = .ten
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
        
        // Standard-Wert für neuen Filter
        defaultMinimumPOIDistance = .twoFifty
    }
}

// MARK: - ProfileSettings Manager with Secure Keychain Storage
@MainActor
class ProfileSettingsManager: ObservableObject {
    @Published var settings: ProfileSettings
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let secureStorage = SecureStorageService.shared
    private let secureKey = "profile_settings_secure"
    private let legacyUserDefaultsKey = "profile_settings" // For migration
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "ProfileSettings")
    
    init() {
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
            else if let savedSettings = try secureStorage.load(
                ProfileSettings.self,
                forKey: secureKey
            ) {
                settings = savedSettings
                logger.info("⚙️ ProfileSettings: Loaded from secure storage")
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