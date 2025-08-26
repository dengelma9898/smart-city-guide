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
            ZStack {
                // Background with intro image
                IntroBackgroundView()
                
                // Content based on current step
                introStepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
            .ignoresSafeArea(.all, edges: .top)
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
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == .completion {
                // Small delay to show completion screen before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    handleIntroCompletion()
                }
            }
        }
    }
    
    @ViewBuilder
    private var introStepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeIntroView(viewModel: viewModel)
        case .locationWhenInUse:
            LocationWhenInUseIntroView(viewModel: viewModel)
        case .locationAlways:
            LocationAlwaysIntroView(viewModel: viewModel)
        case .notificationPermission:
            NotificationPermissionIntroView(viewModel: viewModel)
        case .completion:
            CompletionIntroView(viewModel: viewModel)
        }
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
        VStack(spacing: 0) {
            // Top spacer
            Spacer()
            
            // Main content area
            VStack(spacing: 32) {
                // Icon
                Image(systemName: step.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(step.iconColor)
                
                // Title and description
                VStack(spacing: 16) {
                    Text(step.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Custom content
                content
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bottom action area
            VStack(spacing: 16) {
                // Skip button (if applicable)
                if step.canSkip {
                    Button("Überspringen") {
                        viewModel.showSkipDialog()
                    }
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 50)
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(25)
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
        .opacity(isLoading ? 0.8 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    IntroFlowView {
        print("Intro completed")
    }
}
