import SwiftUI

/// Einzelne Statistik-Karte für RouteSuccessView
/// Zeigt eine Statistik mit Icon, Wert und Label in einem animierten Card-Design
struct StatCardView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Icon with background circle (smaller)
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            // Value (main statistic)
            Text(value)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Label (description)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatCardView(
                icon: "figure.walk",
                value: "2.3 km",
                label: "Gehstrecke",
                color: .blue
            )
            
            StatCardView(
                icon: "clock",
                value: "45 min",
                label: "Gehzeit",
                color: .green
            )
        }
        
        HStack(spacing: 16) {
            StatCardView(
                icon: "map",
                value: "5",
                label: "Spots besucht",
                color: .orange
            )
            
            StatCardView(
                icon: "timer",
                value: "2h 15min",
                label: "Gesamtzeit",
                color: .purple
            )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
