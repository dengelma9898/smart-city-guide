//
//  IntroStepViews.swift
//  SmartCityGuide
//
//  Created on 2025-08-26
//  Placeholder views for intro steps - to be implemented in Task 2
//

import SwiftUI

// MARK: - Placeholder Views for Task 1 Compilation

/// Placeholder Welcome View - to be fully implemented in Task 2
struct WelcomeIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .welcome, viewModel: viewModel) {
            IntroActionButton(IntroStep.welcome.buttonText) {
                viewModel.moveToNextStep()
            }
        }
    }
}

/// Placeholder Location When In Use View - to be fully implemented in Task 2
struct LocationWhenInUseIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .locationWhenInUse, viewModel: viewModel) {
            IntroActionButton(IntroStep.locationWhenInUse.buttonText) {
                // TODO: Task 3 - Implement actual location permission request
                viewModel.moveToNextStep()
            }
        }
    }
}

/// Placeholder Location Always View - to be fully implemented in Task 2
struct LocationAlwaysIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .locationAlways, viewModel: viewModel) {
            IntroActionButton(IntroStep.locationAlways.buttonText) {
                // TODO: Task 3 - Implement actual always location permission request
                viewModel.moveToNextStep()
            }
        }
    }
}

/// Placeholder Notification Permission View - to be fully implemented in Task 2
struct NotificationPermissionIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .notificationPermission, viewModel: viewModel) {
            IntroActionButton(IntroStep.notificationPermission.buttonText) {
                // TODO: Task 3 - Implement actual notification permission request
                viewModel.moveToNextStep()
            }
        }
    }
}

/// Placeholder Completion View - to be fully implemented in Task 2
struct CompletionIntroView: View {
    let viewModel: IntroFlowViewModel
    
    var body: some View {
        IntroStepContainer(step: .completion, viewModel: viewModel) {
            IntroActionButton(IntroStep.completion.buttonText) {
                // Completion is handled in IntroFlowView
            }
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
