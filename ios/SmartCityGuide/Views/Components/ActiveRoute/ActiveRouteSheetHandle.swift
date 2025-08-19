import SwiftUI

/// Sheet handle with mode indicator for active route sheet
struct ActiveRouteSheetHandle: View {
    
    let currentMode: ActiveRouteSheetMode
    let onModeChange: (ActiveRouteSheetMode) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Sheet handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .opacity(0.6)
            
            // Mode indicator
            modeIndicator
        }
        .padding(.top, 8)
    }
    
    // MARK: - Mode Indicator
    
    private var modeIndicator: some View {
        HStack(spacing: 4) {
            ForEach(ActiveRouteSheetMode.allCases, id: \.self) { mode in
                if mode != .hidden {
                    Circle()
                        .fill(mode == currentMode ? .blue : Color(.systemGray4))
                        .frame(width: 6, height: 6)
                        .scaleEffect(mode == currentMode ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentMode)
                        .onTapGesture {
                            onModeChange(mode)
                        }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ActiveRouteSheetHandle(
            currentMode: .compact,
            onModeChange: { mode in
                print("Mode changed to: \(mode)")
            }
        )
        
        ActiveRouteSheetHandle(
            currentMode: .navigation,
            onModeChange: { mode in
                print("Mode changed to: \(mode)")
            }
        )
        
        ActiveRouteSheetHandle(
            currentMode: .overview,
            onModeChange: { mode in
                print("Mode changed to: \(mode)")
            }
        )
    }
    .background(Color.gray.opacity(0.2))
}
