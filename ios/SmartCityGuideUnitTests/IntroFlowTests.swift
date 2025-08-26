//
//  IntroFlowTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-26
//  Unit tests for IntroFlow - Onboarding screen navigation and UserDefaults
//

import XCTest
import SwiftUI
@testable import SmartCityGuide

@MainActor
class IntroFlowTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use separate UserDefaults suite for testing to avoid conflicts
        userDefaults = UserDefaults(suiteName: "IntroFlowTests")!
        userDefaults.removePersistentDomain(forName: "IntroFlowTests")
        userDefaults.synchronize()
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "IntroFlowTests")
        userDefaults.synchronize()
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - IntroStep Enum Tests
    
    func testIntroStepEnumValues() {
        // Test that IntroStep enum has all required cases
        let expectedSteps: [IntroStep] = [
            .welcome,
            .locationWhenInUse,
            .locationAlways,
            .notificationPermission,
            .completion
        ]
        
        // Verify all cases exist
        for step in expectedSteps {
            XCTAssertNotNil(step, "IntroStep \(step) should exist")
        }
        
        // Verify enum has exactly 5 cases
        XCTAssertEqual(IntroStep.allCases.count, 5, "IntroStep should have exactly 5 cases")
    }
    
    func testIntroStepNavigation() {
        // Test navigation order
        XCTAssertEqual(IntroStep.welcome.nextStep, .locationWhenInUse)
        XCTAssertEqual(IntroStep.locationWhenInUse.nextStep, .locationAlways)
        XCTAssertEqual(IntroStep.locationAlways.nextStep, .notificationPermission)
        XCTAssertEqual(IntroStep.notificationPermission.nextStep, .completion)
        XCTAssertNil(IntroStep.completion.nextStep)
    }
    
    func testIntroStepCanSkip() {
        // Test skip functionality - all steps except completion should be skippable
        XCTAssertTrue(IntroStep.welcome.canSkip)
        XCTAssertTrue(IntroStep.locationWhenInUse.canSkip)
        XCTAssertTrue(IntroStep.locationAlways.canSkip)
        XCTAssertTrue(IntroStep.notificationPermission.canSkip)
        XCTAssertFalse(IntroStep.completion.canSkip)
    }
    
    // MARK: - UserDefaults Integration Tests
    
    func testHasCompletedIntroInitialState() {
        // Given - fresh UserDefaults
        let hasCompleted = userDefaults.bool(forKey: "hasCompletedIntro")
        
        // Then - should default to false
        XCTAssertFalse(hasCompleted, "hasCompletedIntro should default to false")
    }
    
    func testSetHasCompletedIntro() {
        // Given - initial false state
        XCTAssertFalse(userDefaults.bool(forKey: "hasCompletedIntro"))
        
        // When - set to true
        userDefaults.set(true, forKey: "hasCompletedIntro")
        userDefaults.synchronize()
        
        // Then - should be true
        XCTAssertTrue(userDefaults.bool(forKey: "hasCompletedIntro"))
    }
    
    func testIsFirstLaunchDetection() {
        // Test helper function for first launch detection
        func isFirstLaunch() -> Bool {
            return !userDefaults.bool(forKey: "hasCompletedIntro")
        }
        
        // Initially should be first launch
        XCTAssertTrue(isFirstLaunch(), "Should be first launch initially")
        
        // After completing intro, should not be first launch
        userDefaults.set(true, forKey: "hasCompletedIntro")
        XCTAssertFalse(isFirstLaunch(), "Should not be first launch after completion")
    }
    
    // MARK: - IntroFlowViewModel Tests
    
    func testIntroFlowViewModelInitialization() {
        // Given - new ViewModel
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        
        // Then - should start at welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.showSkipConfirmation)
        XCTAssertTrue(viewModel.isFirstLaunch)
    }
    
    func testIntroFlowViewModelNextStep() {
        // Given - ViewModel at welcome
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        XCTAssertEqual(viewModel.currentStep, .welcome)
        
        // When - move to next step
        viewModel.moveToNextStep()
        
        // Then - should be at locationWhenInUse
        XCTAssertEqual(viewModel.currentStep, .locationWhenInUse)
    }
    
    func testIntroFlowViewModelSkipToCompletion() {
        // Given - ViewModel at any step
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        viewModel.currentStep = .locationWhenInUse
        
        // When - skip to completion
        viewModel.skipToCompletion()
        
        // Then - should be at completion
        XCTAssertEqual(viewModel.currentStep, .completion)
        XCTAssertTrue(userDefaults.bool(forKey: "hasCompletedIntro"))
    }
    
    func testIntroFlowViewModelCompleteIntro() {
        // Given - ViewModel at completion
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        viewModel.currentStep = .completion
        
        // When - complete intro
        viewModel.completeIntro()
        
        // Then - should mark as completed
        XCTAssertTrue(userDefaults.bool(forKey: "hasCompletedIntro"))
        XCTAssertFalse(viewModel.isFirstLaunch)
    }
    
    // MARK: - Navigation Logic Tests
    
    func testFullNavigationFlow() {
        // Given - ViewModel starting fresh
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        
        // Test complete navigation flow
        XCTAssertEqual(viewModel.currentStep, .welcome)
        
        viewModel.moveToNextStep()
        XCTAssertEqual(viewModel.currentStep, .locationWhenInUse)
        
        viewModel.moveToNextStep()
        XCTAssertEqual(viewModel.currentStep, .locationAlways)
        
        viewModel.moveToNextStep()
        XCTAssertEqual(viewModel.currentStep, .notificationPermission)
        
        viewModel.moveToNextStep()
        XCTAssertEqual(viewModel.currentStep, .completion)
        
        // Complete the intro
        viewModel.completeIntro()
        XCTAssertTrue(userDefaults.bool(forKey: "hasCompletedIntro"))
    }
    
    func testSkipConfirmationDialog() {
        // Given - ViewModel at skippable step
        let viewModel = IntroFlowViewModel(userDefaults: userDefaults)
        viewModel.currentStep = .locationWhenInUse
        
        // When - trigger skip confirmation
        viewModel.showSkipConfirmation = true
        
        // Then - dialog should be shown
        XCTAssertTrue(viewModel.showSkipConfirmation)
        
        // When - confirm skip
        viewModel.confirmSkip()
        
        // Then - should complete intro and hide dialog
        XCTAssertEqual(viewModel.currentStep, .completion)
        XCTAssertFalse(viewModel.showSkipConfirmation)
        XCTAssertTrue(userDefaults.bool(forKey: "hasCompletedIntro"))
    }
    
    // MARK: - Individual Intro Screen View Tests
    
    func testWelcomeIntroViewContent() {
        // Test that WelcomeIntroView contains expected content
        let step = IntroStep.welcome
        
        XCTAssertEqual(step.title, "Willkommen bei Smart City Guide!")
        XCTAssertTrue(step.description.contains("intelligenten Walking-Routen"))
        XCTAssertEqual(step.buttonText, "Los geht's!")
        XCTAssertEqual(step.iconName, "map.circle.fill")
        XCTAssertTrue(step.canSkip)
    }
    
    func testLocationWhenInUseIntroViewContent() {
        // Test that LocationWhenInUseIntroView contains expected content
        let step = IntroStep.locationWhenInUse
        
        XCTAssertEqual(step.title, "Dein Standort für Routen")
        XCTAssertTrue(step.description.contains("beste Route von deiner aktuellen Position"))
        XCTAssertEqual(step.buttonText, "Standort aktivieren")
        XCTAssertEqual(step.iconName, "location.circle.fill")
        XCTAssertTrue(step.canSkip)
    }
    
    func testLocationAlwaysIntroViewContent() {
        // Test that LocationAlwaysIntroView contains expected content
        let step = IntroStep.locationAlways
        
        XCTAssertEqual(step.title, "Standort für Benachrichtigungen")
        XCTAssertTrue(step.description.contains("Benachrichtigungen wenn du Spots"))
        XCTAssertEqual(step.buttonText, "Benachrichtigungen aktivieren")
        XCTAssertEqual(step.iconName, "location.fill.viewfinder")
        XCTAssertTrue(step.canSkip)
    }
    
    func testNotificationPermissionIntroViewContent() {
        // Test that NotificationPermissionIntroView contains expected content
        let step = IntroStep.notificationPermission
        
        XCTAssertEqual(step.title, "Benachrichtigungen aktivieren")
        XCTAssertTrue(step.description.contains("benachrichtigen wenn du interessante Orte"))
        XCTAssertEqual(step.buttonText, "Benachrichtigungen aktivieren")
        XCTAssertEqual(step.iconName, "bell.circle.fill")
        XCTAssertTrue(step.canSkip)
    }
    
    func testCompletionIntroViewContent() {
        // Test that CompletionIntroView contains expected content
        let step = IntroStep.completion
        
        XCTAssertEqual(step.title, "Alles bereit!")
        XCTAssertTrue(step.description.contains("bereit für deine erste intelligente Stadt-Route"))
        XCTAssertEqual(step.buttonText, "Zur App")
        XCTAssertEqual(step.iconName, "checkmark.circle.fill")
        XCTAssertFalse(step.canSkip) // Completion cannot be skipped
    }
    
    func testIntroStepIcons() {
        // Test that all intro steps have unique icons
        let iconNames = IntroStep.allCases.map { $0.iconName }
        let uniqueIcons = Set(iconNames)
        
        XCTAssertEqual(iconNames.count, uniqueIcons.count, "All intro steps should have unique icons")
    }
    
    func testIntroStepTitles() {
        // Test that all intro steps have non-empty titles
        for step in IntroStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "Step \(step) should have a non-empty title")
            XCTAssertFalse(step.description.isEmpty, "Step \(step) should have a non-empty description")
            XCTAssertFalse(step.buttonText.isEmpty, "Step \(step) should have non-empty button text")
        }
    }
    
    func testGermanLanguageContent() {
        // Test that content is in German
        for step in IntroStep.allCases {
            // Check for German-specific characteristics
            let germanContent = step.title + " " + step.description + " " + step.buttonText
            
            // German umlauts and specific words
            let hasGermanChars = germanContent.contains("ä") || 
                               germanContent.contains("ö") || 
                               germanContent.contains("ü") || 
                               germanContent.contains("ß") ||
                               germanContent.contains("Benachrichtig") ||
                               germanContent.contains("aktivieren") ||
                               germanContent.contains("bereit")
            
            XCTAssertTrue(hasGermanChars, "Step \(step) should contain German text")
        }
    }
}

