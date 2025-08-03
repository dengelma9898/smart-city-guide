import SwiftUI

// MARK: - Enhanced Profile View
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager()
    @StateObject private var settingsManager = ProfileSettingsManager()
    @StateObject private var historyManager = RouteHistoryManager()
    
    @State private var showingSettings = false
    @State private var showingRouteHistory = false
    @State private var showingEditProfile = false
    @State private var showingHelpSupport = false
    
    var body: some View {
        NavigationView {
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
                            
                            Text(profileManager.profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Los, ändere dein Profil!") {
                                showingEditProfile = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
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
                    
                    // Enhanced Profile Options
                    VStack(spacing: 0) {
                        // Route History
                        Button(action: {
                            showingRouteHistory = true
                        }) {
                            ProfileRow(
                                icon: "clock.fill",
                                title: "Deine Abenteuer",
                                subtitle: "\(historyManager.savedRoutes.count) coole Touren erlebt"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Settings
                        Button(action: {
                            showingSettings = true
                        }) {
                            ProfileRow(
                                icon: "gearshape.fill",
                                title: "Deine Präferenzen",
                                subtitle: "So wie du's magst!"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Saved Places (Placeholder)
                        Button(action: {
                            // TODO: Implement saved places
                        }) {
                            ProfileRow(
                                icon: "location.fill",
                                title: "Deine Lieblingsorte",
                                subtitle: "Die coolsten Spots!"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.horizontal, 16)
                        
                        // Help & Support
                        Button(action: {
                            showingHelpSupport = true
                        }) {
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
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Dein Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
                .environmentObject(settingsManager)
        }
        .sheet(isPresented: $showingRouteHistory) {
            RouteHistoryView()
                .environmentObject(historyManager)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(profileManager)
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
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
        let days = daysSinceJoined
        
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