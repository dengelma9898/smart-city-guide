import SwiftUI

struct ActiveRouteSheetView: View {
  let route: GeneratedRoute
  let onEnd: () -> Void
  
  @State private var showingEndConfirmation = false
  
  var body: some View {
    VStack(spacing: 0) {
      // Collapsed content: Distanz • Zeit • Stopps
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(summaryLine)
            .font(.subheadline)
            .fontWeight(.medium)
          Text("\(route.numberOfStops) Stopps")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        
        // End Button
        Button(action: { showingEndConfirmation = true }) {
          HStack(spacing: 6) {
            Image(systemName: "stop.fill")
              .font(.system(size: 15, weight: .medium))
            Text("Tour beenden")
              .font(.body)
              .fontWeight(.medium)
          }
          .foregroundColor(.white)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(RoundedRectangle(cornerRadius: 18).fill(Color.red))
        }
        .accessibilityIdentifier("activeRoute.action.end")
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .padding(.top, 10) // extra margin from the top edge so content is not glued to the grab area
      .accessibilityIdentifier("activeRoute.sheet.collapsed")
      .allowsHitTesting(true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.clear)
    .alert("Tour wirklich beenden?", isPresented: $showingEndConfirmation) {
      Button("Abbrechen", role: .cancel) { }
      Button("Beenden", role: .destructive) { onEnd() }
    } message: {
      Text("Deine aktuelle Tour wird geschlossen. Das kannst du nicht rückgängig machen.")
    }
  }
  
  private var summaryLine: String {
    let km = max(1, Int(route.totalDistance / 1000))
    let time = formatDuration(route.totalExperienceTime)
    return "\(km) km • \(time)"
  }
  
  private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds / 60)
    if minutes < 60 { return "\(minutes) min" }
    let hours = minutes / 60
    let remMin = minutes % 60
    return remMin == 0 ? "\(hours) h" : "\(hours) h \(remMin) min"
  }
}


