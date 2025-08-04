import Foundation
import CoreLocation

// MARK: - HERE API Service

class HEREAPIService: ObservableObject {
    static let shared = HEREAPIService()
    
    // Secure Logging - lazy init to avoid main actor issues
    private lazy var secureLogger = SecureLogger.shared
    
    // Network Security with Certificate Pinning
    private let networkSecurity = NetworkSecurityManager.shared
    
    // Secure API Key loading from APIKeys.plist
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["HERE_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("HERE_API_KEY not found in APIKeys.plist. Please add the APIKeys.plist file to your Xcode project with your HERE API Key.")
        }
        return key
    }
    private let baseURL = "https://discover.search.hereapi.com/v1"
    private let geocodeURL = "https://geocoder.ls.hereapi.com/6.2"
    private let urlSession: URLSession
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(urlSession: URLSession? = nil) {
        // Use secure session with certificate pinning by default
        self.urlSession = urlSession ?? NetworkSecurityManager.shared.secureSession
        secureLogger.logInfo("🔐 HEREAPIService initialized with certificate pinning", category: .security)
    }
    
    // MARK: - Public API
    
    /// Fetches POIs for a given city name with caching and rate limit handling
    func fetchPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories, retryCount: Int = 0) async throws -> [POI] {
        // Check cache first
        if let cachedPOIs = await POICacheService.shared.getCachedPOIs(for: cityName) {
            // Cache hit - no logging needed
            return cachedPOIs
        }
        
        // Cache miss - fetch from API
        secureLogger.logInfo("🌐 Fetching POIs for '\(cityName)' (attempt \(retryCount + 1))", category: .data)
        
        do {
            // Step 1: Geocode the city to get coordinates
            let cityLocation = try await geocodeCity(cityName)
            
            // Step 2: Search for POIs around the city
            let pois = try await searchPOIs(near: cityLocation, categories: categories, cityName: cityName)
            
            // Cache the results
            await POICacheService.shared.cachePOIs(pois, for: cityName)
            
            return pois
            
        } catch HEREError.rateLimitExceeded {
            if retryCount < 1 { // Allow 1 retry for the main method
                secureLogger.logWarning("🌐 HERE API rate limit exceeded, retrying...", category: .general)
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 second delay
                return try await fetchPOIs(for: cityName, categories: categories, retryCount: retryCount + 1)
            } else {
                throw HEREError.rateLimitExceeded
            }
        }
    }
    
    /// NEW: Direct POI search with coordinates (eliminates geocoding entirely!)
    func fetchPOIs(at coordinates: CLLocationCoordinate2D, cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories) async throws -> [POI] {
        secureLogger.logCoordinates(coordinates, context: "Direct POI search for '\(cityName)'")
        
        // Check cache first
        if let cachedPOIs = await POICacheService.shared.getCachedPOIs(for: cityName) {
            // Cache hit - no logging needed
            return cachedPOIs
        }
        
        let pois = try await searchPOIs(near: coordinates, categories: categories, cityName: cityName)
        await POICacheService.shared.cachePOIs(pois, for: cityName)
        return pois
    }
    
    // MARK: - Private Implementation
    
    private func geocodeCity(_ cityName: String) async throws -> CLLocationCoordinate2D {
        // Extract city name from full address if needed
        let cleanCityName = extractCityFromInput(cityName)
        
        // 🚀 CHECK CACHE FIRST - eliminates geocoding API call for known cities!
        if let cachedCoordinates = CityCoordinatesCache.getCoordinates(for: cleanCityName) {
            secureLogger.logCoordinates(cachedCoordinates, context: "Cached coordinates for '\(cleanCityName)'")
            return cachedCoordinates
        }
        
        secureLogger.logInfo("🗺️ City not in cache, using Geocoding API", category: .data)
        
        let encodedCity = cleanCityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanCityName
        let urlString = "\(geocodeURL)/geocode.json?searchtext=\(encodedCity)&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw HEREError.invalidURL
        }
        
        do {
            // Minimal delay for geocoding
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HEREError.invalidResponse(statusCode: -1)
            }
            
            // Handle rate limiting specifically
            if httpResponse.statusCode == 429 {
                // Extract more details from rate limiting response  
                if let responseString = String(data: data, encoding: .utf8) {
                    // Rate limit details logged via SecureLogger
                }
                secureLogger.logWarning("🌐 Geocoding rate limit hit, retrying...", category: .general)
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                throw HEREError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                // Extract error details from geocoding API response
                if let responseString = String(data: data, encoding: .utf8) {
                    secureLogger.logError("🌐 Geocoding API Error \(httpResponse.statusCode)", category: .general)
                }
                throw HEREError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            let geocodeResponse = try JSONDecoder().decode(HEREGeocodeResponse.self, from: data)
            
            guard let result = geocodeResponse.Response.View.first?.Result.first?.Location.DisplayPosition else {
                throw HEREError.cityNotFound(cleanCityName)
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: result.Latitude, longitude: result.Longitude)
        secureLogger.logCoordinates(coordinates, context: "Geocoded '\(cleanCityName)'")
            return CLLocationCoordinate2D(latitude: result.Latitude, longitude: result.Longitude)
            
        } catch let error as HEREError {
            throw error
        } catch {
            throw HEREError.geocodingFailed(error.localizedDescription)
        }
    }
    
    private func extractCityFromInput(_ input: String) -> String {
        // If input looks like a full address, try to extract city name
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it contains postal code pattern (5 digits)
        let postalCodePattern = #"\b\d{5}\b"#
        if let regex = try? NSRegularExpression(pattern: postalCodePattern),
           let match = regex.firstMatch(in: trimmedInput, range: NSRange(trimmedInput.startIndex..., in: trimmedInput)) {
            
            // Extract city name after postal code
            let matchRange = Range(match.range, in: trimmedInput)!
            let afterPostalCode = String(trimmedInput[matchRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !afterPostalCode.isEmpty {
                // City extracted successfully
                return afterPostalCode
            }
        }
        
        // If no postal code found, check for comma-separated format
        let components = trimmedInput.components(separatedBy: ",")
        if components.count > 1 {
            // Take the last non-empty component as potential city
            for component in components.reversed() {
                let cleanComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanComponent.isEmpty && !cleanComponent.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
                    // City extracted successfully
                    return cleanComponent
                }
            }
        }
        
        // NEW: Handle "City Street Number" format (e.g., "Feucht Bienenweg 4")
        let words = trimmedInput.components(separatedBy: " ")
        if words.count >= 2 {
            // If the last word is a number, assume first word is the city
            if let lastWord = words.last, lastWord.allSatisfy(\.isNumber) {
                let cityName = words.first!
                // City name extracted from address
                return cityName
            }
            
            // If last 2 words contain numbers/street info, take first word as city
            let lastTwoWords = Array(words.suffix(2)).joined(separator: " ")
            if lastTwoWords.contains(where: \.isNumber) || 
               lastTwoWords.lowercased().contains("str") || 
               lastTwoWords.lowercased().contains("weg") ||
               lastTwoWords.lowercased().contains("platz") {
                let cityName = words.first!
                // Street address pattern detected
                return cityName
            }
        }
        
        // Return original input if no extraction needed
        return trimmedInput
    }
    
    private func searchPOIs(near location: CLLocationCoordinate2D, categories: [PlaceCategory], cityName: String) async throws -> [POI] {
        await MainActor.run {
            isLoading = true
        }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // 🚀 HERE BROWSE API: Category-based search for precise POI filtering
        let categoryIDs = categories.map { $0.hereBrowseCategoryID }
        let categoriesParam = categoryIDs.joined(separator: ",")
        
        // HERE Browse API with Level 3 Category IDs for precise results:
        // GET /browse?at=lat,lng&categories=300-3000-0000,300-3100-0000&limit=50&apiKey=key
        let urlString = "\(baseURL)/browse?at=\(location.latitude),\(location.longitude)&categories=\(categoriesParam)&limit=50&apiKey=\(apiKey)"
        
        secureLogger.logAPIRequest(url: urlString, category: .here)
        
        guard let url = URL(string: urlString) else {
            throw HEREError.invalidURL
        }
        
        do {
            // Minimal delay since we only make one API call
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HEREError.invalidResponse(statusCode: -1)
            }
            
            if httpResponse.statusCode == 429 {
                // Extract more details from rate limiting response
                if let responseString = String(data: data, encoding: .utf8) {
                    secureLogger.logWarning("🌐 HERE API rate limit hit", category: .general)
                }
                throw HEREError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                // Extract error details from API response
                if let responseString = String(data: data, encoding: .utf8) {
                    secureLogger.logError("🌐 HERE API Error \(httpResponse.statusCode)", category: .general)
                }
                throw HEREError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            // Debug: Print actual API response to understand format
            if let responseString = String(data: data, encoding: .utf8) {
                secureLogger.logAPIResponseData(String(responseString.prefix(500)), category: .here)
            }
            
            let searchResponse = try JSONDecoder().decode(HERESearchResponse.self, from: data)
            
            // Convert to POIs and categorize them intelligently
            let allPOIs = searchResponse.items.compactMap { item -> POI? in
                let detectedCategory = detectCategory(for: item)
                return POI(from: item, category: detectedCategory, requestedCity: cityName)
            }
            
            // Remove duplicates but keep all POIs for better selection downstream
            let uniquePOIs = Array(Set(allPOIs))
            
            secureLogger.logPOISearch(cityName: cityName, poiCount: uniquePOIs.count)
            return uniquePOIs
            
        } catch HEREError.rateLimitExceeded {
            throw HEREError.rateLimitExceeded
        } catch {
            secureLogger.logAPIError(error, category: .here)
            throw HEREError.searchFailed("Failed to search POIs: \(error.localizedDescription)")
        }
    }
    
    /// Intelligently detects the category of a POI based on its name and properties
    private func detectCategory(for item: HERESearchItem) -> PlaceCategory {
        let title = item.title.lowercased()
        let categoryIds = item.categories?.compactMap { $0.id } ?? []
        
        // Check for museums first (most specific)
        if title.contains("museum") || title.contains("gallery") || 
           categoryIds.contains(where: { $0.contains("museum") || $0.contains("gallery") }) {
            return .museum
        }
        
        // Check for parks and gardens
        if title.contains("park") || title.contains("garden") || title.contains("garten") ||
           categoryIds.contains(where: { $0.contains("park") || $0.contains("garden") }) {
            return .park
        }
        
        // Default to attraction for everything else
        return .attraction
    }
    
    // OLD CODE REMOVED: searchPOIsForCategory - replaced by single API call in searchPOIs
}

