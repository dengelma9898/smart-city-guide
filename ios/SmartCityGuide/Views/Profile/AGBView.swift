import SwiftUI

// MARK: - AGB View
struct AGBView: View {
    
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 Allgemeine Geschäftsbedingungen")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Willkommen bei Smart City Guide! Diese Geschäftsbedingungen regeln die Nutzung unserer App und Services.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Geltungsbereich
                    AGBSection(
                        title: "1. Geltungsbereich",
                        content: """
                        Diese Allgemeinen Geschäftsbedingungen (AGB) gelten für die Nutzung der Smart City Guide App und aller damit verbundenen Services.
                        
                        Anbieter der App:
                        Smart City Guide GmbH
                        Musterstraße 123
                        10115 Berlin
                        Deutschland
                        
                        Durch das Herunterladen, Installieren oder Nutzen der App stimmst du diesen AGB zu. Falls du mit diesen Bedingungen nicht einverstanden bist, nutze die App bitte nicht.
                        """
                    )
                    
                    // Leistungsbeschreibung
                    AGBSection(
                        title: "2. Leistungsbeschreibung",
                        content: """
                        Smart City Guide ist eine kostenlose mobile App, die folgende Services bietet:
                        
                        • Intelligente Routenplanung für Stadtspaziergänge
                        • Automatische Optimierung von Walking-Touren
                        • Vorschläge für Sehenswürdigkeiten, Museen und Parks
                        • Speicherung deiner Routenhistorie
                        • Navigation und Kartenintegration
                        
                        Die App nutzt externe Services (Geoapify API, Apple Maps) zur Bereitstellung von Karten- und Ortsdaten. Wir übernehmen keine Gewähr für die Vollständigkeit oder Aktualität dieser Drittanbieterdaten.
                        """
                    )
                    
                    // Nutzungsrechte und -pflichten
                    AGBSection(
                        title: "3. Nutzungsrechte und -pflichten",
                        content: """
                        Du erhältst ein einfaches, nicht übertragbares Nutzungsrecht an der App für den persönlichen, nicht-kommerziellen Gebrauch.
                        
                        Du verpflichtest dich:
                        • Die App nur für legale Zwecke zu nutzen
                        • Keine schädlichen oder illegalen Inhalte zu übertragen
                        • Die App nicht zu reverse-engineeren oder zu dekompilieren
                        • Keine automatisierten Systeme zur Datenextraktion zu verwenden
                        • Die Urheberrechte und anderen Schutzrechte zu respektieren
                        
                        Bei Verstößen können wir den Zugang zur App einschränken oder sperren.
                        """
                    )
                    
                    // Verfügbarkeit
                    AGBSection(
                        title: "4. Verfügbarkeit",
                        content: """
                        Wir bemühen uns um eine hohe Verfügbarkeit der App, können aber keine 100%ige Verfügbarkeit garantieren.
                        
                        Wartungsarbeiten können zu vorübergehenden Einschränkungen führen. Wir informieren dich bei geplanten Wartungen rechtzeitig.
                        
                        Bei technischen Problemen oder Störungen kontaktiere unseren Support unter: support@smartcityguide.de
                        """
                    )
                    
                    // Datenschutz
                    AGBSection(
                        title: "5. Datenschutz",
                        content: """
                        Der Schutz deiner Daten ist uns wichtig. Alle Informationen zur Datenverarbeitung findest du in unserer Datenschutzerklärung.
                        
                        Wichtige Punkte:
                        • Standortdaten werden nur mit deiner Einwilligung verarbeitet
                        • Keine kontinuierliche Standortverfolgung
                        • Lokale Speicherung deiner Routenhistorie
                        • Keine Weitergabe persönlicher Daten an Dritte ohne Einwilligung
                        
                        Die vollständigen Datenschutzbestimmungen findest du im Profil-Bereich der App.
                        """
                    )
                    
