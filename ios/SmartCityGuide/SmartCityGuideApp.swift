import SwiftUI

@main
struct SmartCityGuideApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .id(UUID()) // sorgt für frischen Einstieg bei erneutem Öffnen (optional)
    }
  }
}