// MARK: - City Coordinates Cache

/// Static cache of known German city coordinates to avoid geocoding API calls
struct CityCoordinatesCache {
    static let coordinates: [String: CLLocationCoordinate2D] = [
        // Major cities
        "berlin": CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        "münchen": CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820),
        "munich": CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820),
        "hamburg": CLLocationCoordinate2D(latitude: 53.5511, longitude: 9.9937),
        "köln": CLLocationCoordinate2D(latitude: 50.9375, longitude: 6.9603),
        "cologne": CLLocationCoordinate2D(latitude: 50.9375, longitude: 6.9603),
        "frankfurt": CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821),
        "stuttgart": CLLocationCoordinate2D(latitude: 48.7758, longitude: 9.1829),
        "düsseldorf": CLLocationCoordinate2D(latitude: 51.2277, longitude: 6.7735),
        "leipzig": CLLocationCoordinate2D(latitude: 51.3397, longitude: 12.3731),
        "dortmund": CLLocationCoordinate2D(latitude: 51.5136, longitude: 7.4653),
        "essen": CLLocationCoordinate2D(latitude: 51.4556, longitude: 7.0116),
        "bremen": CLLocationCoordinate2D(latitude: 53.0793, longitude: 8.8017),
        "dresden": CLLocationCoordinate2D(latitude: 51.0504, longitude: 13.7373),
        "hannover": CLLocationCoordinate2D(latitude: 52.3759, longitude: 9.7320),
        "nürnberg": CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767),
        "nuremberg": CLLocationCoordinate2D(latitude: 49.4521, longitude: 11.0767),
        
        // Bavarian cities (around Nuremberg)
        "feucht": CLLocationCoordinate2D(latitude: 49.3794, longitude: 11.2058),
        "erlangen": CLLocationCoordinate2D(latitude: 49.5897, longitude: 11.0044),
        "fürth": CLLocationCoordinate2D(latitude: 49.4775, longitude: 10.9888),
        "bamberg": CLLocationCoordinate2D(latitude: 49.8988, longitude: 10.9027),
        "regensburg": CLLocationCoordinate2D(latitude: 49.0134, longitude: 12.1016),
        "würzburg": CLLocationCoordinate2D(latitude: 49.7913, longitude: 9.9534),
        "augsburg": CLLocationCoordinate2D(latitude: 48.3705, longitude: 10.8978),
        "ingolstadt": CLLocationCoordinate2D(latitude: 48.7665, longitude: 11.4257),
        
        // Other popular cities
        "heidelberg": CLLocationCoordinate2D(latitude: 49.3988, longitude: 8.6724),
        "kiel": CLLocationCoordinate2D(latitude: 54.3233, longitude: 10.1228),
        "magdeburg": CLLocationCoordinate2D(latitude: 52.1205, longitude: 11.6276),
        "freiburg": CLLocationCoordinate2D(latitude: 47.9990, longitude: 7.8421),
        "rostock": CLLocationCoordinate2D(latitude: 54.0887, longitude: 12.1403),
        "kassel": CLLocationCoordinate2D(latitude: 51.3127, longitude: 9.4797),
        "halle": CLLocationCoordinate2D(latitude: 51.4819, longitude: 11.9697),
        "mainz": CLLocationCoordinate2D(latitude: 49.9929, longitude: 8.2473),
        "saarbrücken": CLLocationCoordinate2D(latitude: 49.2401, longitude: 6.9969),
        "potsdam": CLLocationCoordinate2D(latitude: 52.3906, longitude: 13.0645),
        "oldenburg": CLLocationCoordinate2D(latitude: 53.1435, longitude: 8.2146),
        "osnabrück": CLLocationCoordinate2D(latitude: 52.2799, longitude: 8.0472),
        "lübeck": CLLocationCoordinate2D(latitude: 53.8655, longitude: 10.6866),
        "erfurt": CLLocationCoordinate2D(latitude: 50.9848, longitude: 11.0299)
    ]
    
    static func getCoordinates(for cityName: String) -> CLLocationCoordinate2D? {
        let normalizedCity = cityName.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
        
        return coordinates[normalizedCity]
    }
}

