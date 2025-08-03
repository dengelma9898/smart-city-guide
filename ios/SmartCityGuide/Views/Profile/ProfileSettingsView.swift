import SwiftUI

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: ProfileSettingsManager
    
    var body: some View {
        NavigationView {
            Form {
                // Header Section
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Deine Einstellungen")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("So stellst du deine Touren standardmäßig ein!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                // Number of Places Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Wie viele Stopps?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(2...5, id: \.self) { number in
                                Button(action: {
                                    settingsManager.updateDefaults(numberOfPlaces: number)
                                }) {
                                    Text("\(number)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(settingsManager.settings.defaultNumberOfPlaces == number ? .white : .blue)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(settingsManager.settings.defaultNumberOfPlaces == number ? .blue : Color(.systemGray6))
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(settingsManager.settings.defaultNumberOfPlaces) ist dein Standard")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("So magst du's")
                }
                
                // Route Length Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Wie weit gehst du gerne?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(RouteLength.allCases, id: \.self) { length in
                                Button(action: {
                                    settingsManager.updateDefaults(routeLength: length)
                                }) {
                                    HStack {
                                        Image(systemName: settingsManager.settings.defaultRouteLength == length ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(settingsManager.settings.defaultRouteLength == length ? .blue : .secondary)
                                            .font(.system(size: 20))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(length.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(length.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(settingsManager.settings.defaultRouteLength == length ? Color(.systemBlue).opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Endpoint Options Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Wo willst du normalerweise hin?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(EndpointOption.allCases, id: \.self) { option in
                                Button(action: {
                                    settingsManager.updateDefaults(endpointOption: option)
                                }) {
                                    HStack {
                                        Image(systemName: settingsManager.settings.defaultEndpointOption == option ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(settingsManager.settings.defaultEndpointOption == option ? .blue : .secondary)
                                            .font(.system(size: 20))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(option.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(option.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(settingsManager.settings.defaultEndpointOption == option ? Color(.systemBlue).opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Custom Endpoint Default
                        if settingsManager.settings.defaultEndpointOption == .custom {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dein liebstes Ziel")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Hauptbahnhof, Zentrum... was magst du?", text: Binding(
                                    get: { settingsManager.settings.customEndpointDefault },
                                    set: { newValue in
                                        settingsManager.updateDefaults(customEndpoint: newValue)
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Reset Section
                Section {
                    Button(action: {
                        settingsManager.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Alles zurücksetzen")
                                .foregroundColor(.orange)
                        }
                    }
                } footer: {
                    Text("Du kannst das später jederzeit bei jeder Tour ändern!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Deine Präferenzen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSettingsView()
        .environmentObject(ProfileSettingsManager())
}