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
                
                // Phase 3: Startpunkt-Präferenzen Section (moved to top)
                Section {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Immer meinen Standort verwenden")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Nutze automatisch deine aktuelle Position als Startpunkt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settingsManager.settings.useCurrentLocationAsDefault },
                            set: { newValue in
                                settingsManager.updateLocationDefault(useCurrentLocation: newValue)
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Startpunkt-Präferenzen")
                }
                
                // Maximum Stops Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Maximale Stopps")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MaximumStops.allCases, id: \.self) { stops in
                                    Button(action: {
                                        settingsManager.updateDefaults(maximumStops: stops)
                                    }) {
                                        Text(stops.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(settingsManager.settings.defaultMaximumStops == stops ? .white : .blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(settingsManager.settings.defaultMaximumStops == stops ? .blue : Color(.systemGray6))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        Text("Standard: \(settingsManager.settings.defaultMaximumStops.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Stopp-Präferenzen")
                }
                
                // Maximum Walking Time Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Maximale Gehzeit")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(MaximumWalkingTime.allCases, id: \.self) { time in
                                Button(action: {
                                    settingsManager.updateDefaults(maximumWalkingTime: time)
                                }) {
                                    HStack {
                                        Image(systemName: settingsManager.settings.defaultMaximumWalkingTime == time ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(settingsManager.settings.defaultMaximumWalkingTime == time ? .blue : .secondary)
                                            .font(.system(size: 20))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(time.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(time.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(settingsManager.settings.defaultMaximumWalkingTime == time ? Color(.systemBlue).opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Zeit-Präferenzen")
                }
                
                // Minimum POI Distance Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Mindestabstand zwischen Stopps")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MinimumPOIDistance.allCases, id: \.self) { distance in
                                    Button(action: {
                                        settingsManager.updateDefaults(minimumPOIDistance: distance)
                                    }) {
                                        Text(distance.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(settingsManager.settings.defaultMinimumPOIDistance == distance ? .white : .blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(settingsManager.settings.defaultMinimumPOIDistance == distance ? .blue : Color(.systemGray6))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        Text("Standard: \(settingsManager.settings.defaultMinimumPOIDistance.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Abstand-Präferenzen")
                } footer: {
                    Text("Größere Abstände = weniger Stopps, aber mehr Abwechslung in der Route")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                } header: {
                    Text("Abstand-Präferenzen")
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