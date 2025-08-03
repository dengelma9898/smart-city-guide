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
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(historyManager.savedRoutes.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Touren")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(totalDistance)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Kilometer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(daysSinceJoined)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Tage mit uns")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                        
                        // Help & Support (Placeholder)
                        Button(action: {
                            // TODO: Implement help section
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
    }
    
    private var totalDistance: String {
        let total = historyManager.savedRoutes.reduce(0) { $0 + $1.totalDistance }
        if total >= 1000 {
            return String(format: "%.1f", total / 1000)
        } else {
            return "\(Int(total))"
        }
    }
    
    private var daysSinceJoined: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: profileManager.profile.createdAt, to: Date()).day ?? 0
        return max(1, days) // At least 1 day
    }
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