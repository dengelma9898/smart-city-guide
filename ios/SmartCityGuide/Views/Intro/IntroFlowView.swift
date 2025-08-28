//
//  IntroFlowView.swift
//  SmartCityGuide
//
//  Created on 2025-08-26
//  Main container view for the intro onboarding flow
//

import SwiftUI

struct IntroFlowView: View {
    @StateObject private var viewModel = IntroFlowViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// Callback when intro flow is completed
    let onIntroCompleted: () -> Void
    
    var body: some View {
        NavigationStack {
            // Clean iOS design without background image
            introStepContent
                .background(Color(.systemBackground))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .alert("Intro überspringen?", isPresented: $viewModel.showSkipConfirmation) {
            Button("Abbrechen", role: .cancel) {
                viewModel.cancelSkip()
            }
            Button("Überspringen") {
                viewModel.confirmSkip()
                handleIntroCompletion()
            }
        } message: {
            Text("Du kannst fehlende Berechtigungen später in den Profileinstellungen aktivieren.")
        }
        .alert("Hinweis", isPresented: .constant(viewModel.permissionErrorMessage != nil)) {
            Button("OK") {
                viewModel.clearPermissionError()
            }
        } message: {
            if let errorMessage = viewModel.permissionErrorMessage {
                Text(errorMessage)
            }
        }

    }
    
    @ViewBuilder
    private var introStepContent: some View {
                            // Animated step transitions
                    Group {
                                            switch viewModel.currentStep {
                    case .welcome:
                        WelcomeIntroView(viewModel: viewModel)
                    case .locationWhenInUse:
                        LocationWhenInUseIntroView(viewModel: viewModel)
                    case .poiNotifications:
                        POINotificationIntroView(viewModel: viewModel)
                    case .completion:
                        CompletionIntroView(viewModel: viewModel, onComplete: {
                            viewModel.completeIntro()
                            onIntroCompleted()
                        })
                    }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)
    }
    
    private func handleIntroCompletion() {
        viewModel.completeIntro()
        onIntroCompleted()
    }
}

// MARK: - IntroBackgroundView

struct IntroBackgroundView: View {
    var body: some View {
        ZStack {
            // Background image with blur and dark overlay
            Image("intro_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 3)
            
            // Dark overlay for text readability
            Color.black.opacity(0.6)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shared Intro Components

struct IntroStepContainer<Content: View>: View {
    let step: IntroStep
    let viewModel: IntroFlowViewModel
    let content: Content
    
    init(step: IntroStep, viewModel: IntroFlowViewModel, @ViewBuilder content: () -> Content) {
        self.step = step
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing for status bar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(0, geometry.safeAreaInsets.top))
                    
                    // Main content with proper iOS spacing
                    VStack(spacing: 40) {
                        // Icon with proper sizing and subtle animation
                        Image(systemName: step.iconName)
                            .font(.system(size: 64, weight: .regular))
                            .foregroundColor(step.iconColor)
                            .frame(height: 80)
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: step)
                        
                        // Title and description with proper typography
                        VStack(spacing: 16) {
                            Text(step.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(step.description)
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                        
                        // Custom content
                        content
                            .padding(.horizontal, 32)
                        
                        // Buttons as part of scrollable content
                        VStack(spacing: 20) {
                            // Main action button for current step
                            if step != .completion {
                                IntroActionButton(step.buttonText, isLoading: viewModel.isPermissionInProgress) {
                                    handleStepAction(step: step, viewModel: viewModel)
                                }
                            }
                            
                            // Skip button (if applicable)
                            if step.canSkip {
                                Button("Überspringen") {
                                    viewModel.showSkipDialog()
                                }
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
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
    
    private func handleStepAction(step: IntroStep, viewModel: IntroFlowViewModel) {
        switch step {
        case .welcome:
            viewModel.moveToNextStep()
        case .locationWhenInUse:
            Task {
                await viewModel.requestLocationWhenInUsePermission()
            }
        case .poiNotifications:
            Task {
                await viewModel.requestPOINotificationPermissions()
            }
        case .completion:
            // This should not be reached now
            break
        }
    }
}



struct IntroActionButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
            .disabled(isLoading)
        }
        .opacity(isLoading ? 0.8 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    IntroFlowView {
        print("Intro completed")
    }
}
