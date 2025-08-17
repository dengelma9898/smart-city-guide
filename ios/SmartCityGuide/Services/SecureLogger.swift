import Foundation
import os.log
import CoreLocation

// MARK: - Secure Logging Service

/// Sicheres Logging-System das sensitive Daten nur im Debug-Modus ausgibt
/// Implementiert OWASP iOS Security Best Practices für Data Leakage Prevention
class SecureLogger {
    static let shared = SecureLogger()
    
    // Verschiedene Logger-Kategorien für bessere Organisation
    private let networkLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Network")
    private let locationLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Location")
    private let routeLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Route")
    private let cacheLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Cache")
    private let profileLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "Profile")
    private let generalLogger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "General")
    
    // Debug Flag - wird automatisch basierend auf Build-Konfiguration gesetzt
    private let isDebugMode: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    private init() {
        generalLogger.info("🔐 SecureLogger initialized - Debug mode: \(self.isDebugMode)")
    }
    
    // MARK: - Network Logging (API Calls, URLs, Responses)
    
    /// Loggt API-Requests sicher
    func logAPIRequest(url: String, method: String = "GET", category: APICategory = .general) {
        let sanitizedURL = sanitizeURL(url)
        
        if isDebugMode {
            networkLogger.info("🌐 \(method) \(sanitizedURL)")
        } else {
            networkLogger.info("🌐 \(method) API request to \(category.description)")
        }
    }
    
    /// Loggt API-Responses sicher
    func logAPIResponse(statusCode: Int, responseSize: Int, category: APICategory = .general) {
        if isDebugMode {
            networkLogger.info("📡 Response \(statusCode) - \(responseSize) bytes from \(category.description)")
        } else {
            networkLogger.info("📡 Response \(statusCode) - \(responseSize) bytes")
        }
    }
    
    /// Loggt API Response-Daten (nur Metadaten in Production)
    func logAPIResponseData(_ data: String, category: APICategory = .general) {
        if isDebugMode {
            // Im Debug-Modus: zeige ersten Teil der Response
            let preview = String(data.prefix(200))
            networkLogger.debug("📄 API Response preview: \(preview)...")
        } else {
            // In Production: nur Metadaten
            networkLogger.info("📄 API response received (\(data.count) chars)")
        }
    }
    
    /// Loggt API-Fehler sicher
    func logAPIError(_ error: Error, url: String? = nil, category: APICategory = .general) {
        if let url = url {
            let sanitizedURL = sanitizeURL(url)
            networkLogger.error("❌ API Error at \(sanitizedURL): \(error.localizedDescription)")
        } else {
            networkLogger.error("❌ API Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Location Logging (GPS Coordinates, Addresses)
    
    /// Loggt GPS-Koordinaten sicher
    func logCoordinates(_ coordinates: CLLocationCoordinate2D, context: String = "location") {
        if isDebugMode {
            // Im Debug-Modus: zeige teilweise Koordinaten
            let maskedLat = String(format: "%.4f••••", coordinates.latitude)
            let maskedLng = String(format: "%.4f••••", coordinates.longitude)
            locationLogger.info("📍 \(context): lat=\(maskedLat), lng=\(maskedLng)")
        } else {
            // In Production: keine Koordinaten
            locationLogger.info("📍 \(context): coordinates processed")
        }
    }
    
    /// Loggt Adressen sicher
    func logAddress(_ address: String, context: String = "address") {
        if isDebugMode {
            // Im Debug-Modus: zeige nur Stadt und maskiere Details
            let maskedAddress = maskSensitiveAddress(address)
            locationLogger.info("🏠 \(context): \(maskedAddress)")
        } else {
            // In Production: keine Details
            locationLogger.info("🏠 \(context): address processed")
        }
    }
    
    /// Loggt Städte (weniger sensitiv, aber trotzdem kontrolliert)
    func logCity(_ cityName: String, context: String = "city") {
        // Städtenamen sind weniger sensitiv, aber wir loggen sie trotzdem kontrolliert
        locationLogger.info("🏙️ \(context): \(cityName)")
    }
    
    // MARK: - Route Logging
    
    /// Loggt Route-Generierung sicher
    func logRouteGeneration(waypointCount: Int, distance: Double, context: String = "route") {
        if isDebugMode {
            routeLogger.info("🗺️ \(context): \(waypointCount) waypoints, ~\(Int(distance/1000))km")
        } else {
            routeLogger.info("🗺️ \(context): route generated with \(waypointCount) stops")
        }
    }
    
    /// Loggt Route-Testing sicher
    func logRouteTest(waypoints: Int, airlineDistance: Int, actualDistance: Int, limit: Int) {
        if isDebugMode {
            routeLogger.info("🔍 Route test: \(waypoints) waypoints, airline: \(airlineDistance)km, actual: \(actualDistance)km (limit: \(limit)km)")
        } else {
            routeLogger.info("🔍 Route validation completed")
        }
    }
    
    // MARK: - Cache Logging
    
    /// Loggt Cache-Operationen sicher
    func logCacheOperation(_ operation: CacheOperation, key: String, count: Int? = nil) {
        let sanitizedKey = sanitizeCacheKey(key)
        
        if let count = count {
            cacheLogger.info("💾 \(operation.emoji) \(operation.description): \(sanitizedKey) (\(count) items)")
        } else {
            cacheLogger.info("💾 \(operation.emoji) \(operation.description): \(sanitizedKey)")
        }
    }
    
    // MARK: - Profile & User Data Logging
    
    /// Loggt Profil-Operationen sicher (niemals persönliche Daten)
    func logProfileOperation(_ operation: ProfileOperation, context: String = "") {
        profileLogger.info("👤 \(operation.emoji) \(operation.description) \(context)")
    }
    
    // MARK: - General Logging
    
    /// Loggt allgemeine Informationen
    func logInfo(_ message: String, category: LogCategory = .general) {
        generalLogger.info("\(category.emoji) \(message)")
    }
    
    /// Loggt Warnungen
    func logWarning(_ message: String, category: LogCategory = .general) {
        generalLogger.warning("\(category.emoji) ⚠️ \(message)")
    }
    
    /// Loggt Fehler
    func logError(_ message: String, category: LogCategory = .general) {
        generalLogger.error("\(category.emoji) ❌ \(message)")
    }
    
    /// Loggt Debug-Nachrichten nur in Debug/UITEST-Umgebungen
    func logDebug(_ message: String, category: LogCategory = .general) {
        let isUITest = ProcessInfo.processInfo.environment["UITEST"] == "1"
        if isDebugMode || isUITest {
            generalLogger.debug("\(category.emoji) \(message)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Maskiert URLs um API-Keys und sensitive Parameter zu verstecken
    private func sanitizeURL(_ url: String) -> String {
        guard var urlComponents = URLComponents(string: url) else { return "<INVALID_URL>" }
        
        // Entferne oder maskiere sensitive Query-Parameter
        if var queryItems = urlComponents.queryItems {
            for i in 0..<queryItems.count {
                let item = queryItems[i]
                
                // Bekannte sensitive Parameter
                if item.name.lowercased().contains("key") || 
                   item.name.lowercased().contains("token") ||
                   item.name.lowercased().contains("secret") {
                    queryItems[i].value = "<REDACTED>"
                }
                
                // Lange Werte (potentiell sensitive)
                if let value = item.value, value.count > 20 {
                    queryItems[i].value = "<REDACTED>"
                }
            }
            urlComponents.queryItems = queryItems
        }
        
        // Stelle sicher, dass keine API-Keys in der URL stehen
        let result = urlComponents.url?.absoluteString ?? "<MALFORMED_URL>"
        
        // Zusätzliche Maskierung für bekannte Patterns
        return result
            .replacingOccurrences(of: #"[A-Za-z0-9]{20,}"#, with: "<REDACTED>", options: .regularExpression)
    }
    
    /// Maskiert sensitive Adressdaten
    private func maskSensitiveAddress(_ address: String) -> String {
        // Extrahiere nur die Stadt und maskiere Straße/Hausnummer
        let components = address.components(separatedBy: ",")
        
        if components.count > 1 {
            // Zeige nur die Stadt (normalerweise letzter oder vorletzter Teil)
            let city = components.last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
            return "***Street***, \(city)"
        } else {
            // Falls Format unbekannt, maskiere teilweise
            return address.count > 10 ? "\(address.prefix(3))••••••" : "<MASKED>"
        }
    }
    
    /// Sanitized Cache-Keys (entfernt potentiell sensitive Daten)
    private func sanitizeCacheKey(_ key: String) -> String {
        // Cache-Keys könnten Städtenamen enthalten - das ist OK
        // Aber entferne potentiell sensitive Parameter
        return key.replacingOccurrences(of: #"[0-9]{4,}"#, with: "<NUM>", options: .regularExpression)
    }
}

// MARK: - Supporting Enums

enum APICategory: CaseIterable {
    case geoapify
    case geocoding
    case general
    
    var description: String {
        switch self {
        case .geoapify: return "Geoapify API"
        case .geocoding: return "Geocoding API"
        case .general: return "API"
        }
    }
}

enum CacheOperation: CaseIterable {
    case hit
    case miss
    case store
    case clear
    case expire
    
    var emoji: String {
        switch self {
        case .hit: return "✅"
        case .miss: return "❌"
        case .store: return "💾"
        case .clear: return "🗑️"
        case .expire: return "⏰"
        }
    }
    
    var description: String {
        switch self {
        case .hit: return "Cache hit"
        case .miss: return "Cache miss"
        case .store: return "Cache store"
        case .clear: return "Cache clear"
        case .expire: return "Cache expire"
        }
    }
}

enum ProfileOperation: CaseIterable {
    case load
    case save
    case migrate
    case delete
    case update
    
    var emoji: String {
        switch self {
        case .load: return "📥"
        case .save: return "💾"
        case .migrate: return "🔄"
        case .delete: return "🗑️"
        case .update: return "✏️"
        }
    }
    
    var description: String {
        switch self {
        case .load: return "Profile loaded"
        case .save: return "Profile saved"
        case .migrate: return "Profile migrated"
        case .delete: return "Profile deleted"
        case .update: return "Profile updated"
        }
    }
}

enum LogCategory: CaseIterable {
    case general
    case security
    case performance
    case ui
    case data
    case geoapify
    
    var emoji: String {
        switch self {
        case .general: return "ℹ️"
        case .security: return "🔐"
        case .performance: return "⚡"
        case .ui: return "🎨"
        case .data: return "📊"
        case .geoapify: return "🌍"
        }
    }
}

// MARK: - Convenience Extensions

extension SecureLogger {
    /// Schneller Zugriff für häufige Operations
    func logPOISearch(cityName: String, poiCount: Int) {
        logInfo("POI search completed for \(cityName): \(poiCount) results", category: .data)
    }
    
    func logRouteCalculation(waypoints: Int, duration: TimeInterval) {
        logInfo("Route calculated: \(waypoints) waypoints in \(String(format: "%.2f", duration))s", category: .performance)
    }
    
    /// Log detailed route performance metrics comparing sequential vs parallel execution
    /// - Parameters:
    ///   - waypoints: Number of waypoints in the route
    ///   - duration: Total time taken for route calculation
    ///   - parallel: Whether parallel processing was used
    ///   - concurrentTasks: Number of concurrent tasks (if parallel)
    ///   - category: Log category (defaults to .performance)
    func logRoutePerformance(
        waypoints: Int,
        duration: TimeInterval,
        parallel: Bool,
        concurrentTasks: Int = 1,
        category: LogCategory = .performance
    ) {
        let mode = parallel ? "parallel(\(concurrentTasks))" : "sequential"
        let throughput = Double(waypoints - 1) / duration // Routes = waypoints - 1
        let formattedThroughput = String(format: "%.1f", throughput)
        let formattedDuration = String(format: "%.2f", duration)
        
        logInfo("🏎️ Route perf: \(waypoints) wp → \(waypoints - 1) routes in \(formattedDuration)s (\(mode), \(formattedThroughput) routes/s)", category: category)
    }
    
    /// Log route performance baseline for comparison
    /// - Parameters:
    ///   - waypoints: Number of waypoints
    ///   - sequentialDuration: Time taken with sequential processing
    ///   - parallelDuration: Time taken with parallel processing
    ///   - improvement: Performance improvement percentage
    func logRoutePerformanceComparison(
        waypoints: Int,
        sequentialDuration: TimeInterval,
        parallelDuration: TimeInterval,
        improvement: Double
    ) {
        let seqFormatted = String(format: "%.2f", sequentialDuration)
        let parFormatted = String(format: "%.2f", parallelDuration)
        let improvementFormatted = String(format: "%.1f", improvement)
        
        logInfo("📊 Perf comparison: \(waypoints) wp → seq: \(seqFormatted)s vs par: \(parFormatted)s (\(improvementFormatted)% improvement)", category: .performance)
    }
    
    func logUserAction(_ action: String) {
        logInfo("User action: \(action)", category: .ui)
    }
}