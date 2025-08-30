import SwiftUI

// MARK: - Impressum View
struct ImpressumView: View {
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {

                        Text("Angaben gemäß § 5 TMG (Telemediengesetz)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Anbieter
                    ImpressumSection(
                        title: "Anbieter",
                        content: """
                        Smart City Guide GmbH
                        Musterstraße 123
                        10115 Berlin
                        Deutschland
                        """
                    )
                    
                    // Kontaktdaten
                    ImpressumSection(
                        title: "Kontakt",
                        content: """
                        E-Mail: dengelma.solutions@gmail.com
                        Website: www.smartcityguide.de
                        """
                    )
                    
                    // Geschäftsführung
                    ImpressumSection(
                        title: "Vertretungsberechtigte Geschäftsführung",
                        content: "Max Mustermann"
                    )
                    
                    // Registereintrag
                    ImpressumSection(
                        title: "Registereintrag",
                        content: """
                        Eintragung im Handelsregister
                        Registergericht: Amtsgericht Berlin
                        Registernummer: HRB 123456 B
                        """
                    )
                    
                    // Umsatzsteuer-ID
                    ImpressumSection(
                        title: "Umsatzsteuer-Identifikationsnummer",
                        content: """
                        Umsatzsteuer-Identifikationsnummer gemäß § 27 a Umsatzsteuergesetz:
                        DE 123456789
                        """
                    )
                    
                    // Aufsichtsbehörde
                    ImpressumSection(
                        title: "Aufsichtsbehörde",
                        content: """
                        Bezirksamt Mitte von Berlin
                        Abteilung Wirtschaft
                        Karl-Marx-Allee 31
                        10178 Berlin
                        """
                    )
                    
                    // Streitschlichtung
                    ImpressumSection(
                        title: "Streitschlichtung",
                        content: """
                        Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit: https://ec.europa.eu/consumers/odr/
                        
                        Unsere E-Mail-Adresse finden Sie oben im Impressum.
                        
                        Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.
                        """
                    )
                    
                    // Haftung für Inhalte
                    ImpressumSection(
                        title: "Haftung für Inhalte",
                        content: """
                        Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht unter der Verpflichtung, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.
                        
                        Verpflichtungen zur Entfernung oder Sperrung der Nutzung von Informationen nach den allgemeinen Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung ist jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten Rechtsverletzung möglich. Bei Bekanntwerden von entsprechenden Rechtsverletzungen werden wir diese Inhalte umgehend entfernen.
                        """
                    )
                    
                    // Haftung für Links
                    ImpressumSection(
                        title: "Haftung für Links",
                        content: """
                        Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich. Die verlinkten Seiten wurden zum Zeitpunkt der Verlinkung auf mögliche Rechtsverstöße überprüft. Rechtswidrige Inhalte waren zum Zeitpunkt der Verlinkung nicht erkennbar.
                        
                        Eine permanente inhaltliche Kontrolle der verlinkten Seiten ist jedoch ohne konkrete Anhaltspunkte einer Rechtsverletzung nicht zumutbar. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Links umgehend entfernen.
                        """
                    )
                    
                    // Urheberrecht
                    ImpressumSection(
                        title: "Urheberrecht",
                        content: """
                        Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers. Downloads und Kopien dieser Seite sind nur für den privaten, nicht kommerziellen Gebrauch gestattet.
                        
                        Soweit die Inhalte auf dieser Seite nicht vom Betreiber erstellt wurden, werden die Urheberrechte Dritter beachtet. Insbesondere werden Inhalte Dritter als solche gekennzeichnet. Sollten Sie trotzdem auf eine Urheberrechtsverletzung aufmerksam werden, bitten wir um einen entsprechenden Hinweis. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Inhalte umgehend entfernen.
                        """
                    )
                    
                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Impressum")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Impressum Section Component
struct ImpressumSection: View {
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
    ImpressumView()
}