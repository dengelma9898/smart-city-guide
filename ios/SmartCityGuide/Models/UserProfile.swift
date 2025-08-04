import Foundation
import SwiftUI
import os.log

// MARK: - User Profile Model
struct UserProfile: Codable {
    var name: String
    var email: String
    var profileImagePath: String?
    var createdAt: Date
    var lastActiveAt: Date
    
    init(name: String = "Max Mustermann", email: String = "max.mustermann@email.de") {
        self.name = name
        self.email = email
        self.profileImagePath = nil
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
    
    // Update last active timestamp
    mutating func updateLastActive() {
        self.lastActiveAt = Date()
    }
}

// MARK: - UserProfile Manager with Secure Keychain Storage
@MainActor
class UserProfileManager: ObservableObject {
    @Published var profile: UserProfile
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let secureStorage = SecureStorageService.shared
    private let secureKey = "user_profile_secure"
    private let legacyUserDefaultsKey = "user_profile" // For migration
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "UserProfile")
    
    init() {
        self.profile = UserProfile() // Temporary default
        Task {
            await loadProfile()
        }
    }
    
    /// Lädt UserProfile aus sicherem Keychain (mit automatischer Migration)
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Versuche Migration von UserDefaults falls nötig
            if let migratedProfile = try secureStorage.migrateFromUserDefaults(
                UserProfile.self,
                userDefaultsKey: legacyUserDefaultsKey,
                secureKey: secureKey,
                requireBiometrics: true
            ) {
                profile = migratedProfile
                logger.info("📱 UserProfile: Successfully migrated from UserDefaults")
            }
            // Sonst lade aus Keychain
            else if let savedProfile = try secureStorage.load(
                UserProfile.self,
                forKey: secureKey,
                promptMessage: "Authentifiziere dich, um dein Profil zu laden"
            ) {
                profile = savedProfile
                logger.info("📱 UserProfile: Loaded from secure storage")
            }
            // Falls nichts existiert, behalte default und speichere
            else {
                profile = UserProfile()
                try await saveProfile()
                logger.info("📱 UserProfile: Created new default profile")
            }
            
        } catch {
            errorMessage = "Fehler beim Laden des Profils: \(error.localizedDescription)"
            logger.error("❌ UserProfile Load Error: \(error)")
            // Bei Fehler: behalte default profile
            profile = UserProfile()
        }
        
        isLoading = false
    }
    
    /// Speichert UserProfile sicher im Keychain
    func saveProfile() async throws {
        profile.updateLastActive()
        
        do {
            try secureStorage.save(
                profile,
                forKey: secureKey,
                requireBiometrics: true
            )
            logger.info("📱 UserProfile: Saved securely")
        } catch {
            errorMessage = "Fehler beim Speichern des Profils: \(error.localizedDescription)"
            logger.error("❌ UserProfile Save Error: \(error)")
            throw error
        }
    }
    
    /// Synchrone save-Funktion für Kompatibilität
    func save() {
        Task {
            try? await saveProfile()
        }
    }
    
    func updateProfile(name: String? = nil, email: String? = nil, profileImagePath: String? = nil) {
        if let name = name { profile.name = name }
        if let email = email { profile.email = email }
        if let imagePath = profileImagePath { profile.profileImagePath = imagePath }
        save() // Uses async wrapper
    }
    
    func setProfileImage(path: String?) {
        profile.profileImagePath = path
        save() // Uses async wrapper
    }
    
    /// Löscht UserProfile aus sicherem Storage (für App-Reset)
    func deleteProfile() async throws {
        try secureStorage.delete(forKey: secureKey)
        profile = UserProfile() // Reset to default
                    logger.info("📱 UserProfile: Deleted from secure storage")
    }
}

// MARK: - Profile Image Helper
struct ProfileImageHelper {
    private static let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "ProfileImage")
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func saveImage(_ imageData: Data) -> String? {
        let filename = "profile_\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: url)
            return filename
        } catch {
            Self.logger.error("Failed to save profile image: \(error)")
            return nil
        }
    }
    
    static func loadImage(from path: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    static func deleteImage(at path: String) {
        let url = documentsDirectory.appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
    }
}