                    // Haftungsausschluss
                    AGBSection(
                        title: "6. Haftung",
                        content: """
                        Wir haften nach den gesetzlichen Bestimmungen für Schäden, die auf einer vorsätzlichen oder grob fahrlässigen Pflichtverletzung beruhen.
                        
                        Für leichte Fahrlässigkeit haften wir nur bei:
                        • Verletzung von Leben, Körper oder Gesundheit
                        • Verletzung wesentlicher Vertragspflichten
                        
                        Die Routenvorschläge dienen nur zur Orientierung. Du bist selbst dafür verantwortlich:
                        • Die Verkehrssicherheit zu beachten
                        • Öffnungszeiten und Zugänglichkeit zu prüfen
                        • Wetterbedingungen zu berücksichtigen
                        • Auf deine körperliche Verfassung zu achten
                        
                        Für Schäden durch Drittanbieter-Services (Karten, Navigation) übernehmen wir keine Haftung.
                        """
                    )
                    
                    // Urheberrecht
                    AGBSection(
                        title: "7. Urheberrecht und geistiges Eigentum",
                        content: """
                        Alle Inhalte der App (Design, Texte, Grafiken, Software) sind urheberrechtlich geschützt und Eigentum der Smart City Guide GmbH oder unserer Lizenzgeber.
                        
                        Marken und Logos:
                        • "Smart City Guide" ist eine eingetragene Marke
                        • Drittanbieter-Marken (Geoapify, Apple) gehören den jeweiligen Eigentümern
                        
                        Du darfst Inhalte nur für den persönlichen Gebrauch nutzen. Eine kommerzielle Nutzung oder Weiterverbreitung ist ohne ausdrückliche Genehmigung untersagt.
                        """
                    )
                    
                    // Aktualisierungen
                    AGBSection(
                        title: "8. App-Updates und Änderungen",
                        content: """
                        Wir können die App jederzeit aktualisieren, um:
                        • Neue Features hinzuzufügen
                        • Sicherheit und Performance zu verbessern
                        • Fehler zu beheben
                        • Rechtlichen Anforderungen zu entsprechen
                        
                        Wichtige Änderungen an diesen AGB werden dir über die App oder per E-Mail mitgeteilt. Die Nutzung der App nach einer Änderung gilt als Zustimmung zu den neuen Bedingungen.
                        
                        Du kannst App-Updates über die iOS-Einstellungen verwalten.
                        """
                    )
                    
                    // Beendigung
                    AGBSection(
                        title: "9. Beendigung der Nutzung",
                        content: """
                        Du kannst die Nutzung der App jederzeit beenden, indem du:
                        • Die App von deinem Gerät löschst
                        • Deine gespeicherten Daten in den App-Einstellungen löschst
                        
                        Wir können den Service einstellen oder deinen Zugang sperren bei:
                        • Verstößen gegen diese AGB
                        • Missbrauch der App
                        • Technischen oder wirtschaftlichen Gründen
                        
                        Bei Einstellung des Services werden wir dich rechtzeitig informieren.
                        """
                    )
                    
                    // Streitbeilegung
                    AGBSection(
                        title: "10. Anwendbares Recht und Gerichtsstand",
                        content: """
                        Für diese AGB und alle Streitigkeiten gilt deutsches Recht unter Ausschluss des UN-Kaufrechts.
                        
                        Gerichtsstand für alle Streitigkeiten ist Berlin, soweit du Vollkaufmann, juristische Person des öffentlichen Rechts oder öffentlich-rechtliches Sondervermögen bist.
                        
                        Verbraucher können auch an ihrem Wohnsitz klagen.
                        
                        EU-Verbraucher können die Online-Streitbeilegungsplattform nutzen:
                        https://ec.europa.eu/consumers/odr/
                        """
                    )
                    
                    // Salvatorische Klausel
                    AGBSection(
                        title: "11. Schlussbestimmungen",
                        content: """
                        Sollten einzelne Bestimmungen dieser AGB unwirksam sein oder werden, bleibt die Wirksamkeit der übrigen Bestimmungen unberührt.
                        
                        Unwirksame Bestimmungen werden durch wirksame ersetzt, die dem wirtschaftlichen Zweck der unwirksamen Bestimmung am nächsten kommen.
                        
                        Änderungen oder Ergänzungen dieser AGB bedürfen der Textform.
                        
                        Stand: Januar 2025
                        Version: 1.0
                        """
                    )
                    
                    Spacer()
                }
                .padding(.bottom, 32)
        }
        .navigationTitle("AGB")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("profile.agb.screen")
    }
}

// MARK: - AGB Section Component
struct AGBSection: View {
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
    AGBView()
}