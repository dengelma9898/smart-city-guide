import SwiftUI

/// Bottom action bar with quick planning and route planning buttons
struct ContentBottomActionBar: View {
    
    let onQuickPlan: () -> Void
    let onFullPlan: () -> Void
    let isQuickPlanEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Full planning button
            Button(action: onFullPlan) {
                VStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Route planen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                )
            }
            .accessibilityIdentifier("home.plan.full")
            .accessibilityLabel("Route planen")
            
            // Quick planning button
            Button(action: onQuickPlan) {
                VStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Schnell planen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.orange)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                )
            }
            .disabled(!isQuickPlanEnabled)
            .opacity(isQuickPlanEnabled ? 1.0 : 0.5)
            .accessibilityIdentifier("home.plan.quick")
            .accessibilityLabel("Schnell planen")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20) // Closer to bottom edge
    }
}

#Preview {
    ContentBottomActionBar(
        onQuickPlan: { print("Quick plan tapped") },
        onFullPlan: { print("Full plan tapped") },
        isQuickPlanEnabled: true
    )
    .background(Color.gray.opacity(0.2))
}
