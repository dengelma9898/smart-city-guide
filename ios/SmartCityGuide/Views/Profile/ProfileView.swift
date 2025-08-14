import SwiftUI

// MARK: - Enhanced Profile View
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager()
    @StateObject private var settingsManager = ProfileSettingsManager.shared
    @StateObject private var historyManager = RouteHistoryManager()
    
    // Sheets für Unterseiten entfallen – alle Unterseiten öffnen via Push
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Profile Header
                    VStack(spacing: 16) {
                        ProfileImageView()
                            .environmentObject(profileManager)
                        
                        VStack(spacing: 8) {
                            Text(profileManager.profile.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .accessibilityIdentifier("profile.header.name.label")
                            
                            Text(profileManager.profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: EditProfileView().environmentObject(profileManager)) {
                                Text("Los, ändere dein Profil!")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .accessibilityIdentifier("profile.open.edit.button")
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick Stats with Achievement Badges
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("\(historyManager.savedRoutes.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    if historyManager.savedRoutes.count >= 10 {
                                        Text("🏆")
                                            .font(.caption)
                                    } else if historyManager.savedRoutes.count >= 5 {
                                        Text("🌟")
                                            .font(.caption)
                                    }
                                }
                                Text("Touren")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("\(totalDistance)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    if totalDistanceValue >= 50 {
                                        Text("🚶‍♂️")
                                            .font(.caption)
                                    } else if totalDistanceValue >= 20 {
                                        Text("👟")
                                            .font(.caption)
                                    }
                                }
                                Text("Kilometer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("\(daysSinceJoined)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    if daysSinceJoined >= 30 {
                                        Text("🎯")
                                            .font(.caption)
                                    } else if daysSinceJoined >= 7 {
                                        Text("📅")
                                            .font(.caption)
                                    }
                                }
                                Text("Tage mit uns")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Achievement Level
                        if let achievement = currentAchievement {
                            HStack(spacing: 8) {
                                Text(achievement.emoji)
                                    .font(.title3)
                                Text(achievement.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Enhanced Profile Options (use NavigationLink for platform-consistent UX)
                    VStack(spacing: 0) {
                        // Route History
                        NavigationLink(destination: RouteHistoryView().environmentObject(historyManager)) {
                            ProfileRow(
                                icon: "clock.fill",
                                title: "Deine Abenteuer",
                                subtitle: "\(historyManager.savedRoutes.count) coole Touren erlebt"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Settings
                        NavigationLink(destination: ProfileSettingsView().environmentObject(settingsManager)) {
                            ProfileRow(
                                icon: "gearshape.fill",
                                title: "Deine Präferenzen",
                                subtitle: "So wie du's magst!"
                            )
                        }
                        .accessibilityIdentifier("profile.open.settings.button")
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Saved Places (placeholder)
                        NavigationLink(destination: Text("Bald verfügbar").padding()) {
                            ProfileRow(
                                icon: "location.fill",
                                title: "Deine Lieblingsorte",
                                subtitle: "Die coolsten Spots!"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Help & Support
                        NavigationLink(destination: HelpSupportView()) {
                            ProfileRow(
                                icon: "questionmark.circle.fill",
                                title: "Brauchst du Hilfe?",
                                subtitle: "Wir helfen gerne!"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Legal Sektion
                    VStack(spacing: 0) {
                        // Impressum
                        NavigationLink(destination: ImpressumView()) {
                            ProfileRow(
                                icon: "doc.text.fill",
                                title: "Impressum",
                                subtitle: "Rechtliche Informationen"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // AGB
                        NavigationLink(destination: AGBView()) {
                            ProfileRow(
                                icon: "doc.plaintext.fill",
                                title: "AGB",
                                subtitle: "Nutzungsbedingungen"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Datenschutzerklärung
                        NavigationLink(destination: DatenschutzerklaerungView()) {
                            ProfileRow(
                                icon: "hand.raised.fill",
                                title: "Datenschutzerklärung",
                                subtitle: "Deine Daten sind sicher!"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        .navigationTitle("Dein Profil")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityIdentifier("profile.root.screen")
        // Keine Sheet-Präsentationen mehr für Profil-Unterseiten
    }
    
    private var totalDistance: String {
        let total = historyManager.savedRoutes.reduce(0) { $0 + $1.totalDistance }
        if total >= 1000 {
            return String(format: "%.1f", total / 1000)
        } else {
            return "\(Int(total))"
        }
    }
    
    private var totalDistanceValue: Double {
        return historyManager.savedRoutes.reduce(0) { $0 + $1.totalDistance } / 1000
    }
    
    private var daysSinceJoined: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: profileManager.profile.createdAt, to: Date()).day ?? 0
        return max(1, days) // At least 1 day
    }
    
    private var currentAchievement: Achievement? {
        let routes = historyManager.savedRoutes.count
        let distance = totalDistanceValue
        let _ = daysSinceJoined // Future: Could be used for time-based achievements
        
        if routes >= 20 && distance >= 100 {
            return Achievement(emoji: "🏅", title: "Abenteuer-Legende!")
        } else if routes >= 10 && distance >= 50 {
            return Achievement(emoji: "🌟", title: "City Explorer!")
        } else if routes >= 5 || distance >= 20 {
            return Achievement(emoji: "🚀", title: "Auf gutem Weg!")
        } else if routes >= 1 {
            return Achievement(emoji: "🌱", title: "Entdecker-Neuling")
        }
        return nil
    }
}

// MARK: - Achievement Model
private struct Achievement {
    let emoji: String
    let title: String
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: UserProfileManager
    
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Erzähl uns von dir!") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("profile.name.textfield")
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Dein Foto") {
                    ProfileImageView()
                        .environmentObject(profileManager)
                }
            }
            .navigationTitle("Profil anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig!") {
                        saveProfile()
                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                    .accessibilityIdentifier("profile.save.button")
                }
            }
        }
        .onAppear {
            name = profileManager.profile.name
            email = profileManager.profile.email
        }
    }
    
    private func saveProfile() {
        profileManager.updateProfile(name: name, email: email)
    }
}