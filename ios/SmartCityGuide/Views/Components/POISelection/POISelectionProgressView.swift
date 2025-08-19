import SwiftUI

/// Progress indicator for POI selection showing current index and progress
struct POISelectionProgressView: View {
    
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        HStack {
            indexBadge
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
    
    private var indexBadge: some View {
        HStack(spacing: 8) {
            Text("\(currentIndex + 1)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.blue))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("von \(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress bar
                ProgressView(value: Double(currentIndex + 1), total: Double(totalCount))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        POISelectionProgressView(currentIndex: 0, totalCount: 10)
        POISelectionProgressView(currentIndex: 5, totalCount: 10)
        POISelectionProgressView(currentIndex: 9, totalCount: 10)
    }
    .padding()
}
