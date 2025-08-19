import SwiftUI

/// Navigation hints and guidance for active route
struct ActiveRouteNavigationHints: View {
    
    let userContext: UserNavigationContext
    let navigationHintText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Navigation")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(navigationHintText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Context-aware status indicator
                contextStatusIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
    }
    
    // MARK: - Context Status Indicator
    
    private var contextStatusIndicator: some View {
        HStack(spacing: 6) {
            // Movement indicator
            if userContext.isActivelyNavigating {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            } else if userContext.isStationary {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Speed indicator
            speedIndicator
        }
    }
    
    private var speedIndicator: some View {
        Group {
            if userContext.currentSpeed > 2.0 { // Fast walking/running
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
            } else if userContext.currentSpeed > 0.5 { // Normal walking
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
            } else { // Stationary or very slow
                Image(systemName: "location")
                    .foregroundColor(.gray)
            }
        }
        .font(.system(size: 12, weight: .medium))
    }
}

#Preview {
    VStack(spacing: 20) {
        ActiveRouteNavigationHints(
            userContext: UserNavigationContext(
                isActivelyNavigating: true,
                lastMovementTime: Date(),
                currentSpeed: 1.4,
                isStationary: false,
                timeOfDay: .afternoon,
                weatherCondition: .sunny
            ),
            navigationHintText: "Folge der Straße geradeaus für 200m"
        )
        
        ActiveRouteNavigationHints(
            userContext: UserNavigationContext(
                isActivelyNavigating: false,
                lastMovementTime: Date().addingTimeInterval(-300),
                currentSpeed: 0.0,
                isStationary: true,
                timeOfDay: .evening,
                weatherCondition: .cloudy
            ),
            navigationHintText: "Du scheinst eine Pause zu machen"
        )
        
        ActiveRouteNavigationHints(
            userContext: UserNavigationContext(
                isActivelyNavigating: true,
                lastMovementTime: Date(),
                currentSpeed: 2.5,
                isStationary: false,
                timeOfDay: .morning,
                weatherCondition: .rainy
            ),
            navigationHintText: "Du bist schnell unterwegs! 🏃‍♂️"
        )
    }
    .padding()
}
