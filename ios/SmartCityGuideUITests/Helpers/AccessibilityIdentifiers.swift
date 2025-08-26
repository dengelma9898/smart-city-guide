import Foundation

/// Zentrale Sammlung aller Accessibility Identifiers für stabile UI-Tests
struct AccessibilityIdentifiers {
    
    // MARK: - Home Screen / Planning
    struct Home {
        static let quickPlanButton = "home.plan.quick"
        static let fullPlanButton = "home.plan.full"
        static let automaticPlanButton = "home.plan.automatic" // Legacy
        static let map = "home.map"
    }
    
    // MARK: - Map Interactions
    struct Map {
        static let mainView = "map.main"
        static let userLocation = "map.userLocation"
        static let routePolyline = "map.route.polyline"
        static let waypointMarker = "map.waypoint.marker"
        static let compass = "map.controls.compass"
        static let scaleView = "map.controls.scale"
        static let zoomIn = "map.controls.zoomIn"
        static let zoomOut = "map.controls.zoomOut"
    }
    
    // MARK: - Quick Planning
    struct QuickPlanning {
        static let loadingMessage = "quickPlanning.loadingMessage"
        static let progressIndicator = "quickPlanning.progress"
    }
    
    // MARK: - Active Route
    struct ActiveRoute {
        static let sheetCollapsed = "activeRoute.sheet.collapsed"
        static let sheetExpanded = "activeRoute.sheet.expanded"
        static let endButton = "activeRoute.action.end"
        static let addStopButton = "activeRoute.action.addStop"
        static let tourLabel = "activeRoute.label.tour"
        static let stopsCounter = "activeRoute.label.stops"
        static let poiList = "activeRoute.list.pois"
        static let nextStopIndicator = "activeRoute.indicator.nextStop"
    }
    
    // MARK: - Route Planning Sheet
    struct RoutePlanning {
        static let sheet = "routePlanning.sheet"
        static let generateButton = "routePlanning.action.generate"
        static let cancelButton = "routePlanning.action.cancel"
        static let cityInput = "routePlanning.input.city"
        static let stopsSlider = "routePlanning.slider.stops"
        static let timeSlider = "routePlanning.slider.time"
        static let endpointPicker = "routePlanning.picker.endpoint"
    }
    
    // MARK: - Route Customization
    struct RouteCustomization {
        static let manualPlanningSheet = "route.manual.planning.sheet"
        static let generateRouteButton = "manual.generate.route.button"
        static let poiSelectionView = "route.poi.selection.view"
        static let poiSwipeCard = "route.poi.swipe.card"
        static let editPOIButton = "route.edit.poi.button"
        static let deletePOIButton = "route.delete.poi.button"
        static let optimizeButton = "route.optimize.button"
        static let selectionCounter = "route.selection.counter"
        static let swipeAcceptArea = "route.swipe.accept"
        static let swipeRejectArea = "route.swipe.reject"
    }
    
    // MARK: - Error Handling
    struct Error {
        static let dialog = "error.dialog"
        static let title = "error.title"
        static let message = "error.message"
        static let retryButton = "error.action.retry"
        static let dismissButton = "error.action.dismiss"
        static let settingsButton = "error.action.settings"
    }
    
    // MARK: - Profile & Settings
    struct Profile {
        static let view = "profile.view"
        static let avatar = "profile.avatar"
        static let nameField = "profile.name"
        static let settingsButton = "profile.action.settings"
        static let historyButton = "profile.action.history"
        static let helpButton = "profile.action.help"
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let backButton = "navigation.back"
        static let closeButton = "navigation.close"
        static let profileButton = "navigation.profile"
        static let locationButton = "navigation.location"
    }
    
    // MARK: - POI Details
    struct POIDetail {
        static let view = "poiDetail.view"
        static let title = "poiDetail.title"
        static let description = "poiDetail.description"
        static let addButton = "poiDetail.action.add"
        static let removeButton = "poiDetail.action.remove"
        static let wikipediaLink = "poiDetail.link.wikipedia"
    }
    
    // MARK: - Swipe Interface
    struct Swipe {
        static let cardStack = "swipe.cardStack"
        static let currentCard = "swipe.card.current"
        static let likeButton = "swipe.action.like"
        static let passButton = "swipe.action.pass"
        static let undoButton = "swipe.action.undo"
        static let doneButton = "swipe.action.done"
    }
    
    // MARK: - Loading States
    struct Loading {
        static let overlay = "loading.overlay"
        static let progressView = "loading.progress"
        static let message = "loading.message"
    }
    
    // MARK: - Route Success
    struct RouteSuccess {
        static let sheet = "routeSuccess.sheet"
        static let statsView = "routeSuccess.stats"
        static let startButton = "routeSuccess.action.start"
        static let editButton = "routeSuccess.action.edit"
        static let closeButton = "routeSuccess.action.close"
    }
}

// MARK: - Test Helper Extensions
extension AccessibilityIdentifiers {
    
    /// German text patterns commonly found in UI elements
    struct GermanTextPatterns {
        static let planning = ["Route planen", "Schnell planen", "planen"]
        static let tour = ["Tour", "Deine Tour", "läuft"]
        static let stops = ["Stopp", "Stopps", "Nächste"]
        static let ending = ["beenden", "Tour beenden"]
        static let errors = ["Fehler", "Problem", "versuche", "nochmal"]
        static let location = ["Standort", "Berechtigung", "erlauben"]
        static let network = ["Verbindung", "Internet", "Netzwerk"]
        static let loading = ["basteln", "Route", "Wir", "entdecken"]
    }
    
    /// Forbidden terms that should not appear in user-facing messages
    struct ForbiddenTerms {
        static let techPartners = ["HERE", "Geoapify", "MapKit", "API", "OpenStreetMap"]
        static let technical = ["HTTP", "JSON", "SSL", "Certificate", "Exception"]
        static let english = ["Error", "Failed", "Loading", "Success"] // Only if no German equivalent
    }
}
