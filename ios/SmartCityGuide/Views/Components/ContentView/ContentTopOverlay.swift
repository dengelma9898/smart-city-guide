import SwiftUI

/// Top overlay with profile and location buttons
struct ContentTopOverlay: View {
    
    @ObservedObject var locationService: LocationManagerService
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
