//
//  IntroModels.swift
//  SmartCityGuide
//
//  Created on 2025-08-26
//  Models for onboarding intro flow
//

import Foundation
import SwiftUI

// MARK: - IntroStep Enum

/// Represents the different steps in the intro onboarding flow
enum IntroStep: String, CaseIterable, Identifiable {
    case welcome = "welcome"
    case locationWhenInUse = "locationWhenInUse"
    case poiNotifications = "poiNotifications"
    case completion = "completion"
    
    var id: String { rawValue }
    
    /// Returns the next step in the intro flow, or nil if this is the last step
    var nextStep: IntroStep? {
        switch self {
        case .welcome:
            return .locationWhenInUse
        case .locationWhenInUse:
            return .poiNotifications
        case .poiNotifications:
            return .completion
        case .completion:
            return nil
        }
    }
    
    /// Indicates whether this step can be skipped
    var canSkip: Bool {
        switch self {
        case .completion:
            return false
        default:
            return true
        }
    }
    
    /// Returns the title for this intro step
    var title: String {
        switch self {
        case .welcome:
            return "Willkommen bei Smart City Guide!"
        case .locationWhenInUse:
            return "Dein Standort für Routen"
        case .poiNotifications:
            return "POI-Benachrichtigungen aktivieren"
        case .completion:
            return "Alles bereit!"
        }
    }
    
    /// Returns the description text for this intro step
    var description: String {
        switch self {
        case .welcome:
            return "Entdecke Städte mit intelligenten Walking-Routen! Wir optimieren deine Route zu den besten Sehenswürdigkeiten, Museen und Parks."
        case .locationWhenInUse:
            return "Damit wir die beste Route von deiner aktuellen Position planen können, benötigen wir Zugriff auf deinen Standort während der App-Nutzung."
        case .poiNotifications:
            return "Erhalte intelligente Benachrichtigungen wenn du während einer aktiven Route interessante Spots erreichst! Dafür benötigen wir Standort-Zugriff im Hintergrund und Mitteilungen."
        case .completion:
            return "Perfekt! Du bist bereit für deine erste intelligente Stadt-Route. Los geht's mit der Entdeckung!"
        }
    }
    
    /// Returns the button text for this intro step
    var buttonText: String {
        switch self {
        case .welcome:
            return "Los geht's!"
        case .locationWhenInUse:
            return "Standort aktivieren"
        case .poiNotifications:
            return "POI-Benachrichtigungen aktivieren"
        case .completion:
            return "Zur App"
        }
    }
    
    /// Returns the icon name for this intro step
    var iconName: String {
        switch self {
        case .welcome:
            return "map.circle.fill"
        case .locationWhenInUse:
            return "location.circle.fill"
        case .poiNotifications:
            return "bell.badge.fill"
        case .completion:
            return "checkmark.circle.fill"
        }
    }
    
    /// Returns the icon color for this intro step
    var iconColor: Color {
        switch self {
        case .welcome:
            return .blue
        case .locationWhenInUse:
            return .green
        case .poiNotifications:
            return .purple
        case .completion:
            return .green
        }
    }
}

// MARK: - IntroFlowViewModel

/// ViewModel for managing the intro flow state and navigation
@MainActor
class IntroFlowViewModel: ObservableObject {
    @Published var currentStep: IntroStep = .welcome
    @Published var showSkipConfirmation: Bool = false
    @Published var isPermissionInProgress: Bool = false
    @Published var permissionErrorMessage: String? = nil
    
    private let userDefaults: UserDefaults
    
    /// Indicates if this is the user's first launch (intro not completed)
    var isFirstLaunch: Bool {
        return !userDefaults.bool(forKey: IntroFlowViewModel.hasCompletedIntroKey)
    }
    
    /// UserDefaults key for tracking intro completion
    static let hasCompletedIntroKey = "hasCompletedIntro"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Moves to the next step in the intro flow with animation
    func moveToNextStep() {
        guard let nextStep = currentStep.nextStep else {
            // Already at the last step, complete the intro
            completeIntro()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = nextStep
        }
    }
    
