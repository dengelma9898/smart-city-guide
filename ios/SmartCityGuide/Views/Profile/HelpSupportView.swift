import SwiftUI

// MARK: - FAQ & Support View
struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    // FAQ Kategorien
    private let faqCategories = FAQCategory.allCategories
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header mit freundlicher Begrüßung
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hey! Brauchst du Hilfe? 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Keine Sorge, wir helfen dir gerne weiter! Hier findest du Antworten auf die häufigsten Fragen rund um deine Smart City Guide App.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Suchfeld
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                    
                    // FAQ Kategorien
                    LazyVStack(spacing: 16) {
                        ForEach(filteredCategories, id: \.title) { category in
                            FAQCategoryView(category: category)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Kontakt Sektion
                    ContactSectionView()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("Hilfe & Support")
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
    
    private var filteredCategories: [FAQCategory] {
        if searchText.isEmpty {
            return faqCategories
        } else {
            return faqCategories.compactMap { category in
                let filteredFAQs = category.faqs.filter { faq in
                    faq.question.localizedCaseInsensitiveContains(searchText) ||
                    faq.answer.localizedCaseInsensitiveContains(searchText)
                }
                
                if filteredFAQs.isEmpty {
                    return nil
                } else {
                    return FAQCategory(
                        title: category.title,
                        icon: category.icon,
                        faqs: filteredFAQs
                    )
                }
            }
        }
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Durchsuche die FAQs...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - FAQ Category View
struct FAQCategoryView: View {
    let category: FAQCategory
    @State private var expandedFAQs: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Kategorie Header
            HStack(spacing: 12) {
                Text(category.icon)
                    .font(.title2)
                
                Text(category.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // FAQ Items
            VStack(spacing: 0) {
                ForEach(Array(category.faqs.enumerated()), id: \.offset) { index, faq in
                    FAQItemView(
                        faq: faq,
                        isExpanded: expandedFAQs.contains(faq.id),
                        onToggle: {
                            if expandedFAQs.contains(faq.id) {
                                expandedFAQs.remove(faq.id)
                            } else {
                                expandedFAQs.insert(faq.id)
                            }
                        }
                    )
                    
                    if index < category.faqs.count - 1 {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - FAQ Item View
struct FAQItemView: View {
    let faq: FAQ
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(faq.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                if isExpanded {
                    Text(faq.answer)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Section
struct ContactSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("🤝 Immer noch Fragen?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Kein Problem! Melde dich gerne bei uns - wir helfen dir schnell und unkompliziert weiter.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Kontakt Options
            VStack(spacing: 12) {
                ContactOptionView(
                    icon: "envelope.fill",
                    title: "E-Mail Support",
                    detail: "dengelma.solutions@gmail.com",
                    color: .blue,
                    action: {
                        if let url = URL(string: "mailto:dengelma.solutions@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
                ContactOptionView(
                    icon: "clock.fill",
                    title: "Support Zeiten",
                    detail: "Mo-Fr 9:00-18:00 Uhr",
                    color: .orange,
                    action: nil
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Contact Option View
struct ContactOptionView: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - FAQ Data Models
struct FAQ {
    let id = UUID().uuidString
    let question: String
    let answer: String
}

struct FAQCategory {
    let title: String
    let icon: String
    let faqs: [FAQ]
    
    static let allCategories: [FAQCategory] = [
        // Route Planning FAQs
        FAQCategory(
            title: "Routenplanung",
            icon: "🗺️",
            faqs: [
                FAQ(
                    question: "Was ist die Schnell‑Planung?",
                    answer: "Mit der Schnell‑Planung startest du sofort eine Rundreise ab deinem aktuellen Standort. Die App wählt automatisch bis zu 5 interessante Orte in deiner Nähe, ohne Zeitlimit und ohne Mindestabstand. Es gibt keine Zwischenschritte – du siehst direkt die fertige Route auf der Karte."
                ),
                FAQ(
                    question: "Wie funktioniert die intelligente Routenplanung?",
                    answer: "Unsere App nutzt einen speziellen Algorithmus (TSP-Optimierung), der die beste Route zwischen deinen gewählten Sehenswürdigkeiten berechnet. Dabei werden echte Gehzeiten und Entfernungen berücksichtigt, sodass du möglichst effizient von Ort zu Ort kommst."
                ),
                FAQ(
                    question: "Kann ich selbst bestimmen, welche Orte besucht werden?",
                    answer: "Ja! Wähle im Planungsbildschirm den Modus \"Manuell erstellen\". Dann kannst du mit einem Swipe-Interface (links = übernehmen, rechts = überspringen) deine Lieblings-POIs auswählen. Oben rechts findest du über die drei Punkte eine Übersicht und deine aktuelle Auswahl."
                ),
                FAQ(
                    question: "Was ist der Unterschied zwischen \"Automatisch\" und \"Manuell erstellen\"?",
                    answer: "Im Modus \"Automatisch\" sucht die App passende Orte und erstellt die komplette Route für dich. Im Modus \"Manuell erstellen\" wählst du die POIs per Swipe selbst aus, und die App optimiert anschließend Reihenfolge und Gehwege (TSP mit echten Gehzeiten)."
                ),
                FAQ(
                    question: "Warum schließt sich das Planungsmenü nach \"Los geht's!\"?",
                    answer: "Das ist unser neuer Single-Sheet-Flow! Nach der Routengenerierung siehst du die Route sofort auf der Karte. Danach öffnet sich automatisch das Aktive-Routen-Menü, wo du die Route starten, bearbeiten und POIs hinzufügen kannst. So hast du alles übersichtlich in einem einzigen Menü, ohne mehrere Ebenen."
                ),
                FAQ(
                    question: "Wie funktioniert die POI-Auswahl (Swipe)?",
                    answer: "Auf der Karte siehst du POI-Karten: Nach links swipen oder Haken-Button = übernehmen, nach rechts oder X-Button = überspringen. Oben im Bildschirm findest du die Auswahl-Info – die große Bestätigungsfläche unten wurde entfernt. Die Route erstellst du im Manual‑Flow über den Button \"Route erstellen\" in der Kopfzeile."
                ),
                FAQ(
                    question: "Was passiert bei \"Rückgängig\"?",
                    answer: "Die letzte Aktion wird zurückgenommen. Der betroffene POI wird direkt wieder vor die aktuelle Karte einsortiert – du kannst ihn sofort neu bewerten. Ein kurzer Hinweis (Toast) zeigt dir zusätzlich, was zurückgenommen wurde und wie viele POIs aktuell ausgewählt sind."
                ),
                FAQ(
                    question: "Wo sehe ich meine aktuelle Auswahl?",
                    answer: "Tippe oben rechts auf die drei Punkte (⋯) → \"Aktuelle Auswahl\". Dort siehst du eine Liste deiner bisher gewählten POIs. Über dasselbe Menü findest du auch die Übersicht und kannst die Auswahl komplett zurücksetzen."
                ),
                FAQ(
                    question: "Warum sind manche Routen länger als gewünscht?",
                    answer: "Die App priorisiert interessante Orte und optimale Routenführung. Wenn eine Route dein Limit überschreitet, reduziert sie automatisch die Anzahl der Stops, um innerhalb deiner gewünschten Distanz zu bleiben."
                ),
                FAQ(
                    question: "Welche Kategorien von Orten kann ich auswählen?",
                    answer: "Du kannst zwischen Sehenswürdigkeiten, Museen, Parks und Nationalparks wählen. Die App findet automatisch die besten Orte in deiner gewählten Stadt für diese Kategorien."
                ),
                FAQ(
                    question: "Warum ändert sich der Titel nach der Planung?",
                    answer: "Sobald deine Route fertig ist, wechselt der Titel automatisch zu \"Deine Tour im Detail\". Daran erkennst du direkt, dass die Planung abgeschlossen ist und du dir nun die Route im Detail anschauen kannst."
                ),
                FAQ(
                    question: "Wie kann ich einzelne Stopps in meiner Route ändern?",
                    answer: """
                    Du kannst jeden Stopp deiner generierten Route bearbeiten:
                    
                    **So funktioniert's:**
                    1. **Stopp auswählen:** Tippe auf das Bearbeiten-Symbol (Stift) neben einem Stopp
                    2. **Alternativen durchschauen:** Swipe die Karten nach links (nehmen) oder rechts (überspringen)
                    3. **Neue Route:** Bei Auswahl wird automatisch eine optimierte Route berechnet
                    
                    **Swipe-Steuerung:**
                    • Nach links swipen = Stopp übernehmen ✅
                    • Nach rechts swipen = Stopp ablehnen ❌
                    • Alternativ: Verwende die Buttons am unteren Rand
                    
                    **Was wird gezeigt:**
                    • Bilder und Beschreibung des Ortes
                    • Entfernung zum ursprünglichen Stopp
                    • Wikipedia-Informationen (falls verfügbar)
                    """
                ),
                FAQ(
                    question: "Wie füge ich neue Stopps zu meiner Route hinzu?",
                    answer: """
                    Tippe in der Routenübersicht oben rechts auf das **+**. 
                    Im anschließenden Swipe-Interface kannst du POIs nach links **nehmen** (✅) oder nach rechts **überspringen** (❌). 
                    Du kannst beliebig viele POIs hintereinander hinzufügen. 

                    Sobald du fertig bist, tippe auf **Jetzt optimieren** – die gesamte Route wird anschließend vollständig neu berechnet und die Reihenfolge intelligent optimiert.
                    """
                ),
                FAQ(
                    question: "Wie lösche ich einzelne Stopps aus meiner Route?",
                    answer: """
                    Wische in der Routenliste bei einem Zwischenstopp nach links und tippe auf **Löschen**. 
                    Die Laufwege werden danach automatisch neu berechnet. 
                    Wenn nur noch ein einziger Zwischenstopp vorhanden ist und du diesen löscht, gelangst du automatisch zurück zur Planung.
                    """
                ),
                FAQ(
                    question: "Warum werden mir nur bestimmte Alternative Stopps gezeigt?",
                    answer: """
                    Die App zeigt dir alle interessanten Orte in der Stadt, außer denen, die bereits in deiner Route sind.
                    
                    **Was wird bevorzugt:**
                    • Orte der gleichen Kategorie (Museum, Park, etc.)
                    • Spots mit Wikipedia-Daten für bessere Infos
                    • Qualitätsgeprüfte Sehenswürdigkeiten
                    
                    **Sortierung der Alternativen:**
                    1. Kategorie-Übereinstimmung
                    2. Verfügbarkeit von Qualitätsdaten
                    3. Entfernung zum Original-Stopp
                    
                    **Wichtig:** Du siehst ALLE verfügbaren Alternativen - egal wie weit entfernt. Die App berechnet danach automatisch die beste neue Route für dich!
                    """
                ),
                FAQ(
                    question: "Was passiert wenn ich einen Stopp ändere?",
                    answer: """
                    **Automatische Route-Optimierung:**
                    
                    1. **Neuer Stopp eingefügt:** Der gewählte alternative Stopp ersetzt den ursprünglichen
                    2. **Intelligente Positionierung:** Bei weit entfernten Alternativen (>1,5km) wird die beste Position in der Route automatisch gefunden
                    3. **Route neu berechnet:** Laufwege werden vollständig neu optimiert
                    4. **Zeiten aktualisiert:** Gesamtzeit und Laufdauer werden angepasst
                    5. **Wikipedia-Daten geladen:** Neue Informationen werden im Hintergrund ergänzt
                    
                    **Smart Re-Optimierung:**
                    • Nahe Alternativen bleiben an derselben Position
                    • Ferne Alternativen werden optimal in die Route eingesetzt
                    • Reihenfolge kann sich ändern für beste Effizienz
                    
                    **Tipp:** Das System sorgt automatisch für die kürzeste und sinnvollste Route!
                    """
                )
            ]
        ),
        
        // App Features
        FAQCategory(
            title: "App Features",
            icon: "⭐",
            faqs: [
                FAQ(
                    question: "Funktioniert die App offline?",
                    answer: "Aktuell benötigt die App eine Internetverbindung für die Routenplanung und das Laden von Ortsinformationen. Offline-Funktionen sind für zukünftige Updates geplant."
                ),
                FAQ(
                    question: "Kann ich meine Routen speichern?",
                    answer: "Ja! Alle deine erstellten Routen werden automatisch in deinem Profil unter 'Deine Abenteuer' gespeichert. Du kannst sie jederzeit wieder ansehen und erneut nutzen."
                ),
                FAQ(
                    question: "Was bedeuten die Achievements?",
                    answer: "Die Achievements zeigen deinen Fortschritt als Stadtentdecker! Du erhältst Abzeichen basierend auf der Anzahl deiner Touren, gelaufenen Kilometern und aktiven Tagen mit der App."
                ),
                FAQ(
                    question: "Kann ich die App für andere Städte nutzen?",
                    answer: "Ja! Die App funktioniert für Städte weltweit. Gib einfach den Namen deiner gewünschten Stadt ein und die App findet automatisch interessante Orte dort."
                ),
                FAQ(
                    question: "Warum sehe ich ein Lade‑Overlay bei der Schnell‑Planung?",
                    answer: "Während die Schnell‑Planung läuft, berechnen wir die optimale Reihenfolge, prüfen Gehzeiten und laden Ortsdaten. Damit du siehst, dass etwas passiert, zeigen wir ein kurzes Lade‑Overlay mit Status‑Text (z. B. 'Entdecke coole Orte…' ➝ 'Optimiere deine Route…'). Sobald die Route fertig ist, verschwindet das Overlay automatisch."
                )
            ]
        ),
        
        // Technische Fragen
        FAQCategory(
            title: "Technische Hilfe",
            icon: "⚙️",
            faqs: [
                FAQ(
                    question: "Die App lädt sehr langsam oder hängt sich auf",
                    answer: "Überprüfe deine Internetverbindung und stelle sicher, dass du die neueste Version der App hast. Bei anhaltenden Problemen starte die App neu oder kontaktiere unseren Support."
                ),
                FAQ(
                    question: "Warum werden keine Orte für meine Stadt gefunden?",
                    answer: "Das kann bei sehr kleinen Orten vorkommen. Versuche eine größere Stadt in der Nähe oder kontaktiere uns - wir erweitern kontinuierlich unsere Datenbank."
                ),
                FAQ(
                    question: "Die Navigation funktioniert nicht richtig",
                    answer: "Stelle sicher, dass du der App Zugriff auf deinen Standort gewährt hast. Du findest diese Einstellung in den iOS-Einstellungen unter Datenschutz → Ortungsdienste."
                ),
                FAQ(
                    question: "Welche iOS Version wird benötigt?",
                    answer: "Die App benötigt iOS 17.5 oder neuer. Falls du eine ältere Version hast, aktualisiere dein iPhone über Einstellungen → Allgemein → Softwareupdate."
                )
            ]
        ),
        
        // Standort & Datenschutz
        FAQCategory(
            title: "Standort & Datenschutz",
            icon: "📍",
            faqs: [
                FAQ(
                    question: "Was sind die Intro-Screens beim ersten App-Start?",
                    answer: "Beim ersten Öffnen der App führen wir dich durch eine kurze Einführung, die den App-Zweck erklärt und dir dabei hilft, die notwendigen Berechtigungen zu verstehen. Du erfährst genau, warum jede Berechtigung benötigt wird und kannst selbst entscheiden, welche du aktivieren möchtest. Die Intro-Screens zeigen sich nur einmal - danach startest du direkt in die App."
                ),
                FAQ(
                    question: "Kann ich die Intro-Screens überspringen?",
                    answer: "Ja! Du kannst auf jedem Screen (außer dem letzten) auf 'Überspringen' tippen. Wir zeigen dir dann einen kurzen Hinweis, dass du fehlende Berechtigungen später jederzeit in den Profileinstellungen aktivieren kannst. Die App funktioniert auch ohne alle Berechtigungen - manche Features sind dann nur eingeschränkt verfügbar."
                ),
                FAQ(
                    question: "Wie funktionieren die POI-Benachrichtigungen?",
                    answer: "POI-Benachrichtigungen sind unser intelligentes Benachrichtigungssystem, das beide notwendigen Berechtigungen kombiniert: Hintergrund-Standort UND Mitteilungen. Wenn du eine Route startest und POI-Benachrichtigungen aktiviert hast, erhältst du automatisch Hinweise auf interessante Spots in deiner Nähe (ca. 25m), auch wenn die App geschlossen ist. Du kannst dieses Feature mit einem einzigen Toggle in deinen Berechtigungen aktivieren."
                ),

                FAQ(
                    question: "Wie kann ich Berechtigungen später ändern?",
                    answer: "Du findest alle Berechtigungen in deinem Profil unter 'Berechtigungen'. Dort siehst du drei Bereiche: Standort (für App-Nutzung), POI-Benachrichtigungen (kombiniert Hintergrund-Standort + Mitteilungen) und Sicherheit (biometrische Sicherung). Mit den Toggles kannst du Features direkt aktivieren/deaktivieren. Falls Systemberechtigungen fehlen, öffnet sich automatisch der iOS-Dialog."
                ),
                FAQ(
                    question: "Kann ich die App ohne Location-Permission verwenden?",
                    answer: "Ja, absolut! Du kannst die App vollständig nutzen, ohne Standortzugriff zu gewähren. Du gibst einfach eine Stadt manuell ein, und die App plant trotzdem perfekte Routen für dich. Lediglich die automatische Anzeige deiner Position und Benachrichtigungen sind dann nicht verfügbar."
                ),
                FAQ(
                    question: "Was passiert wenn ich Benachrichtigungen ablehne?",
                    answer: "Kein Problem! Die App funktioniert vollständig ohne Benachrichtigungen. Du verpasst nur die automatischen Hinweise auf interessante Spots während deiner Routen. Du kannst Benachrichtigungen jederzeit später in den Profileinstellungen oder iOS-Einstellungen aktivieren."
                ),
                FAQ(
                    question: "Wie kann ich meinen Standort als Standard-Startpunkt setzen?",
                    answer: "Gehe in dein Profil → Einstellungen → 'Immer meinen Standort verwenden'. Wenn diese Option aktiviert ist, wird automatisch dein aktueller Standort als Startpunkt vorgeschlagen, sobald du eine neue Route planst. Du kannst trotzdem jederzeit manuell eine andere Stadt eingeben."
                ),
                FAQ(
                    question: "Welche Daten sammelt die App?",
                    answer: "Wir sammeln nur die notwendigen Daten für die Routenplanung: Deine Standortangaben für Städte und gespeicherte Routen. Deine persönlichen Daten bleiben lokal auf deinem Gerät gespeichert."
                ),
                FAQ(
                    question: "Wird mein Standort getrackt?",
                    answer: "Nein! Wir tracken deinen Standort nicht kontinuierlich. Die App nutzt Standortdaten nur, wenn du aktiv eine Route planst oder nach Orten in deiner Nähe suchst. Bei Background-Benachrichtigungen wird dein Standort nur überprüft, um dir relevante Benachrichtigungen zu senden."
                ),
                FAQ(
                    question: "Kann ich meine Daten löschen?",
                    answer: "Ja, du kannst jederzeit alle deine gespeicherten Daten in den Profileinstellungen löschen. Dies umfasst deine Routenhistorie und Profileinstellungen."
                ),
                FAQ(
                    question: "Was ist die biometrische Sicherung?",
                    answer: "Die biometrische Sicherung schützt deine sensiblen Profilbereiche 'Deine Abenteuer' und 'Deine Lieblingsorte' mit Face ID, Touch ID oder Optic ID. Wenn aktiviert, musst du dich mit deinem Finger, Gesicht oder Augen authentifizieren, bevor du auf diese persönlichen Daten zugreifen kannst. Du findest diese Einstellung in deinen Berechtigungen unter 'Sicherheit'."
                ),
                FAQ(
                    question: "Wie aktiviere/deaktiviere ich Face ID für mein Profil?",
                    answer: "Gehe zu Profil → Berechtigungen → 'Sicherheit'. Dort findest du den Toggle 'Biometrische Sicherung'. Wenn aktiviert, werden 'Deine Abenteuer' und 'Deine Lieblingsorte' mit Face ID/Touch ID/Optic ID geschützt. Wenn deaktiviert, hast du direkten Zugriff auf diese Bereiche. Die Einstellung wird automatisch für alle unterstützten biometrischen Verfahren deines Geräts verwendet."
                ),
                FAQ(
                    question: "Was passiert wenn Face ID fehlschlägt?",
                    answer: "Wenn die biometrische Authentifizierung fehlschlägt (z.B. Face ID nicht erkannt), siehst du eine Fehlermeldung und bleibst auf der aktuellen Seite. Du kannst es erneut versuchen, indem du nochmal auf den entsprechenden Bereich tippst. Falls Face ID auf deinem Gerät nicht verfügbar ist (z.B. im Simulator), funktioniert der Zugriff automatisch ohne Authentifizierung."
                )
            ]
        ),
        
        // Rechtliche Informationen
        FAQCategory(
            title: "Rechtliches",
            icon: "🔒",
            faqs: [
                FAQ(
                    question: "Wo finde ich die rechtlichen Informationen?",
                    answer: "Im Profil-Bereich findest du alle rechtlichen Dokumente: 'Impressum' mit Unternehmensinformationen, 'AGB' mit den Nutzungsbedingungen und 'Datenschutzerklärung' mit Details zum Umgang mit deinen Daten. Alle Dokumente entsprechen den deutschen Rechtsvorgaben und sind kostenlos einsehbar."
                ),
                FAQ(
                    question: "Was regeln die AGB (Allgemeine Geschäftsbedingungen)?",
                    answer: "Die AGB legen fest, wie du die Smart City Guide App nutzen darfst und welche Rechte und Pflichten damit verbunden sind. Sie regeln unter anderem: erlaubte Nutzung der App, Haftungsausschlüsse, Urheberrechte und Updates. Da die App kostenlos ist, fallen keine Zahlungsbedingungen an."
                )
            ]
        )
    ]
}

// MARK: - Preview
#Preview {
    HelpSupportView()
}