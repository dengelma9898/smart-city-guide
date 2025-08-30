//
//  BiometricAuthenticationService.swift
//  SmartCityGuide
//
//  Created on 2025-08-27
//  Service for handling biometric authentication for sensitive profile features
//

import Foundation
import LocalAuthentication
import SwiftUI
import os.log

// MARK: - Biometric Authentication Service

/// Service für biometrische Authentifizierung bei sensiblen Profile-Bereichen
@MainActor
class BiometricAuthenticationService: ObservableObject {
    static let shared = BiometricAuthenticationService()
    
    @Published var isAvailable = false
    @Published var biometryType: LABiometryType = .none
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "BiometricAuth")
    
    private init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Availability Check
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometryType = context.biometryType
        
        #if targetEnvironment(simulator)
        logger.info("🔐 BiometricAuth: Running in SIMULATOR - Biometrics disabled")
        isAvailable = false
        biometryType = .none
        #endif
        
        logger.info("🔐 BiometricAuth: Available: \(self.isAvailable), Type: \(self.biometryTypeString)")
        
        if let error = error {
            logger.error("🔐 BiometricAuth: Error checking availability: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication
    
    /// Führt biometrische Authentifizierung durch
    /// - Parameter reason: Grund für die Authentifizierung
    /// - Returns: True wenn authentifiziert, False wenn fehlgeschlagen oder abgebrochen
    func authenticate(reason: String) async -> Bool {
        guard isAvailable else {
            logger.warning("🔐 BiometricAuth: Not available, skipping authentication")
            return true // Fallback: Erlaube Zugriff wenn Biometrics nicht verfügbar
        }
        
        let context = LAContext()
        context.localizedReason = reason
        context.localizedFallbackTitle = "Passcode verwenden"
        context.localizedCancelTitle = "Abbrechen"
        
        do {
            let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            logger.info("🔐 BiometricAuth: Authentication \(result ? "successful" : "failed")")
            return result
        } catch {
            logger.error("🔐 BiometricAuth: Authentication error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Authentifiziert für "Deine Abenteuer" Zugriff
    func authenticateForAdventures() async -> Bool {
        return await authenticate(reason: "Zugriff auf deine persönlichen Abenteuer und Routen-Historie")
    }
    
    /// Authentifiziert für "Deine Lieblingsorte" Zugriff
    func authenticateForFavoritePlaces() async -> Bool {
        return await authenticate(reason: "Zugriff auf deine gespeicherten Lieblingsorte")
    }
    
    // MARK: - Helper Properties
    
    var biometryTypeString: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Unknown"
        }
    }
    
    var authenticationIcon: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        @unknown default:
            return "lock.fill"
        }
    }
    
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Biometric Authentication Error

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancel
    case biometryLockout
    case biometryNotEnrolled
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometrische Authentifizierung ist nicht verfügbar"
        case .authenticationFailed:
            return "Authentifizierung fehlgeschlagen"
        case .userCancel:
            return "Vom Benutzer abgebrochen"
        case .biometryLockout:
            return "Biometrische Authentifizierung ist gesperrt"
        case .biometryNotEnrolled:
            return "Keine biometrischen Daten registriert"
        }
    }
}
