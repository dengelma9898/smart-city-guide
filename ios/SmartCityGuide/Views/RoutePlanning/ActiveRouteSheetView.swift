import SwiftUI

struct ActiveRouteSheetView: View {
  let route: GeneratedRoute
  let onEnd: () -> Void
  let onAddStop: () -> Void
  
  @State private var showingEndConfirmation = false
  
  var body: some View {
    GeometryReader { proxy in
      let height = proxy.size.height
      ScrollView(showsIndicators: false) {
        VStack(spacing: 12) {
          // Collapsed summary row
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
          .padding(.top, 10)
          .padding(.bottom, height >= 220 ? 6 : 12)
          .accessibilityIdentifier("activeRoute.sheet.collapsed")

          // Medium & Large content (appears as soon as there is enough height)
          if height >= 220 {
            VStack(alignment: .leading, spacing: 10) {
              Text("Nächste Stopps")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

              VStack(spacing: 8) {
                let stops = Array(intermediateWaypoints().prefix(6))
                ForEach(stops.indices, id: \.self) { index in
                  let wp = stops[index]
                  HStack(spacing: 10) {
                    Text("\(index + 1)")
                      .font(.footnote)
                      .foregroundColor(.secondary)
                      .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                      Text(wp.name)
                        .font(.body)
                        .lineLimit(1)
                      Text(wp.address)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundColor(.secondary)
                  }
                  .padding(.horizontal, 16)
                  .padding(.vertical, 8)
                  .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
              }

              HStack {
                Spacer()
                Button(action: onAddStop) {
                  HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .semibold))
                    Text("Stopp hinzufügen").font(.body).fontWeight(.medium)
                  }
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.15)))
                }
                .accessibilityIdentifier("activeRoute.action.addStop")
              }
              .padding(.horizontal, 16)
              .padding(.top, 4)
              .padding(.bottom, 8)
            }
          }
        }
        .padding(.bottom, 8)
      }
      .background(Color.clear)
    }
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

  private func intermediateWaypoints() -> [RoutePoint] {
    let wps = route.waypoints
    guard wps.count > 2 else { return [] }
    return Array(wps.dropFirst().dropLast())
  }
}


