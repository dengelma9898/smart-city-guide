import SwiftUI

/// Completed view for successful route generation in manual route planning
struct ManualRouteCompletedView: View {
    let onShowRoute: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Route erstellt!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("manual.completion.anchor")
                
                Text("Deine manuelle Route ist bereit")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onShowRoute) {
                Text("Route anzeigen")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
            }
            .accessibilityIdentifier("manual.route.show.builder.button")
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ManualRouteCompletedView {
        print("Show route tapped")
    }
}
