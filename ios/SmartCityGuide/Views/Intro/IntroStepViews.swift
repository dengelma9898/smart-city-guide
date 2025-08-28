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
            // Feature highlights with better spacing and staggered animations
            VStack(spacing: 20) {
                FeatureHighlight(
                    icon: "map.fill", 
                    text: "Intelligente Routen zwischen Sehenswürdigkeiten"
                )
                .opacity(1.0)
                .animation(.easeInOut(duration: 0.6).delay(0.1), value: viewModel.currentStep)
                
                FeatureHighlight(
                    icon: "sparkles", 
                    text: "TSP-optimierte Walking-Touren"
                )
                .opacity(1.0)
                .animation(.easeInOut(duration: 0.6).delay(0.2), value: viewModel.currentStep)
                
                FeatureHighlight(
                    icon: "bell.fill", 
                    text: "Benachrichtigungen bei interessanten Spots"
                )
                .opacity(1.0)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: viewModel.currentStep)
            }
        }
    }
}

/// Location When In Use Permission View - Explanation for basic location access
struct LocationWhenInUseIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .locationWhenInUse, viewModel: viewModel) {
            // Permission benefits with better spacing
            VStack(spacing: 20) {
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
        }
    }
}

/// POI Notification Permission View - Combined location always + notifications
struct POINotificationIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .poiNotifications, viewModel: viewModel) {
            VStack(spacing: 24) {
                // Combined permission benefits
                VStack(spacing: 16) {
                    PermissionBenefit(
                        icon: "bell.badge.circle", 
                        title: "Smart POI-Benachrichtigungen",
                        description: "Werde informiert wenn du interessante Spots auf deiner Route erreichst"
                    )
                    PermissionBenefit(
                        icon: "location.fill.viewfinder", 
                        title: "Hintergrund-Erkennung",
                        description: "Spots werden automatisch erkannt, auch wenn die App im Hintergrund läuft"
                    )
                    PermissionBenefit(
                        icon: "info.circle.fill", 
                        title: "Relevante Informationen",
                        description: "Erhalte spannende Details und Fakten zu Sehenswürdigkeiten"
                    )
                    PermissionBenefit(
                        icon: "battery.75", 
                        title: "Energieeffizient",
                        description: "Intelligente Standorterkennung schont deinen Akku"
                    )
                }
                .padding(.horizontal, 8)
                
                // Privacy and control note
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.secondary)
                        Text("Deine Daten bleiben privat und werden nicht geteilt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "gear.circle")
                            .foregroundColor(.secondary)
                        Text("Vollständig anpassbar in den Profileinstellungen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Completion View - Success message and app transition
struct CompletionIntroView: View {
    let viewModel: IntroFlowViewModel
    let onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing for status bar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(0, geometry.safeAreaInsets.top))
                    
                    // Main content
                    VStack(spacing: 40) {
                        // Icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64, weight: .regular))
                            .foregroundColor(.green)
                            .frame(height: 80)
                        
                        // Title and description
                        VStack(spacing: 16) {
                            Text("Alles bereit!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Perfekt! Du bist bereit für deine erste intelligente Stadt-Route. Los geht's mit der Entdeckung!")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                        
                        // Features preview
                        VStack(spacing: 20) {
                            FeatureHighlight(
                                icon: "map.fill", 
                                text: "Optimierte Routen zwischen Sehenswürdigkeiten"
                            )
                            FeatureHighlight(
                                icon: "location.circle", 
                                text: "GPS-Navigation zu interessanten Spots"
                            )
                            FeatureHighlight(
                                icon: "bell.badge", 
                                text: "Smart Benachrichtigungen unterwegs"
                            )
                        }
                        .padding(.horizontal, 32)
                        
                        // Manual button for completion
                        VStack(spacing: 20) {
                            Button(action: onComplete) {
                                HStack {
                                    Text("Zur App")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, max(34, geometry.safeAreaInsets.bottom + 16))
                }
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Helper Components

struct FeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PermissionBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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

#Preview("POI Notifications") {
    ZStack {
        IntroBackgroundView()
        POINotificationIntroView(viewModel: IntroFlowViewModel())
    }
}

#Preview("Completion") {
    CompletionIntroView(viewModel: IntroFlowViewModel(), onComplete: {
        print("Completion preview")
    })
}
