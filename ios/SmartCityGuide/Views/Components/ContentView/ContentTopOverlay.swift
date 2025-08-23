import SwiftUI

/// Top overlay with profile and location buttons
struct ContentTopOverlay: View {
    
    @ObservedObject var locationService: LocationManagerService
    @StateObject private var cityNameService = CityNameService()
    let onLocationTap: () -> Void
    
    var body: some View {
        HStack {
            // Profile button - NavigationLink for push navigation
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
            .accessibilityIdentifier("home.profile.button")
            .accessibilityLabel("Profil")
            
            Spacer()
            
            // Current city display
            if let cityName = cityNameService.currentCityName {
                Text(cityName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .accessibilityLabel("Aktuelle Stadt: \(cityName)")
                    .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
            
            // Location button
            Button(action: onLocationTap) {
                Image(systemName: locationButtonIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(locationButtonColor))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .accessibilityIdentifier("home.location.button")
            .accessibilityLabel("Mein Standort")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .animation(.easeInOut(duration: 0.3), value: cityNameService.currentCityName)
        .onChange(of: locationService.currentLocation) { _, newLocation in
            Task {
                await cityNameService.updateCityName(from: newLocation)
            }
        }
        .onDisappear {
            cityNameService.clearCityName()
        }
    }
    
    // MARK: - Computed Properties
    
    private var locationButtonIcon: String {
        if !locationService.isLocationAuthorized {
            return locationService.authorizationStatus == .denied ? "location.slash" : "location"
        } else {
            return "location.fill"
        }
    }
    
    private var locationButtonColor: Color {
        if !locationService.isLocationAuthorized {
            return locationService.authorizationStatus == .denied ? .red : .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    NavigationStack {
        ContentTopOverlay(
            locationService: LocationManagerService.shared,
            onLocationTap: { print("Location tapped") }
        )
        .background(Color.gray.opacity(0.2))
    }
}
