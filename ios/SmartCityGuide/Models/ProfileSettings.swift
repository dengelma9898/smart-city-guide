import Foundation
import SwiftUI

// MARK: - Profile Settings Model
struct ProfileSettings: Codable {
    var defaultNumberOfPlaces: Int
    var defaultEndpointOption: EndpointOption
    var defaultRouteLength: RouteLength
    var customEndpointDefault: String
    
    init() {
        self.defaultNumberOfPlaces = 3
        self.defaultEndpointOption = .roundtrip
        self.defaultRouteLength = .medium
        self.customEndpointDefault = ""
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
                print("⚙️ ProfileSettings: Successfully migrated from UserDefaults")
            }
            // Sonst lade aus Keychain
            else if let savedSettings = try secureStorage.load(
                ProfileSettings.self,
                forKey: secureKey
            ) {
                settings = savedSettings
                print("⚙️ ProfileSettings: Loaded from secure storage")
            }
            // Falls nichts existiert, behalte default und speichere
            else {
                settings = ProfileSettings()
                try await saveSettings()
                print("⚙️ ProfileSettings: Created new default settings")
            }
            
        } catch {
            errorMessage = "Fehler beim Laden der Einstellungen: \(error.localizedDescription)"
            print("❌ ProfileSettings Load Error: \(error)")
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
            print("⚙️ ProfileSettings: Saved securely")
        } catch {
            errorMessage = "Fehler beim Speichern der Einstellungen: \(error.localizedDescription)"
            print("❌ ProfileSettings Save Error: \(error)")
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
        customEndpoint: String? = nil
    ) {
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
}