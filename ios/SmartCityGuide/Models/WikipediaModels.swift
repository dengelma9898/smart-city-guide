import Foundation
import CoreLocation

// MARK: - Wikipedia OpenSearch Response
/// Wikipedia OpenSearch API Response Model
/// Response Format: [query, [titles], [descriptions], [urls]]
struct WikipediaOpenSearchResponse {
    let query: String
    let titles: [String]
    let descriptions: [String]
    let urls: [String]
    
    init?(from jsonArray: [Any]) {
        guard jsonArray.count == 4,
              let query = jsonArray[0] as? String,
              let titles = jsonArray[1] as? [String],
              let descriptions = jsonArray[2] as? [String],
              let urls = jsonArray[3] as? [String] else {
            return nil
        }
        
        self.query = query
        self.titles = titles
        self.descriptions = descriptions
        self.urls = urls
    }
    
    /// Kombiniert OpenSearch-Ergebnisse zu strukturierten Objekten
    var searchResults: [WikipediaSearchResult] {
        let count = min(titles.count, descriptions.count, urls.count)
        var results: [WikipediaSearchResult] = []
        
        for i in 0..<count {
            let result = WikipediaSearchResult(
                title: titles[i],
                description: descriptions[i],
                url: urls[i]
            )
            results.append(result)
        }
        
        return results
    }
}

// MARK: - Wikipedia Search Result
struct WikipediaSearchResult {
    let title: String
    let description: String
    let url: String
    
    /// Relevanz-Score basierend auf String-Ähnlichkeit zum ursprünglichen POI-Namen
    func relevanceScore(for poiName: String) -> Double {
        let cleanPOIName = cleanString(poiName)
        let cleanTitle = cleanString(title)
        
        // 1. Exact Match Check (höchste Priorität)
        if cleanTitle == cleanPOIName {
            return 1.0
        }
        
        // 2. Substring-Check für direkte Treffer
        if cleanTitle.contains(cleanPOIName) || cleanPOIName.contains(cleanTitle) {
            return 0.9
        }
        
        // 3. Levenshtein Distance für ähnliche Strings
        let titleSimilarity = levenshteinSimilarity(cleanTitle, cleanPOIName)
        
        // 4. Fallback zu word-based matching (nur für Beschreibung)
        let descriptionSimilarity = stringSimilarity(description.lowercased(), poiName.lowercased())
        
        // Titel ist deutlich wichtiger als Beschreibung
        let score = (titleSimilarity * 0.9) + (descriptionSimilarity * 0.1)
        
        // Mindest-Threshold für gültige Matches
        return score > 0.3 ? score : 0.0
    }
    
