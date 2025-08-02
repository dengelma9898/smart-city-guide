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

// MARK: - ProfileSettings Manager with UserDefaults
@MainActor
class ProfileSettingsManager: ObservableObject {
    @Published var settings: ProfileSettings
    
    private let userDefaultsKey = "profile_settings"
    
    init() {
        // Load from UserDefaults or create default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedSettings = try? JSONDecoder().decode(ProfileSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = ProfileSettings()
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
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