// MARK: - HERE API Response Models

struct HEREGeocodeResponse: Codable {
    let Response: HEREGeocodeMainResponse
}

struct HEREGeocodeMainResponse: Codable {
    let View: [HEREGeocodeView]
}

struct HEREGeocodeView: Codable {
    let Result: [HEREGeocodeResult]
}

struct HEREGeocodeResult: Codable {
    let Location: HERELocation
}

struct HERELocation: Codable {
    let DisplayPosition: HEREPosition
    let Address: HEREAddress?
}

struct HEREPosition: Codable {
    let Latitude: Double
    let Longitude: Double
}

struct HEREAddress: Codable {
    let Label: String?
    let Country: String?
    let State: String?
    let County: String?
    let City: String?
    let District: String?
    let Street: String?
    let HouseNumber: String?
    let PostalCode: String?
}

struct HERESearchResponse: Codable {
    let items: [HERESearchItem] // CORRECTED: HERE API returns "items" not "results"
}

struct HERESearchItem: Codable {
    let title: String
    let id: String
    let position: HERESearchPosition
    let address: HERESearchAddress?
    let contacts: [HEREContact]?
    let openingHours: [HEREOpeningHours]?
    let categories: [HERECategory]?
    let access: [HEREAccess]?
    let chains: [HEREChain]?
}

