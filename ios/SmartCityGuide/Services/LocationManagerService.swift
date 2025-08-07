import Foundation
import CoreLocation
import os.log

/// Service für Location-Management mit Permission-Handling und Position-Updates
/// Implementiert @MainActor für UI-Thread-Safety
@MainActor
class LocationManagerService: ObservableObject {
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Location")
    
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isLocationAvailable: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var locationUpdateContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Singleton
    static let shared = LocationManagerService()
    
    init() {
        setupLocationManager()
        updateLocationAvailability()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = LocationDelegate.shared
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 Meter minimum movement für Updates
        
        // Delegate Callbacks einrichten
        LocationDelegate.shared.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.handleLocationUpdate(location)
            }
        }
        
        LocationDelegate.shared.onLocationError = { [weak self] error in
            Task { @MainActor in
                self?.handleLocationError(error)
            }
        }
        
        LocationDelegate.shared.onAuthorizationChange = { [weak self] status in
            Task { @MainActor in
                self?.handleAuthorizationChange(status)
            }
        }
        
        // Initial authorization status setzen
        authorizationStatus = locationManager.authorizationStatus
        logger.info("LocationManager initialisiert mit Status: \(String(describing: self.authorizationStatus))")
    }
    
    // MARK: - Permission Management
    
    /// Fordert Location-Permission vom User an
    func requestLocationPermission() {
        logger.info("Location-Permission wird angefordert")
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location-Services sind auf diesem Gerät deaktiviert"
            logger.error("Location-Services nicht verfügbar")
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location-Zugriff wurde verweigert. Du kannst ihn in den Einstellungen aktivieren."
            logger.warning("Location-Permission verweigert")
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location-Permission bereits gewährt")
        @unknown default:
            logger.error("Unbekannter Authorization-Status")
        }
    }
    
    /// Fordert Always Location Permission für Background Notifications
    func requestAlwaysLocationPermission() {
        logger.info("Always Location-Permission wird angefordert für Background Notifications")
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location-Services sind auf diesem Gerät deaktiviert"
            logger.error("Location-Services nicht verfügbar")
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            // Erst When In Use anfordern
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Upgrade zu Always
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            logger.info("Always Location-Permission bereits gewährt")
        case .denied, .restricted:
            errorMessage = "Location-Zugriff wurde verweigert. Du kannst ihn in den Einstellungen aktivieren."
            logger.warning("Location-Permission verweigert")
        @unknown default:
            logger.error("Unbekannter Authorization-Status")
        }
    }
    
    /// Prüft ob Location-Services verfügbar sind
    var isLocationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    /// Prüft ob Permission gewährt ist
    var isLocationAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Location Updates
    
    /// Startet kontinuierliche Location-Updates
    func startLocationUpdates() {
        guard isLocationAuthorized else {
            errorMessage = "Location-Permission erforderlich"
            logger.warning("Location-Updates ohne Permission angefordert")
            return
        }
        
        guard isLocationServicesEnabled else {
            errorMessage = "Location-Services sind deaktiviert"
            logger.error("Location-Services nicht verfügbar für Updates")
            return
        }
        
        logger.info("Location-Updates gestartet")
        locationManager.startUpdatingLocation()
    }
    
    /// Startet Background Location Updates für Proximity Monitoring
    func startBackgroundLocationUpdates() {
        guard isLocationAuthorized else {
            errorMessage = "Location-Permission erforderlich für Background-Updates"
            logger.warning("Background Location-Updates ohne Permission angefordert")
            return
        }
        
        guard isLocationServicesEnabled else {
            errorMessage = "Location-Services sind deaktiviert"
            logger.error("Location-Services nicht verfügbar für Background-Updates")
            return
        }
        
        // Configure for background updates
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 meters for proximity detection
        
        // Enable background location updates if permission is "Always"
        if authorizationStatus == .authorizedAlways {
            // Enable background location updates
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            logger.info("🌙 Background Location-Updates aktiviert für Proximity Monitoring")
            
            // Also start significant location changes for background (simulator compatible)
            locationManager.startMonitoringSignificantLocationChanges()
            logger.info("🌙 Significant Location Changes monitoring started for background")
        } else {
            logger.info("📍 Foreground Location-Updates für Proximity Monitoring (Background benötigt 'Always' Permission)")
        }
        
        // Start continuous location updates
        locationManager.startUpdatingLocation()
    }
    
    /// Stoppt Background Location Updates
    func stopBackgroundLocationUpdates() {
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.stopMonitoringSignificantLocationChanges()
            logger.info("🌙 Background Location-Updates und Significant Location Changes gestoppt")
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    /// Stoppt Location-Updates
    func stopLocationUpdates() {
        logger.info("Location-Updates gestoppt")
        locationManager.stopUpdatingLocation()
    }
    
    /// Holt einmalig die aktuelle Position (async/await)
    func getCurrentLocation() async throws -> CLLocation {
        guard isLocationAuthorized else {
            throw LocationError.permissionDenied
        }
        
        guard isLocationServicesEnabled else {
            throw LocationError.locationServicesDisabled
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Falls bereits eine aktuelle Location verfügbar ist (weniger als 30 Sekunden alt)
            if let location = currentLocation,
               abs(location.timestamp.timeIntervalSinceNow) < 30 {
                continuation.resume(returning: location)
                return
            }
            
            // Ansonsten neue Location anfordern
            locationUpdateContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Private Handlers
    
    private func handleLocationUpdate(_ location: CLLocation) {
        logger.info("Location aktualisiert: \(self.formatLocation(location))")
        
        currentLocation = location
        updateLocationAvailability()
        errorMessage = nil
        
        // Phase 4: Trigger proximity check for active routes
        Task {
            await ProximityService.shared.checkProximityToSpots()
        }
        
        // Falls eine Continuation wartet, erfülle sie
        if let continuation = locationUpdateContinuation {
            locationUpdateContinuation = nil
            continuation.resume(returning: location)
        }
    }
    
    private func handleLocationError(_ error: Error) {
        logger.error("Location-Fehler: \(error.localizedDescription)")
        
        let friendlyError: String
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                friendlyError = "Location-Zugriff wurde verweigert"
            case .locationUnknown:
                friendlyError = "Position konnte nicht ermittelt werden"
            case .network:
                friendlyError = "Netzwerkfehler beim Ermitteln der Position"
            case .headingFailure:
                friendlyError = "Kompass-Daten nicht verfügbar"
            default:
                friendlyError = "Fehler beim Ermitteln der Position"
            }
        } else {
            friendlyError = "Unbekannter Location-Fehler"
        }
        
        errorMessage = friendlyError
        
        // Falls eine Continuation wartet, gebe Fehler zurück
        if let continuation = locationUpdateContinuation {
            locationUpdateContinuation = nil
            continuation.resume(throwing: LocationError.locationUpdateFailed(friendlyError))
        }
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        logger.info("Authorization-Status geändert: \(String(describing: status))")
        
        authorizationStatus = status
        updateLocationAvailability()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            logger.info("Location-Permission gewährt")
        case .denied, .restricted:
            errorMessage = "Location-Zugriff verweigert. Du kannst ihn in den Einstellungen aktivieren."
            logger.warning("Location-Permission verweigert")
        case .notDetermined:
            logger.info("Location-Permission noch nicht bestimmt")
        @unknown default:
            logger.error("Unbekannter Authorization-Status: \(String(describing: status))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateLocationAvailability() {
        isLocationAvailable = isLocationServicesEnabled && isLocationAuthorized && currentLocation != nil
        logger.debug("Location-Verfügbarkeit aktualisiert: \(self.isLocationAvailable)")
    }
    
    /// Formatiert CLLocation für Debug-Ausgabe
    private func formatLocation(_ location: CLLocation) -> String {
        return String(format: "%.6f, %.6f (±%.0fm)", 
                     location.coordinate.latitude,
                     location.coordinate.longitude,
                     location.horizontalAccuracy)
    }
}

// MARK: - LocationDelegate

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDelegate()
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationError: ((Error) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationError?(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange?(status)
    }
}

// MARK: - LocationError

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServicesDisabled
    case locationUpdateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location-Permission wurde verweigert"
        case .locationServicesDisabled:
            return "Location-Services sind deaktiviert"
        case .locationUpdateFailed(let message):
            return "Location-Update fehlgeschlagen: \(message)"
        }
    }
}