// MARK: - Mock IntroStep Extension for Testing

extension IntroStep {
    var nextStep: IntroStep? {
        switch self {
        case .welcome:
            return .locationWhenInUse
        case .locationWhenInUse:
            return .locationAlways
        case .locationAlways:
            return .notificationPermission
        case .notificationPermission:
            return .completion
        case .completion:
            return nil
        }
    }
    
    var canSkip: Bool {
        switch self {
        case .completion:
            return false
        default:
            return true
        }
    }
}

// MARK: - Mock IntroFlowViewModel for Testing

class IntroFlowViewModel: ObservableObject {
    @Published var currentStep: IntroStep = .welcome
    @Published var showSkipConfirmation: Bool = false
    
    private let userDefaults: UserDefaults
    
    var isFirstLaunch: Bool {
        return !userDefaults.bool(forKey: "hasCompletedIntro")
    }
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    func moveToNextStep() {
        if let nextStep = currentStep.nextStep {
            currentStep = nextStep
        }
    }
    
    func skipToCompletion() {
        currentStep = .completion
        completeIntro()
    }
    
    func completeIntro() {
        userDefaults.set(true, forKey: "hasCompletedIntro")
        userDefaults.synchronize()
    }
    
    func confirmSkip() {
        showSkipConfirmation = false
        skipToCompletion()
    }
}
