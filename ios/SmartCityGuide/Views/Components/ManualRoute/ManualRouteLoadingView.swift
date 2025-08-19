import SwiftUI

/// Loading view for POI discovery phase in manual route planning
struct ManualRouteLoadingView: View {
    let cityName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Entdecke POIs in \(cityName)...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Ich suche nach interessanten Orten für deine Tour")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ManualRouteLoadingView(cityName: "Berlin")
}
