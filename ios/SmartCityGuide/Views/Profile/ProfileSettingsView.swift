import SwiftUI

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: ProfileSettingsManager

    
    var body: some View {
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
                

                
                // Maximum Stops Section (unified radio style)
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
                        
                        VStack(spacing: 8) {
                            ForEach(MaximumStops.allCases, id: \.self) { stops in
                                Button(action: {
                                    settingsManager.updateDefaults(maximumStops: stops)
                                }) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: settingsManager.settings.defaultMaximumStops == stops ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(settingsManager.settings.defaultMaximumStops == stops ? .blue : .secondary)
                                            .font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stops.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            Text(stopsDescription(stops))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(settingsManager.settings.defaultMaximumStops == stops ? Color(.systemBlue).opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("settings.stops.\(stops.rawValue)")
                            }
                        }
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
                                .accessibilityIdentifier("settings.walktime.\(time.rawValue)")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Zeit-Präferenzen")
                }
                
                // Minimum POI Distance Section (unified radio style)
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
                        
                        VStack(spacing: 8) {
                            ForEach(MinimumPOIDistance.allCases, id: \.self) { distance in
                                Button(action: {
                                    settingsManager.updateDefaults(minimumPOIDistance: distance)
                                }) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: settingsManager.settings.defaultMinimumPOIDistance == distance ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(settingsManager.settings.defaultMinimumPOIDistance == distance ? .blue : .secondary)
                                            .font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(distance.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            Text(distanceDescription(distance))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(settingsManager.settings.defaultMinimumPOIDistance == distance ? Color(.systemBlue).opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("settings.distance.\(distance.rawValue)")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Abstand-Präferenzen")
                } footer: {
                    Text("Größere Abstände = weniger Stopps, aber mehr Abwechslung in der Route")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Endpoint Options Section (unified radio style)
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
                                    HStack(alignment: .top, spacing: 10) {
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
                                .accessibilityIdentifier("settings.endpoint.\(option.rawValue)")
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
                } header: {
                    Text("Ziel-Präferenzen")
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
        .accessibilityIdentifier("profile.settings.screen")
    }
    

}

// MARK: - Option Descriptions
private func stopsDescription(_ stops: MaximumStops) -> String {
    switch stops {
    case .three: return "Kompakte, schnelle Tour"
    case .five: return "Ausgewogene Entdeckung"
    case .eight: return "Intensivere Runde mit mehr Vielfalt"
    }
}

private func distanceDescription(_ d: MinimumPOIDistance) -> String {
    switch d {
    case .oneHundred: return "Enger Radius – dichter beieinander"
    case .twoFifty: return "Gutes Mittelmaß für City-Touren"
    case .fiveHundred: return "Mehr Strecke, mehr Wechsel"
    case .sevenFifty: return "Weite Abstände – abwechslungsreicher"
    case .oneKm: return "Große Distanzen für längere Spaziergänge"
    case .noMinimum: return "Keine Begrenzung – kann kompakt clustern"
    }
}

#Preview {
    ProfileSettingsView()
        .environmentObject(ProfileSettingsManager.shared)
}