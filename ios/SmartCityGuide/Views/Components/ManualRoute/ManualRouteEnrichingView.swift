import SwiftUI

/// Enriching view for Wikipedia data loading phase in manual route planning
struct ManualRouteEnrichingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 200)
                
                Text("Lade Wikipedia-Infos...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Bereite interessante Details zu den Orten vor")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))% abgeschlossen")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ManualRouteEnrichingView(progress: 0.7)
}