struct HERESearchPosition: Codable {
    let lat: Double
    let lng: Double
}

struct HERESearchAddress: Codable {
    let label: String?
    let countryCode: String?
    let countryName: String?
    let stateCode: String?
    let state: String?
    let county: String?
    let city: String?
    let district: String?
    let street: String?
    let postalCode: String?
    let houseNumber: String?
}

struct HEREContact: Codable {
    let phone: [HEREPhone]?
    let www: [HEREWWW]?
    let email: [HEREEmail]?
}

struct HEREPhone: Codable {
    let value: String
    let categories: [HEREContactCategory]?
}

struct HEREWWW: Codable {
    let value: String
    let categories: [HEREContactCategory]?
}

struct HEREEmail: Codable {
    let value: String
    let categories: [HEREContactCategory]?
}

struct HEREContactCategory: Codable {
    let id: String?
}

struct HEREOpeningHours: Codable {
    let categories: [HEREOpeningHoursCategory]?
    let text: [String]?
    let isOpen: Bool?
    let structured: [HEREStructuredHours]?
}

struct HEREOpeningHoursCategory: Codable {
    let id: String?
}

struct HEREStructuredHours: Codable {
    let start: String?
    let duration: String?
    let recurrence: String?
}

struct HERECategory: Codable {
    let id: String?
    let name: String?
    let primary: Bool?
}

