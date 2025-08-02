import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Profile Header
          VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 80))
              .foregroundColor(.blue)
            
            Text("Max Mustermann")
              .font(.title2)
              .fontWeight(.semibold)
            
            Text("max.mustermann@email.de")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 20)
          
          // Profile Options
          VStack(spacing: 0) {
            ProfileRow(icon: "location.fill", title: "Gespeicherte Orte", subtitle: "5 Orte")
            ProfileRow(icon: "clock.fill", title: "Letzte Routen", subtitle: "12 Routen")
            ProfileRow(icon: "heart.fill", title: "Favoriten", subtitle: "8 Favoriten")
            ProfileRow(icon: "gearshape.fill", title: "Einstellungen", subtitle: "App-Einstellungen")
            ProfileRow(icon: "questionmark.circle.fill", title: "Hilfe & Support", subtitle: "Häufige Fragen")
          }
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(.systemGray6))
          )
          
          Spacer()
        }
        .padding(.horizontal, 20)
      }
      .navigationTitle("Profil")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fertig") {
            dismiss()
          }
        }
      }
    }
  }
}