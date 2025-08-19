import Foundation
import CoreLocation
import SwiftUI

/// Service for generating routes in manual route planning
@MainActor
class ManualRouteGenerationService: ObservableObject {
    
    @Published var generatedRoute: GeneratedRoute?
    @Published var errorMessage: String?
    @Published var isGenerating = false
    
    private let manualService: ManualRouteService
    private let logger = SecureLogger.shared
    
    init(manualService: ManualRouteService? = nil) {
        self.manualService = manualService ?? ManualRouteService()
    }
    
    func generateRoute(config: ManualRouteConfig, selectedPOIs: [POI], discoveredPOIs: [POI]) async {
        isGenerating = true
        errorMessage = nil
        
        logger.logDebug("🟦 ManualRouteGenerationService.generateRoute: start (selected=\(selectedPOIs.count))", category: .ui)
        let request = ManualRouteRequest(
            config: config,
            selectedPOIs: selectedPOIs,
            allDiscoveredPOIs: discoveredPOIs
        )
        
        await manualService.generateRoute(request: request)
        
        if let route = manualService.generatedRoute {
            logger.logDebug("🟩 ManualRouteGenerationService.generateRoute: route ready", category: .ui)
            generatedRoute = route
        } else {
            logger.logWarning("🟥 ManualRouteGenerationService.generateRoute: route generation failed: \(manualService.errorMessage ?? "unknown")", category: .ui)
            errorMessage = manualService.errorMessage ?? "Route generation failed"
        }
        
        isGenerating = false
    }
    
    func clearRoute() {
        generatedRoute = nil
        errorMessage = nil
        isGenerating = false
    }
}
