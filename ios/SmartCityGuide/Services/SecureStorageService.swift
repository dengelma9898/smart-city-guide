import Foundation
import Security
import LocalAuthentication
import os.log

// MARK: - Secure Storage Service for Keychain

/// Sichere Keychain-basierte Speicherung für persönliche Daten
/// Implementiert OWASP iOS Security Best Practices mit biometrischer Authentifizierung
@MainActor
class SecureStorageService: ObservableObject {
    static let shared = SecureStorageService()
    
    private let serviceName = "de.dengelma.smartcity-guide.secure"
    private let accessGroup: String? = nil // Kann für App Groups verwendet werden
    
    @Published var isAvailable = false
    @Published var biometricsEnabled = false
    
    // Enhanced Logging für Security Debugging
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "SecureStorage")
    
    private init() {
        // EXPLICIT DEBUG TEST - Dies sollte IMMER erscheinen
        logger.critical("🔴 CRITICAL DEBUG: SecureStorageService.init() CALLED!")
        print("🔴 EXPLICIT PRINT: SecureStorageService init called!")
        
        checkAvailability()
        
        // Test Keychain Zugriff direkt
        testKeychainAccess()
    }
    
    // MARK: - Availability Checks
    
    private func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        
        // Check if device supports biometric authentication
        biometricsEnabled = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        // Check basic Keychain availability
        isAvailable = true // Keychain is always available on iOS
        
        #if targetEnvironment(simulator)
        logger.info("🔐 SecureStorage: Running in SIMULATOR - Biometrics disabled by default")
        biometricsEnabled = false // Force disable in simulator
        #endif
        
        logger.info("🔐 SecureStorage: Biometrics available: \(self.biometricsEnabled)")
        logger.info("🔐 SecureStorage: Keychain available: \(self.isAvailable)")
        
        if let error = error {
            logger.error("🔐 SecureStorage: Biometric check error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generic Save/Load Methods
    
    /// Sichere Speicherung von Codable-Objekten im Keychain
    /// - Parameters:
    ///   - data: Das zu speichernde Codable-Objekt
    ///   - key: Eindeutiger Schlüssel für die Speicherung
    ///   - requireBiometrics: Ob biometrische Authentifizierung erforderlich ist
    func save<T: Codable>(_ data: T, forKey key: String, requireBiometrics: Bool = true) throws {
        // JSON-Enkodierung
        let jsonData = try JSONEncoder().encode(data)
        
        // Erstelle Access Control mit biometrischer Authentifizierung
        let accessControl = try createAccessControl(requireBiometrics: requireBiometrics)
        
        // Keychain Query erstellen
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: jsonData
        ]
        
        // Access Control hinzufügen
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        } else {
            // Fallback für Geräte ohne Biometrics
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        // Access Group falls konfiguriert
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Alten Eintrag löschen falls vorhanden
        SecItemDelete(query as CFDictionary)
        
        // Neuen Eintrag hinzufügen
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            logger.error("🔐 SecureStorage: Save failed for '\(key)' with status: \(status)")
            throw SecureStorageError.saveFailed(status: status)
        }
        
        logger.info("🔐 SecureStorage: Successfully saved '\(key)'")
    }
    
    /// Sichere Ladung von Codable-Objekten aus dem Keychain
    /// - Parameters:
    ///   - type: Der Typ des zu ladenden Objekts
    ///   - key: Der Schlüssel der gespeicherten Daten
    ///   - promptMessage: Biometrische Authentifizierung Nachricht
    /// - Returns: Das geladene Objekt oder nil falls nicht vorhanden
    func load<T: Codable>(_ type: T.Type, forKey key: String, promptMessage: String? = nil) throws -> T? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Access Group falls konfiguriert
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Biometric prompt mit moderner LAContext API (iOS 14+)
        if let message = promptMessage {
            let context = LAContext()
            context.localizedReason = message
            query[kSecUseAuthenticationContext as String] = context
        }
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil // Normal case - item doesn't exist yet
            }
            throw SecureStorageError.loadFailed(status: status)
        }
        
        guard let data = result as? Data else {
            throw SecureStorageError.invalidData
        }
        
        // JSON-Dekodierung
        let decodedObject = try JSONDecoder().decode(type, from: data)
        logger.info("🔐 SecureStorage: Successfully loaded '\(key)'")
        
        return decodedObject
    }
    
    /// Sicheres Löschen von Keychain-Einträgen
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("🔐 SecureStorage: Delete failed for '\(key)' with status: \(status)")
            throw SecureStorageError.deleteFailed(status: status)
        }
        
        logger.info("🔐 SecureStorage: Successfully deleted '\(key)'")
    }
    
    /// Alle gespeicherten Daten löschen (für App-Reset)
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.deleteFailed(status: status)
        }
        
        print("🔐 SecureStorage: Cleared all data successfully")
    }
    
    // MARK: - Access Control Creation
    
    private func createAccessControl(requireBiometrics: Bool) throws -> SecAccessControl? {
        guard requireBiometrics && biometricsEnabled else {
            return nil // Fallback to standard protection
        }
        
        var error: Unmanaged<CFError>?
        
        // Verwende kSecAccessControlBiometryCurrentSet für höchste Sicherheit
        // Dies macht Daten unzugänglich wenn neue Biometrics hinzugefügt werden
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, // Device-only, unlocked required
            .biometryCurrentSet, // Höchste Sicherheit - OWASP empfohlen
            &error
        )
        
        if let error = error {
            throw SecureStorageError.accessControlFailed(error: error.takeRetainedValue())
        }
        
        return accessControl
    }
    
    // MARK: - Migration Helpers
    
    /// Migriert Daten von UserDefaults zu sicherem Keychain
    func migrateFromUserDefaults<T: Codable>(
        _ type: T.Type,
        userDefaultsKey: String,
        secureKey: String,
        requireBiometrics: Bool = true
    ) throws -> T? {
        // Prüfe ob Daten bereits in Keychain sind
        if let existingData = try? load(type, forKey: secureKey) {
            logger.info("🔐 Migration: Data already exists in Keychain for '\(secureKey)'")
            return existingData
        }
        
        // Lade Daten aus UserDefaults
        guard let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decodedData = try? JSONDecoder().decode(type, from: userData) else {
            logger.info("🔐 Migration: No data found in UserDefaults for '\(userDefaultsKey)'")
            return nil
        }
        
        // Speichere in sicherem Keychain
        try save(decodedData, forKey: secureKey, requireBiometrics: requireBiometrics)
        
        // Entferne aus UserDefaults nach erfolgreicher Migration
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        logger.info("🔐 Migration: Successfully migrated '\(userDefaultsKey)' to secure storage")
        return decodedData
    }
    
    // MARK: - Debug & Testing
    
    private func testKeychainAccess() {
        logger.critical("🔴 DEBUG: Testing basic Keychain access...")
        
        let testKey = "debug_test_key"
        let testData = "Hello Keychain Test"
        
        do {
            try save(testData, forKey: testKey, requireBiometrics: false)
            logger.info("🔴 DEBUG: Test save successful")
            
            if let loaded: String = try load(String.self, forKey: testKey) {
                logger.info("🔴 DEBUG: Test load successful: \(loaded)")
            }
            
            try delete(forKey: testKey)
            logger.info("🔴 DEBUG: Test delete successful")
            
        } catch {
            logger.error("🔴 DEBUG: Keychain test failed: \(error)")
        }
    }
}

// MARK: - Error Handling

enum SecureStorageError: LocalizedError {
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case accessControlFailed(error: CFError)
    case invalidData
    case biometricsNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save data to Keychain (Status: \(status))"
        case .loadFailed(let status):
            return "Failed to load data from Keychain (Status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete data from Keychain (Status: \(status))"
        case .accessControlFailed(let error):
            return "Failed to create access control: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data format in Keychain"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        }
    }
}

// MARK: - Keychain Status Code Helper

extension OSStatus {
    var keychainErrorDescription: String {
        switch self {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecAuthFailed:
            return "Authentication failed"
        case -128: // errSecUserCancel equivalent
            return "User canceled authentication"
        case errSecNotAvailable:
            return "No keychain is available"
        default:
            return "Unknown error (\(self))"
        }
    }
}