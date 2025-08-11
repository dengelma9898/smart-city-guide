import SwiftUI

// MARK: - Horizontal Filter Chips Component
struct HorizontalFilterChips<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    let title: String
    let icon: String
    let options: [T]
    @Binding var selection: T
    let infoAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with title and info button
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("\(title) Info")
                .accessibilityHint("Mehr Infos zu \(title)")
            }
            
            // Horizontal scrolling chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selection = option
                        }) {
                            Text(option.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(selection == option ? .white : .blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selection == option ? .blue : Color(.systemGray6))
                                )
                        }
                        .accessibilityLabel("\(option.rawValue)")
                        .accessibilityIdentifier("\(title).\(option.rawValue)")
                        .accessibilityValue(selection == option ? "selected" : "not-selected")
                        .accessibilityAddTraits(selection == option ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HorizontalFilterChips(
            title: "Maximale Stopps",
            icon: "map.fill",
            options: MaximumStops.allCases,
            selection: .constant(.five),
            infoAction: { }
        )
        
        HorizontalFilterChips(
            title: "Mindestabstand",
            icon: "point.3.filled.connected.trianglepath.dotted",
            options: MinimumPOIDistance.allCases,
            selection: .constant(.twoFifty),
            infoAction: { }
        )
    }
    .padding()
}