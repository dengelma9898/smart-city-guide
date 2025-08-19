import SwiftUI

/// Selection counter view for toolbar in manual route planning
struct ManualRouteSelectionCounterView: View {
    let selectedCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text("\(selectedCount)")
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(.systemGray6)))
    }
}

#Preview {
    ManualRouteSelectionCounterView(selectedCount: 5)
        .padding()
}
