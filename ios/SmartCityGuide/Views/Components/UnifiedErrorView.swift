import SwiftUI

/// Unified error component with consistent design and retry functionality
struct UnifiedErrorView: View {
    
    // MARK: - Properties
    
    let error: UnifiedError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @State private var isRetrying = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon with animation
            errorIcon
            
            // Error Content
            VStack(spacing: 12) {
                Text(error.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(error.message)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                // Retry Button (if available)
                if let retryAction = onRetry {
                    Button(action: {
                        handleRetry(retryAction)
                    }) {
                        HStack(spacing: 8) {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(isRetrying ? "Versuche erneut..." : error.retryButtonText)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(error.primaryColor)
                        )
                    }
                    .disabled(isRetrying)
                }
                
                // Support/Secondary Action Buttons
                HStack(spacing: 12) {
                    // Support Button
                    if error.showSupportButton {
                        Button(action: openSupportSheet) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Hilfe")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    // Dismiss Button (if available)
                    if let dismissAction = onDismiss {
                        Button(action: dismissAction) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Schließen")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.secondary.opacity(0.1))
                            )
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Error Icon
    
    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(error.primaryColor.opacity(0.15))
                .frame(width: 64, height: 64)
            
            Image(systemName: error.iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(error.primaryColor)
        }
    }
    
    // MARK: - Actions
    
    private func handleRetry(_ retryAction: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isRetrying = true
        }
        
        // Add haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        // Execute retry with delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            retryAction()
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isRetrying = false
            }
        }
    }
    
    private func openSupportSheet() {
        // TODO: Implement support sheet navigation
        // This would typically trigger a sheet with HelpSupportView
        SecureLogger.shared.logInfo("🆘 Support requested for error: \(error.category)", category: .ui)
    }
}

// MARK: - Unified Error Model

struct UnifiedError {
    let category: ErrorCategory
    let title: String
    let message: String
    let retryButtonText: String
    let showSupportButton: Bool
    let primaryColor: Color
    let iconName: String
    
    init(
        category: ErrorCategory,
        title: String? = nil,
        message: String? = nil,
        retryButtonText: String? = nil,
        showSupportButton: Bool = true
    ) {
        self.category = category
        self.title = title ?? category.defaultTitle
        self.message = message ?? category.defaultMessage
        self.retryButtonText = retryButtonText ?? category.defaultRetryText
        self.showSupportButton = showSupportButton
        self.primaryColor = category.primaryColor
        self.iconName = category.iconName
    }
}

// MARK: - Error Categories

enum ErrorCategory {
    case routeGeneration
    case locationAccess
    case networkConnectivity
    case cacheError
    case apiLimitReached
    case generalError
    
    var defaultTitle: String {
        switch self {
        case .routeGeneration:
            return "Route konnte nicht erstellt werden"
        case .locationAccess:
            return "Standort nicht verfügbar"
        case .networkConnectivity:
            return "Keine Internetverbindung"
        case .cacheError:
            return "Daten konnten nicht gespeichert werden"
        case .apiLimitReached:
            return "Service vorübergehend nicht verfügbar"
        case .generalError:
            return "Ein Fehler ist aufgetreten"
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .routeGeneration:
            return "Wir konnten keine passende Route für deine Auswahl finden. Versuche es mit anderen Einstellungen oder einer anderen Stadt."
        case .locationAccess:
            return "Um dir personalisierte Routen zu erstellen, benötigen wir Zugriff auf deinen Standort. Bitte erlaube den Zugriff in den Einstellungen."
        case .networkConnectivity:
            return "Bitte überprüfe deine Internetverbindung und versuche es erneut."
        case .cacheError:
            return "Deine Daten konnten nicht gespeichert werden. Die App funktioniert weiterhin, aber einige Features sind möglicherweise eingeschränkt."
        case .apiLimitReached:
            return "Unser Service ist derzeit stark ausgelastet. Bitte versuche es in ein paar Minuten erneut."
        case .generalError:
            return "Es ist ein unerwarteter Fehler aufgetreten. Bitte versuche es erneut."
        }
    }
    
    var defaultRetryText: String {
        switch self {
        case .routeGeneration:
            return "Erneut versuchen"
        case .locationAccess:
            return "Einstellungen öffnen"
        case .networkConnectivity:
            return "Erneut verbinden"
        case .cacheError:
            return "Erneut speichern"
        case .apiLimitReached:
            return "Erneut versuchen"
        case .generalError:
            return "Erneut versuchen"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .routeGeneration:
            return .orange
        case .locationAccess:
            return .blue
        case .networkConnectivity:
            return .red
        case .cacheError:
            return .yellow
        case .apiLimitReached:
            return .purple
        case .generalError:
            return .gray
        }
    }
    
    var iconName: String {
        switch self {
        case .routeGeneration:
            return "map.fill"
        case .locationAccess:
            return "location.slash.fill"
        case .networkConnectivity:
            return "wifi.slash"
        case .cacheError:
            return "externaldrive.badge.exclamationmark"
        case .apiLimitReached:
            return "hourglass.badge.plus"
        case .generalError:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        UnifiedErrorView(
            error: UnifiedError(category: .routeGeneration),
            onRetry: { print("Retry route generation") },
            onDismiss: { print("Dismiss error") }
        )
        
        UnifiedErrorView(
            error: UnifiedError(category: .networkConnectivity),
            onRetry: { print("Retry connection") },
            onDismiss: nil
        )
    }
    .background(Color(.systemGroupedBackground))
}
