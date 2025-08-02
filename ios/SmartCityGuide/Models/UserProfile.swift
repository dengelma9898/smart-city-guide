import Foundation
import SwiftUI

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

// MARK: - UserProfile Manager with UserDefaults
@MainActor
class UserProfileManager: ObservableObject {
    @Published var profile: UserProfile
    
    private let userDefaultsKey = "user_profile"
    
    init() {
        // Load from UserDefaults or create default
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = UserProfile()
            save() // Save default profile
        }
    }
    
    func save() {
        profile.updateLastActive()
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func updateProfile(name: String? = nil, email: String? = nil, profileImagePath: String? = nil) {
        if let name = name { profile.name = name }
        if let email = email { profile.email = email }
        if let imagePath = profileImagePath { profile.profileImagePath = imagePath }
        save()
    }
    
    func setProfileImage(path: String?) {
        profile.profileImagePath = path
        save()
    }
}

// MARK: - Profile Image Helper
struct ProfileImageHelper {
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func saveImage(_ imageData: Data) -> String? {
        let filename = "profile_\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: url)
            return filename
        } catch {
            print("Failed to save profile image: \(error)")
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