    /// Shows the skip confirmation dialog
    func showSkipDialog() {
        guard currentStep.canSkip else { return }
        showSkipConfirmation = true
    }
    
    /// Handles skip confirmation - jumps to completion
    func confirmSkip() {
        showSkipConfirmation = false
        skipToCompletion()
    }
    
    /// Cancels the skip action
    func cancelSkip() {
        showSkipConfirmation = false
    }
    
    /// Skips directly to completion step
    func skipToCompletion() {
        currentStep = .completion
        completeIntro()
    }
    
    /// Marks the intro as completed and saves to UserDefaults
    func completeIntro() {
        userDefaults.set(true, forKey: IntroFlowViewModel.hasCompletedIntroKey)
        userDefaults.synchronize()
    }
    
    /// Sets permission in progress state
    func setPermissionInProgress(_ inProgress: Bool) {
        isPermissionInProgress = inProgress
    }
    
    // MARK: - Permission Request Methods
    
    /// Requests location when in use permission
    func requestLocationWhenInUsePermission() async {
        setPermissionInProgress(true)
        permissionErrorMessage = nil
        
        let locationService = LocationManagerService.shared
        await locationService.requestLocationPermission()
        
        // Check if permission was granted
        let isAuthorized = locationService.isLocationAuthorized
        if !isAuthorized && locationService.authorizationStatus == .denied {
            permissionErrorMessage = "Kein Problem! Du kannst die Berechtigung später in den Profileinstellungen aktivieren."
        }
        
        setPermissionInProgress(false)
        
        // Move to next step regardless of permission result
        // User can always grant permissions later in profile
        withAnimation(.easeInOut(duration: 0.4)) {
            guard let nextStep = currentStep.nextStep else {
                completeIntro()
                return
            }
            currentStep = nextStep
        }
    }
    
    /// Requests POI notification permissions (both location always and notifications)
    func requestPOINotificationPermissions() async {
        setPermissionInProgress(true)
        permissionErrorMessage = nil
        
        let locationService = LocationManagerService.shared
        let proximityService = ProximityService.shared
        
        // Request location always permission first
        await locationService.requestAlwaysLocationPermission()
        
        // Request notification permission
        let notificationGranted = await proximityService.requestNotificationPermission()
        
        // Check results and provide appropriate feedback
        let hasLocationAlways = locationService.authorizationStatus == .authorizedAlways
        let hasNotifications = notificationGranted && proximityService.notificationPermissionStatus == .authorized
        
        if !hasLocationAlways && !hasNotifications {
            permissionErrorMessage = "POI-Benachrichtigungen sind optional. Du kannst beide Berechtigungen später in den Profileinstellungen aktivieren."
        } else if !hasLocationAlways {
            permissionErrorMessage = "Standort im Hintergrund ist optional. Du kannst es später in den Profileinstellungen aktivieren."
        } else if !hasNotifications {
            permissionErrorMessage = "Mitteilungen sind optional. Du kannst sie später in den Profileinstellungen aktivieren."
        }
        
        setPermissionInProgress(false)
        
        // Move to next step WITHOUT animation wrapping to avoid interfering with permission dialogs
        guard let nextStep = currentStep.nextStep else {
            completeIntro()
            return
        }
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.currentStep = nextStep
            }
        }
    }
    
    /// Clears any permission error message
    func clearPermissionError() {
        permissionErrorMessage = nil
    }
}

// MARK: - UserDefaults Helper Extension

extension UserDefaults {
    /// Checks if the intro flow has been completed
    var hasCompletedIntro: Bool {
        return bool(forKey: "hasCompletedIntro")
    }
    
    /// Marks the intro flow as completed
    func setIntroCompleted(_ completed: Bool = true) {
        set(completed, forKey: "hasCompletedIntro")
        synchronize()
    }
}
