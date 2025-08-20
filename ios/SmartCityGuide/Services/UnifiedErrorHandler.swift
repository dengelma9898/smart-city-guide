import Foundation
import SwiftUI

/// Centralized error handling service for consistent error presentation
@MainActor
class UnifiedErrorHandler: ObservableObject {
    
    static let shared = UnifiedErrorHandler()
    
    @Published var currentError: UnifiedError?
    @Published var isShowingError = false
    
    private init() {}
    
    // MARK: - Public API
    
    /// Present a unified error with automatic categorization
    func presentError(_ error: Error, context: String = "") {
        let unifiedError = categorizeError(error, context: context)
        presentUnifiedError(unifiedError)
    }
    
    /// Present a custom unified error
    func presentUnifiedError(_ error: UnifiedError) {
        currentError = error
        isShowingError = true
        
        // Log error for debugging
        SecureLogger.shared.logError(
            "🚨 Unified Error Presented: \(error.category) - \(error.title)",
            category: .general
        )
    }
    
    /// Present error for specific category with custom message
    func presentError(
        category: ErrorCategory,
        title: String? = nil,
        message: String? = nil,
        retryButtonText: String? = nil
    ) {
        let error = UnifiedError(
            category: category,
            title: title,
            message: message,
            retryButtonText: retryButtonText
        )
        presentUnifiedError(error)
    }
    
    /// Dismiss current error
    func dismissError() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingError = false
            currentError = nil
        }
    }
    
    // MARK: - Error Categorization
    
    private func categorizeError(_ error: Error, context: String) -> UnifiedError {
        
        // Check error type and context to determine category
        let errorDescription = error.localizedDescription.lowercased()
        
        // Route Generation Errors
        if context.contains("route") || context.contains("generation") {
            if errorDescription.contains("no routes") || errorDescription.contains("no suitable") {
                return UnifiedError(
                    category: .routeGeneration,
                    message: "Für diese Auswahl konnten keine passenden Routen gefunden werden. Versuche es mit anderen Einstellungen."
                )
            }
            return UnifiedError(category: .routeGeneration)
        }
        
        // Network Errors
        if errorDescription.contains("network") || 
           errorDescription.contains("internet") || 
           errorDescription.contains("connection") ||
           errorDescription.contains("timeout") {
            return UnifiedError(category: .networkConnectivity)
        }
        
        // Location Errors
        if errorDescription.contains("location") || 
           errorDescription.contains("authorization") ||
           context.contains("location") {
            return UnifiedError(category: .locationAccess)
        }
        
        // API Limit Errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("quota") ||
           errorDescription.contains("429") {
            return UnifiedError(category: .apiLimitReached)
        }
        
        // Cache Errors
        if context.contains("cache") || context.contains("storage") {
            return UnifiedError(category: .cacheError)
        }
        
        // Default to general error
        return UnifiedError(
            category: .generalError,
            message: error.localizedDescription
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Quick method for route generation errors
    func presentRouteGenerationError(message: String? = nil) {
        presentError(category: .routeGeneration, message: message)
    }
    
    /// Quick method for location errors
    func presentLocationError(message: String? = nil) {
        presentError(category: .locationAccess, message: message)
    }
    
    /// Quick method for network errors
    func presentNetworkError(message: String? = nil) {
        presentError(category: .networkConnectivity, message: message)
    }
    
    /// Quick method for API limit errors
    func presentAPILimitError() {
        presentError(category: .apiLimitReached)
    }
}

// MARK: - Error Overlay Modifier

extension View {
    /// Add unified error presentation overlay to any view
    func unifiedErrorOverlay(
        errorHandler: UnifiedErrorHandler,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.overlay(
            Group {
                if errorHandler.isShowingError, let error = errorHandler.currentError {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            errorHandler.dismissError()
                        }
                    
                    UnifiedErrorView(
                        error: error,
                        onRetry: onRetry,
                        onDismiss: {
                            errorHandler.dismissError()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: errorHandler.isShowingError)
        )
    }
}

// MARK: - Service Extensions

extension RouteService {
    /// Helper to present route generation errors consistently
    func presentError(_ error: Error) {
        UnifiedErrorHandler.shared.presentError(error, context: "route generation")
    }
}

extension LocationManagerService {
    /// Helper to present location errors consistently  
    func presentLocationError(_ error: Error) {
        UnifiedErrorHandler.shared.presentError(error, context: "location")
    }
}

extension GeoapifyAPIService {
    /// Helper to present API errors consistently
    func presentAPIError(_ error: Error) {
        UnifiedErrorHandler.shared.presentError(error, context: "api")
    }
}

// MARK: - FeatureFlags Extension

extension FeatureFlags {
    /// Enable unified error handling across the app
    static let unifiedErrorHandlingEnabled: Bool = true
    
    /// Enable error analytics and logging
    static let errorAnalyticsEnabled: Bool = true
}
