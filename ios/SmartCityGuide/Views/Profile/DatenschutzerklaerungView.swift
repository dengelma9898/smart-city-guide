import SwiftUI

// MARK: - Datenschutzerklärung View
struct DatenschutzerklaerungView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔒 Datenschutzerklärung")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Wir nehmen den Schutz deiner persönlichen Daten sehr ernst und halten uns strikt an die Regeln der Datenschutzgesetze.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Verantwortlicher
                    DatenschutzSection(
                        title: "1. Verantwortlicher",
                        content: """
                        Verantwortlicher für die Datenverarbeitung auf dieser App ist:
                        
                        Smart City Guide GmbH
                        Musterstraße 123
                        10115 Berlin
                        Deutschland
                        
                        E-Mail: datenschutz@smartcityguide.de
                        Telefon: +49 30 12345678
                        """
                    )
                    
                    // Arten der verarbeiteten Daten
                    DatenschutzSection(
                        title: "2. Arten der verarbeiteten Daten",
                        content: """
                        Wir verarbeiten folgende Kategorien von personenbezogenen Daten:
                        
                        • Bestandsdaten (z.B. Name, E-Mail-Adresse)
                        • Nutzungsdaten (z.B. besuchte Seiten, Interessen)
                        • Standortdaten (z.B. Stadt für Routenplanung)
                        • Inhaltsdaten (z.B. gespeicherte Routen)
                        • Meta-/Kommunikationsdaten (z.B. Geräte-IDs)
                        """
                    )
                    
                    // Zwecke der Datenverarbeitung
                    DatenschutzSection(
                        title: "3. Zwecke der Datenverarbeitung",
                        content: """
                        Wir verarbeiten deine Daten für folgende Zwecke:
                        
                        • Bereitstellung der App-Funktionen
                        • Routenplanung und Ortssuche
                        • Speicherung deiner Routenhistorie
                        • Verbesserung unserer Dienste
                        • Technische Administration
                        • Erfüllung rechtlicher Verpflichtungen
                        """
                    )
                    
                    // Rechtsgrundlagen
                    DatenschutzSection(
                        title: "4. Rechtsgrundlagen",
                        content: """
                        Die Verarbeitung erfolgt auf Grundlage folgender Rechtsgrundlagen:
                        
                        • Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
                        • Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)
                        • Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)
                        
                        Unser berechtigtes Interesse liegt in der Bereitstellung und Verbesserung unserer App-Dienste.
                        """
                    )
                    
                    // Standortdaten
                    DatenschutzSection(
                        title: "5. Standortdaten",
                        content: """
                        Unsere App nutzt Standortdaten für:
                        
                        • Routenplanung in deiner gewählten Stadt
                        • Suche nach interessanten Orten in deiner Nähe
                        • Optimierung der Wegführung
                        
                        Die Standortdatenverarbeitung erfolgt nur mit deiner expliziten Einwilligung. Du kannst diese jederzeit in den iOS-Einstellungen widerrufen.
                        
                        Wir tracken deinen Standort NICHT kontinuierlich oder ohne deine Einwilligung.
                        """
                    )
                    
                    // Drittanbieter-Dienste
                    DatenschutzSection(
                        title: "6. Drittanbieter-Dienste",
                        content: """
                        Wir nutzen folgende Drittanbieter-Dienste:
                        
                        Geoapify API
                        • Zweck: Routenplanung und Ortssuche
                        • Daten: Stadtname, Points of Interest
                        • Anbieter: Geoapify Ltd.
                        • Datenschutz: https://www.geoapify.com/privacy-policy
                        
                        Apple MapKit
                        • Zweck: Kartenanzeige und Navigation
                        • Daten: Kartendaten, Routen
                        • Anbieter: Apple Inc.
                        • Datenschutz: https://www.apple.com/privacy/
                        """
                    )
                    
                    // Speicherdauer
                    DatenschutzSection(
                        title: "7. Speicherdauer",
                        content: """
                        Wir speichern deine Daten nur so lange, wie es für die Zwecke erforderlich ist:
                        
                        • Profildaten: Bis zur Löschung des Accounts
                        • Routenhistorie: Bis zur manuellen Löschung durch dich
                        • Nutzungsdaten: Maximal 2 Jahre
                        • Log-Daten: Maximal 30 Tage
                        
                        Du kannst alle deine Daten jederzeit in den App-Einstellungen löschen.
                        """
                    )
                    
                    // Deine Rechte
                    DatenschutzSection(
                        title: "8. Deine Rechte",
                        content: """
                        Du hast folgende Rechte bezüglich deiner Daten:
                        
                        • Auskunft über deine gespeicherten Daten (Art. 15 DSGVO)
                        • Berichtigung unrichtiger Daten (Art. 16 DSGVO)
                        • Löschung deiner Daten (Art. 17 DSGVO)
                        • Einschränkung der Verarbeitung (Art. 18 DSGVO)
                        • Datenübertragbarkeit (Art. 20 DSGVO)
                        • Widerspruch gegen die Verarbeitung (Art. 21 DSGVO)
                        • Widerruf von Einwilligungen (Art. 7 Abs. 3 DSGVO)
                        
                        Kontaktiere uns unter: datenschutz@smartcityguide.de
                        """
                    )
                    
                    // Datensicherheit
                    DatenschutzSection(
                        title: "9. Datensicherheit",
                        content: """
                        Wir setzen technische und organisatorische Maßnahmen ein, um deine Daten zu schützen:
                        
                        • Verschlüsselung der Datenübertragung (HTTPS/TLS)
                        • Sichere Server in Europa
                        • Regelmäßige Sicherheitsupdates
                        • Zugriffskontrolle und Berechtigungskonzepte
                        • Regelmäßige Datenschutz-Schulungen
                        
                        Lokale Daten werden sicher auf deinem Gerät gespeichert.
                        """
                    )
                    
                    // Beschwerderecht
                    DatenschutzSection(
                        title: "10. Beschwerderecht",
                        content: """
                        Du hast das Recht, dich bei einer Datenschutz-Aufsichtsbehörde über unsere Verarbeitung deiner Daten zu beschweren.
                        
                        Zuständige Aufsichtsbehörde:
                        Berliner Beauftragte für Datenschutz und Informationsfreiheit
                        Friedrichstr. 219
                        10969 Berlin
                        
                        Telefon: +49 30 13889-0
                        E-Mail: mailbox@datenschutz-berlin.de
                        """
                    )
                    
                    // Änderungen
                    DatenschutzSection(
                        title: "11. Änderungen dieser Datenschutzerklärung",
                        content: """
                        Wir behalten uns vor, diese Datenschutzerklärung zu aktualisieren, um sie an geänderte Rechtslagen oder bei Änderungen unserer Dienste anzupassen.
                        
                        Bei wesentlichen Änderungen werden wir dich über die App oder per E-Mail informieren.
                        
                        Stand: Januar 2025
                        """
                    )
                    
                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Datenschutz")
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

// MARK: - Datenschutz Section Component
struct DatenschutzSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    DatenschutzerklaerungView()
}