    /// Bereinigt Strings für besseres Matching
    private func cleanString(_ string: String) -> String {
        return string.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe") 
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
            .components(separatedBy: .punctuationCharacters).joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Berechnet Levenshtein-basierte Ähnlichkeit (0.0 - 1.0)
    private func levenshteinSimilarity(_ str1: String, _ str2: String) -> Double {
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Berechnet Levenshtein Distance zwischen zwei Strings
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let chars1 = Array(str1)
        let chars2 = Array(str2)
        let len1 = chars1.count
        let len2 = chars2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 {
            matrix[i][0] = i
        }
        for j in 0...len2 {
            matrix[0][j] = j
        }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = chars1[i-1] == chars2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[len1][len2]
    }
    
    /// Berechnet String-Ähnlichkeit (vereinfacht: gemeinsame Wörter)
    private func stringSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let words2 = Set(str2.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Wikipedia Summary Response
struct WikipediaSummary: Codable {
    // Basis-Informationen
    let type: String?
    let title: String?
    let displaytitle: String?
    let namespace: WikipediaNamespace?
    let wikibaseItem: String?
    let titles: WikipediaTitles?
    let pageid: Int?
    
    // Inhalt
    let extract: String?
    let extractHTML: String?
    let description: String?
    let descriptionSource: String?
    
    // Bilder
    let thumbnail: WikipediaImage?
    let originalimage: WikipediaImage?
    
    // URLs
    let contentUrls: WikipediaContentUrls?
    let apiUrls: WikipediaApiUrls?
    
    // Metadaten
    let lang: String?
    let dir: String?
    let revision: String?
    let tid: String?
    let timestamp: String?
    
    // Koordinaten (optional)
    let coordinates: WikipediaCoordinates?
    
    enum CodingKeys: String, CodingKey {
        case type, title, displaytitle, namespace
        case wikibaseItem = "wikibase_item"
        case titles, pageid, extract
        case extractHTML = "extract_html"
        case description
        case descriptionSource = "description_source"
        case thumbnail, originalimage
        case contentUrls = "content_urls"
        case apiUrls = "api_urls"
        case lang, dir, revision, tid, timestamp, coordinates
    }
}

// MARK: - Wikipedia Supporting Models
struct WikipediaNamespace: Codable {
    let id: Int
    let text: String
}

struct WikipediaTitles: Codable {
    let canonical: String?
    let normalized: String?
    let display: String?
}

struct WikipediaImage: Codable {
    let source: String
    let width: Int?
    let height: Int?
    
    /// Generiert Thumbnail-URLs in verschiedenen Größen
    func thumbnailURL(width: Int) -> String {
        if source.contains("/thumb/") {
            // Bereits ein Thumbnail - URL anpassen
            let components = source.components(separatedBy: "/")
            let filename = components.last ?? ""
            let basePath = components.dropLast().joined(separator: "/")
            return "\(basePath)/\(width)px-\(filename)"
        } else {
            // Original-Bild zu Thumbnail konvertieren
            let components = source.components(separatedBy: "/")
            guard let filenameWithExtension = components.last else { return source }
            
            let filename = filenameWithExtension
            let pathComponents = components.dropLast()
            let basePath = pathComponents.joined(separator: "/")
            
            return "\(basePath)/thumb/\(filename)/\(width)px-\(filename)"
        }
    }
}

struct WikipediaContentUrls: Codable {
    let desktop: WikipediaUrlSet?
    let mobile: WikipediaUrlSet?
}

struct WikipediaUrlSet: Codable {
    let page: String?
    let revisions: String?
    let edit: String?
}

struct WikipediaApiUrls: Codable {
    let summary: String?
    let metadata: String?
    let references: String?
    let media: String?
    let editHTML: String?
    let talkPageHTML: String?
    
    enum CodingKeys: String, CodingKey {
        case summary, metadata, references, media
        case editHTML = "edit_html"
        case talkPageHTML = "talk_page_html"
    }
}

struct WikipediaCoordinates: Codable {
    let lat: Double
    let lon: Double
    
    /// Konvertiert zu CoreLocation
    var clLocation: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Berechnet Entfernung zu einem anderen Punkt
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: lat, longitude: lon)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - Wikipedia-enriched POI
/// POI erweitert um Wikipedia-Daten
struct WikipediaEnrichedPOI {
    let basePOI: POI
    let wikipediaData: WikipediaSummary?
    let searchResult: WikipediaSearchResult?
    let enrichmentTimestamp: Date
    let relevanceScore: Double
    
    // MARK: - Convenience Properties
    
    /// Wikipedia-Beschreibung falls verfügbar, sonst Original-POI-Beschreibung
    var enhancedDescription: String {
        if let extract = wikipediaData?.extract, !extract.isEmpty {
            return extract
        }
        return basePOI.description ?? "Zu diesem Ort haben wir leider keine weiteren Infos gefunden."
    }
    
    /// Wikipedia-Bild falls verfügbar
    var wikipediaImageURL: String? {
        return wikipediaData?.thumbnail?.source ?? wikipediaData?.originalimage?.source
    }
    
    /// Wikipedia-Link für weitere Informationen
    var wikipediaURL: String? {
        return wikipediaData?.contentUrls?.desktop?.page ?? searchResult?.url
    }
    
    /// Kurze Wikipedia-Beschreibung
    var shortDescription: String? {
        return wikipediaData?.description
    }
    
    /// Koordinaten-Validierung (falls Wikipedia-Koordinaten verfügbar)
    var isLocationValidated: Bool {
        guard let coordinates = wikipediaData?.coordinates else { return false }
        let distance = coordinates.distance(to: basePOI.coordinate)
        return distance < 1000 // Maximal 1km Entfernung
    }
    
    /// Qualitäts-Score für die Wikipedia-Anreicherung
    var qualityScore: Double {
        var score = relevanceScore
        
        // Bonus für verfügbare Daten
        if wikipediaData?.extract != nil { score += 0.1 }
        if wikipediaData?.thumbnail != nil { score += 0.1 }
        if isLocationValidated { score += 0.1 }
        if wikipediaData?.description != nil { score += 0.05 }
        
        return min(score, 1.0)
    }
    
    /// Ist die Anreicherung von hoher Qualität?
    var isHighQuality: Bool {
        return qualityScore >= 0.7 && wikipediaData?.extract != nil
    }
}

// MARK: - Wikipedia API Errors
enum WikipediaError: Error, LocalizedError {
    case invalidURL
    case noResults
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Wikipedia-URL"
        case .noResults:
            return "Keine Wikipedia-Ergebnisse gefunden"
        case .invalidResponse:
            return "Ungültige Antwort von Wikipedia"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Dekodierungsfehler: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Wikipedia Rate Limit erreicht"
        }
    }
}