struct HEREAccess: Codable {
    let id: String?
    let name: String?
}

struct HEREChain: Codable {
    let id: String?
    let name: String?
}

// MARK: - HERE API Errors

enum HEREError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case cityNotFound(String)
    case geocodingFailed(String)
    case searchFailed(String)
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die HERE API URL ist ungültig."
        case .invalidResponse(let statusCode):
            return "Ungültige Antwort vom HERE Server. Statuscode: \(statusCode)"
        case .cityNotFound(let city):
            return "Die Stadt '\(city)' konnte nicht gefunden werden. Bitte überprüfen Sie die Schreibweise."
        case .geocodingFailed(let description):
            return "Geocoding fehlgeschlagen: \(description)"
        case .searchFailed(let description):
            return "POI-Suche fehlgeschlagen: \(description)"
        case .rateLimitExceeded:
            return "Zu viele Anfragen an HERE API. Bitte warten Sie einen Moment und versuchen Sie es erneut."
        }
    }
}

// MARK: - PlaceCategory HERE Integration

extension PlaceCategory {
    // Essential categories to avoid rate limiting - only 4 Level 3 categories
        static let essentialCategories: [PlaceCategory] = [
        .attraction,        // Tourist Attraction  
        .monument,          // Historical Monument
        .castle,            // Castle
        .landmarkAttraction,// Landmark-Attraction
        .museum,            // Museum (Level 2 - all museums)
        .waterfall,         // Natural: Waterfall
        .river,             // Natural: River
        .canal,             // Natural: Canal
        .lake               // Natural: Lake
    ]
    
    /// HERE Browse API Category IDs - Korrekte IDs aus offizieller HERE Dokumentation
    var hereBrowseCategoryID: String {
        switch self {
        // 300 Series: Sights and Museums
        case .attraction:
            return "300-3000-0023"  // Tourist Attraction
        case .monument:
            return "300-3000-0025"  // Historical Monument
        case .castle:
            return "300-3000-0030"  // Castle
        case .landmarkAttraction:
            return "300-3000-0000"  // Landmark-Attraction (base-level)
        case .museum:
            return "300-3100-0000"  // Museum (base-level)
        case .gallery:
            return "300-3000-0024"  // Gallery
            
        // 350 Series: Natural and Geographical Features
        case .waterfall:
            return "350-3500-0235"  // Waterfall
        case .river:
            return "350-3500-0302"  // River
        case .canal:
            return "350-3500-0303"  // Canal
        case .lake:
            return "350-3500-0304"  // Lake
        default:
            return "300-3000-0023"  // Default to Tourist Attraction
        }
    }
    
