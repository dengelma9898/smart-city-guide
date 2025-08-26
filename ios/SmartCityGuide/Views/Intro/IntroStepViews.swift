//
//  IntroStepViews.swift
//  SmartCityGuide
//
//  Created on 2025-08-26
//  Placeholder views for intro steps - to be implemented in Task 2
//

import SwiftUI

// MARK: - Placeholder Views for Task 1 Compilation

/// Welcome Intro View - App purpose and feature explanation
struct WelcomeIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .welcome, viewModel: viewModel) {
            VStack(spacing: 24) {
                // Feature highlights
                VStack(spacing: 16) {
                    FeatureHighlight(
                        icon: "map.fill", 
                        text: "Intelligente Routen zwischen Sehenswürdigkeiten"
                    )
                    FeatureHighlight(
                        icon: "sparkles", 
                        text: "TSP-optimierte Walking-Touren"
                    )
                    FeatureHighlight(
                        icon: "bell.fill", 
                        text: "Benachrichtigungen bei interessanten Spots"
                    )
                }
                .padding(.horizontal, 8)
                
                // Main action button
                IntroActionButton(IntroStep.welcome.buttonText) {
                    viewModel.moveToNextStep()
                }
            }
        }
    }
}

/// Location When In Use Permission View - Explanation for basic location access
struct LocationWhenInUseIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .locationWhenInUse, viewModel: viewModel) {
            VStack(spacing: 24) {
                // Permission benefits
                VStack(spacing: 16) {
                    PermissionBenefit(
                        icon: "location.north.line", 
                        title: "Optimale Startposition",
                        description: "Routen beginnen von deinem aktuellen Standort"
                    )
                    PermissionBenefit(
                        icon: "figure.walk.circle", 
                        title: "Präzise Navigation",
                        description: "Genaue Distanzen und Gehzeiten berechnen"
                    )
                    PermissionBenefit(
                        icon: "shield.checkered", 
                        title: "Nur während App-Nutzung",
                        description: "Dein Standort wird nur bei aktiver App verwendet"
                    )
                }
                .padding(.horizontal, 8)
                
                // Action button
                IntroActionButton(
                    IntroStep.locationWhenInUse.buttonText,
                    isLoading: viewModel.isPermissionInProgress
                ) {
                    Task {
                        await viewModel.requestLocationWhenInUsePermission()
                    }
                }
            }
        }
    }
}

/// Location Always Permission View - Explanation for background location access
struct LocationAlwaysIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .locationAlways, viewModel: viewModel) {
            VStack(spacing: 24) {
                // Background permission benefits
                VStack(spacing: 16) {
                    PermissionBenefit(
                        icon: "bell.badge.circle", 
                        title: "Smart Benachrichtigungen",
                        description: "Werde informiert wenn du interessante Spots erreichst"
                    )
                    PermissionBenefit(
                        icon: "clock.arrow.2.circlepath", 
                        title: "Automatische Erkennung",
                        description: "Spots werden erkannt auch wenn die App im Hintergrund ist"
                    )
                    PermissionBenefit(
                        icon: "battery.75", 
                        title: "Energieeffizient",
                        description: "Intelligente Standorterkennung schont den Akku"
                    )
                }
                .padding(.horizontal, 8)
                
                // Privacy note
                Text("Deine Daten bleiben privat und werden nicht geteilt")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                // Action button
                IntroActionButton(
                    IntroStep.locationAlways.buttonText,
                    isLoading: viewModel.isPermissionInProgress
                ) {
                    Task {
                        await viewModel.requestLocationAlwaysPermission()
                    }
                }
            }
        }
    }
}

/// Notification Permission View - Explanation for push notifications
struct NotificationPermissionIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .notificationPermission, viewModel: viewModel) {
            VStack(spacing: 24) {
                // Notification benefits
                VStack(spacing: 16) {
                    PermissionBenefit(
                        icon: "bell.badge.waveform", 
                        title: "Nie wieder verpassen",
                        description: "Benachrichtigungen für Sehenswürdigkeiten in deiner Nähe"
                    )
                    PermissionBenefit(
                        icon: "info.circle", 
                        title: "Spannende Details",
                        description: "Erfahre interessante Fakten über deine Umgebung"
                    )
                    PermissionBenefit(
                        icon: "gear.circle", 
                        title: "Vollständig anpassbar",
                        description: "Du bestimmst welche Benachrichtigungen du erhältst"
                    )
                }
                .padding(.horizontal, 8)
                
                // Timing note
                HStack(spacing: 8) {
                    Image(systemName: "clock.circle")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Benachrichtigungen kommen nur wenn relevant")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                
                // Action button
                IntroActionButton(
                    IntroStep.notificationPermission.buttonText,
                    isLoading: viewModel.isPermissionInProgress
                ) {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
            }
        }
    }
}

/// Completion View - Success message and app transition
struct CompletionIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .completion, viewModel: viewModel) {
            VStack(spacing: 32) {
                // Success animation placeholder (could be enhanced later)
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.6).repeatCount(1, autoreverses: false), value: true)
                    
                    Text("Perfekt!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Ready to go message
                VStack(spacing: 12) {
                    Text("Alles ist eingerichtet!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Du bist bereit für deine erste intelligente Stadt-Route. Entdecke die schönsten Orte mit optimierten Walking-Touren!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Next steps hint
                VStack(spacing: 8) {
                    Text("🗺️ Wähle eine Stadt")
                    Text("📍 Lass uns eine Route planen")
                    Text("🚶‍♂️ Starte dein Abenteuer")
                }
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 24)
                
                // Action button
                IntroActionButton(IntroStep.completion.buttonText) {
                    // Completion is handled in IntroFlowView
                }
            }
        }
    }
}

// MARK: - Helper Components

struct FeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct PermissionBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Welcome") {
    ZStack {
        IntroBackgroundView()
        WelcomeIntroView(viewModel: IntroFlowViewModel())
    }
}

#Preview("Location When In Use") {
    ZStack {
        IntroBackgroundView()
        LocationWhenInUseIntroView(viewModel: IntroFlowViewModel())
    }
}

#Preview("Location Always") {
    ZStack {
        IntroBackgroundView()
        LocationAlwaysIntroView(viewModel: IntroFlowViewModel())
    }
}

#Preview("Notification Permission") {
    ZStack {
        IntroBackgroundView()
        NotificationPermissionIntroView(viewModel: IntroFlowViewModel())
    }
}

#Preview("Completion") {
    ZStack {
        IntroBackgroundView()
        CompletionIntroView(viewModel: IntroFlowViewModel())
    }
}
