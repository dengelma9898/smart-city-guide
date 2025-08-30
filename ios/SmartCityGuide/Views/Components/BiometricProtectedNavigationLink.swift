//
//  BiometricProtectedNavigationLink.swift
//  SmartCityGuide
//
//  Created on 2025-08-27
//  NavigationLink wrapper mit biometrischer Authentifizierung
//

import SwiftUI

// MARK: - Biometric Protected Navigation Link

/// NavigationLink der biometrische Authentifizierung vor der Navigation erfordert
struct BiometricProtectedNavigationLink<Destination: View, Label: View>: View {
    let destination: Destination
    let authenticationMessage: String
    let label: Label
    
    @ObservedObject private var biometricService = BiometricAuthenticationService.shared
    @ObservedObject private var settingsManager = ProfileSettingsManager.shared
    @State private var isAuthenticated = false
    @State private var showingAuthenticationError = false
    @State private var authenticationError: String?
    
    init(
        destination: Destination,
        authenticationMessage: String,
        @ViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.authenticationMessage = authenticationMessage
        self.label = label()
    }
    
    var body: some View {
        Button(action: {
            Task {
                await authenticateAndNavigate()
            }
        }) {
            label
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: destination,
                isActive: $isAuthenticated
            ) {
                EmptyView()
            }
            .hidden()
        )
        .alert("Authentifizierung fehlgeschlagen", isPresented: $showingAuthenticationError) {
            Button("OK") {
                authenticationError = nil
            }
        } message: {
            if let error = authenticationError {
                Text(error)
            }
        }
    }
    
    private func authenticateAndNavigate() async {
        // Prüfe ob biometrische Sicherung in Settings aktiviert ist
        guard settingsManager.isBiometricSecurityEnabled else {
            // Sicherung deaktiviert: Direkt navigieren
            await MainActor.run {
                isAuthenticated = true
            }
            return
        }
        
        // Prüfe ob Biometrics verfügbar sind
        guard biometricService.isAvailable else {
            // Fallback: Direkt navigieren wenn keine Biometrics verfügbar
            await MainActor.run {
                isAuthenticated = true
            }
            return
        }
        
        // Führe Authentifizierung durch
        let success = await biometricService.authenticate(reason: authenticationMessage)
        
        await MainActor.run {
            if success {
                isAuthenticated = true
            } else {
                authenticationError = "Zugriff verweigert. Authentifizierung erforderlich."
                showingAuthenticationError = true
            }
        }
    }
}

// MARK: - Convenience Initializers

extension BiometricProtectedNavigationLink where Label == ProfileRow {
    /// Convenience Initializer für ProfileRow
    init(
        destination: Destination,
        authenticationMessage: String,
        icon: String,
        title: String,
        subtitle: String
    ) {
        self.init(
            destination: destination,
            authenticationMessage: authenticationMessage
        ) {
            ProfileRow(
                icon: icon,
                title: title,
                subtitle: subtitle
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        VStack {
            BiometricProtectedNavigationLink(
                destination: Text("Geschützter Bereich"),
                authenticationMessage: "Zugriff auf geschützte Daten",
                icon: "clock.fill",
                title: "Geschützter Bereich",
                subtitle: "Biometrische Authentifizierung erforderlich"
            )
            .padding()
        }
    }
}