    var hereSearchQuery: String {
        switch self {
        case .attraction:
            return "tourist attraction"
        case .museum:
            return "museum"
        case .gallery:
            return "art gallery"
        case .artwork:
            return "public art"
        case .viewpoint:
            return "viewpoint scenic lookout"
        case .monument:
            return "monument"
        case .memorial:
            return "memorial"
        case .castle:
            return "castle palace"
        case .ruins:
            return "ruins archaeological site"
        case .archaeologicalSite:
            return "archaeological site"
        case .park:
            return "park"
        case .garden:
            return "botanical garden"
        case .artsCenter:
            return "arts center cultural center"
        case .townhall:
            return "town hall city hall"
        case .placeOfWorship:
            return "place of worship church"
        case .cathedral:
            return "cathedral"
        case .chapel:
            return "chapel"
        case .monastery:
            return "monastery"
        case .shrine:
            return "shrine"
        case .spring:
            return "natural spring"
        case .waterfall:
            return "waterfall"
        case .river:
            return "river stream"
        case .canal:
            return "canal channel waterway"
        case .lake:
            return "lake"
        case .nationalPark:
            return "national park nature reserve"
        case .landmarkAttraction:
            return "landmark famous site"
        }
    }
}

// MARK: - POI Extension for HERE

extension POI {
    init?(from item: HERESearchItem, category: PlaceCategory, requestedCity: String) {
        self.id = "here_\(item.id)"
        self.name = item.title
        self.latitude = item.position.lat
        self.longitude = item.position.lng
        self.category = category
        self.overpassType = "here_poi"
        self.overpassId = Int64(item.id.hashValue)
        
        // Extract description from categories
        if let categories = item.categories, !categories.isEmpty {
            self.description = categories.compactMap { $0.name }.joined(separator: ", ")
        } else {
            self.description = category.rawValue
        }
        
        // Build tags from HERE data for compatibility
        var tags: [String: String] = [:]
        if let address = item.address {
            if let street = address.street { tags["addr:street"] = street }
            if let houseNumber = address.houseNumber { tags["addr:housenumber"] = houseNumber }
            if let city = address.city { tags["addr:city"] = city }
            if let postalCode = address.postalCode { tags["addr:postcode"] = postalCode }
            if let country = address.countryName { tags["addr:country"] = country }
        }
        
        // Add contact information to tags
        if let contacts = item.contacts {
            for contact in contacts {
                if let phones = contact.phone, let phone = phones.first {
                    tags["phone"] = phone.value
                }
                if let websites = contact.www, let website = websites.first {
                    tags["website"] = website.value
                }
                if let emails = contact.email, let email = emails.first {
                    tags["email"] = email.value
                }
            }
        }
        
        // Add opening hours
        if let openingHours = item.openingHours, let hours = openingHours.first, let text = hours.text?.first {
            tags["opening_hours"] = text
        }
        
        self.tags = tags
        
        // Extract address information
        if let hereAddress = item.address {
            self.address = POIAddress(
                street: hereAddress.street,
                houseNumber: hereAddress.houseNumber,
                city: hereAddress.city,
                postcode: hereAddress.postalCode,
                country: hereAddress.countryName
            )
        } else {
            self.address = nil
        }
        
        // Extract contact information
        var phone: String?
        var email: String?
        var website: String?
        
        if let contacts = item.contacts {
            for contact in contacts {
                if phone == nil, let phones = contact.phone, let firstPhone = phones.first {
                    phone = firstPhone.value
                }
                if email == nil, let emails = contact.email, let firstEmail = emails.first {
                    email = firstEmail.value
                }
                if website == nil, let websites = contact.www, let firstWebsite = websites.first {
                    website = firstWebsite.value
                }
            }
        }
        
        if phone != nil || email != nil || website != nil {
            self.contact = POIContact(phone: phone, email: email, website: website)
        } else {
            self.contact = nil
        }
        
        // Extract accessibility information (HERE doesn't provide this directly)
        self.accessibility = nil
        
        // Extract pricing information (HERE doesn't provide this directly)
        self.pricing = nil
        
        // Extract operating hours
        if let openingHours = item.openingHours, let hours = openingHours.first, let text = hours.text?.first {
            self.operatingHours = text
        } else {
            self.operatingHours = nil
        }
        
        // Extract website
        var extractedWebsite: String?
        if let contacts = item.contacts {
            for contact in contacts {
                if let websites = contact.www, let website = websites.first {
                    extractedWebsite = website.value
                    break
                }
            }
        }
        self.website = extractedWebsite
    }
}

extension POI: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: POI, rhs: POI) -> Bool {
        return lhs.id == rhs.id
    }
}