import Foundation
import CoreLocation

// MARK: - HERE API Service

class HEREAPIService: ObservableObject {
    static let shared = HEREAPIService()
    
    private let apiKey = "IJQ_FHors1UT0Bf-Ekex9Sgg41jDWgOWgcW58EedIWo"
    private let baseURL = "https://discover.search.hereapi.com/v1"
    private let geocodeURL = "https://geocoder.ls.hereapi.com/6.2"
    private let urlSession: URLSession
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Public API
    
    /// Fetches POIs for a given city name with caching and rate limit handling
    func fetchPOIs(for cityName: String, categories: [PlaceCategory] = PlaceCategory.essentialCategories, retryCount: Int = 0) async throws -> [POI] {
        // Check cache first
        if let cachedPOIs = await POICacheService.shared.getCachedPOIs(for: cityName) {
            print("HEREAPIService: Using cached POIs for '\(cityName)'")
            return cachedPOIs
        }
        
        // Cache miss - fetch from API
        print("HEREAPIService: Fetching POIs from HERE API for '\(cityName)' (attempt \(retryCount + 1))")
        
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
                print("HEREAPIService: Rate limit exceeded, retrying after 5 seconds...")
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 second delay
                return try await fetchPOIs(for: cityName, categories: categories, retryCount: retryCount + 1)
            } else {
                throw HEREError.rateLimitExceeded
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func geocodeCity(_ cityName: String) async throws -> CLLocationCoordinate2D {
        // Extract city name from full address if needed
        let cleanCityName = extractCityFromInput(cityName)
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
                print("HEREAPIService: Rate limit hit, waiting 2 seconds...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                throw HEREError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                throw HEREError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            let geocodeResponse = try JSONDecoder().decode(HEREGeocodeResponse.self, from: data)
            
            guard let result = geocodeResponse.Response.View.first?.Result.first?.Location.DisplayPosition else {
                throw HEREError.cityNotFound(cleanCityName)
            }
            
            print("HEREAPIService: Successfully geocoded '\(cleanCityName)' to \(result.Latitude), \(result.Longitude)")
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
                print("HEREAPIService: Extracted city '\(afterPostalCode)' from address '\(trimmedInput)'")
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
                    print("HEREAPIService: Extracted city '\(cleanComponent)' from address '\(trimmedInput)'")
                    return cleanComponent
                }
            }
        }
        
        // Return original input if no extraction needed
        return trimmedInput
    }
    
    private func searchPOIs(near location: CLLocationCoordinate2D, categories: [PlaceCategory], cityName: String) async throws -> [POI] {
        isLoading = true
        defer { isLoading = false }
        
        // 🚀 SINGLE API CALL: Comprehensive search for all tourist POIs
        let combinedQuery = "tourist attraction museum park sightseeing landmark monument"
        let encodedQuery = combinedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? combinedQuery
        
        // Single API call with higher limit to get diverse results
        let urlString = "\(baseURL)/discover?at=\(location.latitude),\(location.longitude)&q=\(encodedQuery)&limit=50&apiKey=\(apiKey)"
        
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
                throw HEREError.rateLimitExceeded
            }
            
            guard httpResponse.statusCode == 200 else {
                throw HEREError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            let searchResponse = try JSONDecoder().decode(HERESearchResponse.self, from: data)
            
            // Convert to POIs and categorize them intelligently
            let allPOIs = searchResponse.results.compactMap { item -> POI? in
                let detectedCategory = detectCategory(for: item)
                return POI(from: item, category: detectedCategory, requestedCity: cityName)
            }
            
            // Remove duplicates and limit to 10 results
            let uniquePOIs = Array(Set(allPOIs))
            let limitedPOIs = Array(uniquePOIs.prefix(10))
            
            print("HEREAPIService: Single API call found \(allPOIs.count) POIs, returning \(limitedPOIs.count) for '\(cityName)'")
            return limitedPOIs
            
        } catch HEREError.rateLimitExceeded {
            throw HEREError.rateLimitExceeded
        } catch {
            print("HEREAPIService: Search failed for '\(cityName)': \(error)")
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
    
    private func searchPOIsForCategory(_ category: PlaceCategory, near location: CLLocationCoordinate2D, cityName: String, retryCount: Int = 0) async throws -> [POI] {
        let categoryQuery = category.hereSearchQuery
        let encodedQuery = categoryQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? categoryQuery
        
        // Search in a 20km radius around the city center - limit to 5 per category for max 15 total
        let urlString = "\(baseURL)/discover?at=\(location.latitude),\(location.longitude)&q=\(encodedQuery)&limit=5&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw HEREError.invalidURL
        }
        
        do {
            // Reduced delay since we only have 3 categories now
            let baseDelay = 100_000_000 // 100ms base delay  
            let categoryDelay = retryCount * 200_000_000 // Additional delay for retries
            try await Task.sleep(nanoseconds: UInt64(baseDelay + categoryDelay))
            
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HEREError.invalidResponse(statusCode: -1)
            }
            
            // Handle rate limiting with retry logic
            if httpResponse.statusCode == 429 {
                if retryCount < 2 { // Max 2 retries
                    let retryDelay = (retryCount + 1) * 2_000_000_000 // 2s, 4s delays
                    print("HEREAPIService: Rate limit hit for '\(category.rawValue)', retrying in \((retryDelay / 1_000_000_000))s (attempt \(retryCount + 1))")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay))
                    return try await searchPOIsForCategory(category, near: location, cityName: cityName, retryCount: retryCount + 1)
                } else {
                    print("HEREAPIService: Max retries reached for '\(category.rawValue)', skipping")
                    return []
                }
            }
            
            guard httpResponse.statusCode == 200 else {
                print("HEREAPIService: HTTP \(httpResponse.statusCode) for category '\(category.rawValue)', skipping")
                return []
            }
            
            let searchResponse = try JSONDecoder().decode(HERESearchResponse.self, from: data)
            
            let pois = searchResponse.results.compactMap { item in
                POI(from: item, category: category, requestedCity: cityName)
            }
            
            print("HEREAPIService: Found \(pois.count) POIs for category '\(category.rawValue)'")
            return pois
            
        } catch let error as HEREError {
            throw error
        } catch {
            print("HEREAPIService: Error searching for category '\(category.rawValue)': \(error)")
            return []
        }
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
    let results: [HERESearchItem]
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
    let id: String
}

struct HEREOpeningHours: Codable {
    let categories: [HEREOpeningHoursCategory]?
    let text: [String]?
    let isOpen: Bool?
    let structured: [HEREStructuredHours]?
}

struct HEREOpeningHoursCategory: Codable {
    let id: String
}

struct HEREStructuredHours: Codable {
    let start: String?
    let duration: String?
    let recurrence: String?
}

struct HERECategory: Codable {
    let id: String
    let name: String?
    let primary: Bool?
}

struct HEREAccess: Codable {
    let id: String
    let name: String?
}

struct HEREChain: Codable {
    let id: String
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
    // Essential categories to avoid rate limiting - only 3 categories = 3 API calls
    static let essentialCategories: [PlaceCategory] = [
        .attraction,  // Main tourist attractions
        .museum,      // Museums 
        .park         // Parks and green spaces
    ]
    
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
        case .lake:
            return "lake"
        case .nationalPark:
            return "national park nature reserve"
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