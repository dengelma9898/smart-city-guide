import Foundation
import CoreLocation

/// Service für das Extrahieren von Stadtnamen aus Koordinaten
@MainActor
class CityNameService: ObservableObject {
    
    @Published var currentCityName: String?
    
    private let geocoder = CLGeocoder()
    private var lastLocation: CLLocation?
    
    /// Extrahiert den Stadtnamen aus den gegebenen Koordinaten
    /// - Parameter location: Die Location für die der Stadtname ermittelt werden soll
    func updateCityName(from location: CLLocation?) async {
        guard let location = location else {
            currentCityName = nil
            return
        }
        
        // Avoid unnecessary calls if location hasn't changed significantly
        if let lastLocation = lastLocation,
           location.distance(from: lastLocation) < 1000 { // 1km threshold
            return
        }
        
        self.lastLocation = location
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                // Prioritize locality (city), then administrative area (state/region)
                let cityName = placemark.locality ?? 
                               placemark.administrativeArea ?? 
                               placemark.subAdministrativeArea ??
                               placemark.country
                
                await MainActor.run {
                    self.currentCityName = cityName
                }
                
                SecureLogger.shared.logCity(cityName ?? "Unknown", context: "Reverse geocoding resolved")
            }
        } catch {
            SecureLogger.shared.logWarning("Failed to resolve city name: \(error.localizedDescription)")
            await MainActor.run {
                self.currentCityName = nil
            }
        }
    }
    
    /// Löscht den aktuellen Stadtnamen
    func clearCityName() {
        currentCityName = nil
        lastLocation = nil
    }
}
