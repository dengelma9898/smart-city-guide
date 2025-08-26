//
//  AppLaunchFlowTests.swift
//  SmartCityGuideTests
//
//  Created on 2025-08-26
//  Unit tests for app launch logic with intro vs direct main app flow
//

import XCTest
import SwiftUI
@testable import SmartCityGuide

@MainActor
class AppLaunchFlowTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use separate UserDefaults suite for testing
        userDefaults = UserDefaults(suiteName: "AppLaunchFlowTests")!
        userDefaults.removePersistentDomain(forName: "AppLaunchFlowTests")
        userDefaults.synchronize()
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "AppLaunchFlowTests")
        userDefaults.synchronize()
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - App Launch Decision Tests
    
    func testFirstLaunchShouldShowIntro() {
        // Given - fresh app install (no intro completed)
        XCTAssertFalse(userDefaults.hasCompletedIntro, "Fresh install should not have completed intro")
        
        // When - check launch decision
        let shouldShowIntro = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        
        // Then - should show intro
        XCTAssertTrue(shouldShowIntro, "First launch should show intro flow")
    }
    
    func testSubsequentLaunchShouldSkipIntro() {
        // Given - intro already completed
        userDefaults.setIntroCompleted(true)
        XCTAssertTrue(userDefaults.hasCompletedIntro, "Intro should be marked as completed")
        
        // When - check launch decision
        let shouldShowIntro = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        
        // Then - should skip intro
        XCTAssertFalse(shouldShowIntro, "Subsequent launches should skip intro flow")
    }
    
    func testAppLaunchDecisionConsistency() {
        // Test multiple calls return consistent results
        
        // First launch scenario
        let firstCheck = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        let secondCheck = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        XCTAssertEqual(firstCheck, secondCheck, "Multiple checks should be consistent")
        
        // Complete intro
        userDefaults.setIntroCompleted(true)
        
        // Subsequent launch scenario
        let thirdCheck = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        let fourthCheck = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        XCTAssertEqual(thirdCheck, fourthCheck, "Multiple checks should be consistent after completion")
        XCTAssertNotEqual(firstCheck, thirdCheck, "Result should change after intro completion")
    }
    
    // MARK: - Main App Coordinator Tests
    
    func testMainAppCoordinatorInitialization() {
        // Given - Main app coordinator
        let coordinator = MainAppCoordinator(userDefaults: userDefaults)
        
        // Then - should initialize correctly
        XCTAssertNotNil(coordinator, "Main app coordinator should initialize")
        XCTAssertEqual(coordinator.isFirstLaunch, !userDefaults.hasCompletedIntro)
    }
    
    func testMainAppCoordinatorIntroCompletion() {
        // Given - Main app coordinator on first launch
        let coordinator = MainAppCoordinator(userDefaults: userDefaults)
        XCTAssertTrue(coordinator.isFirstLaunch, "Should be first launch initially")
        
        // When - complete intro
        coordinator.onIntroCompleted()
        
        // Then - should update state
        XCTAssertFalse(coordinator.isFirstLaunch, "Should no longer be first launch")
        XCTAssertTrue(userDefaults.hasCompletedIntro, "Should mark intro as completed")
    }
    
    // MARK: - App State Management Tests
    
    func testAppStateTransition() {
        // Given - App state manager
        let stateManager = AppStateManager(userDefaults: userDefaults)
        
        // Initially should be intro
        XCTAssertEqual(stateManager.currentState, .intro, "Initial state should be intro")
        
        // When - complete intro
        stateManager.completeIntro()
        
        // Then - should transition to main app
        XCTAssertEqual(stateManager.currentState, .mainApp, "Should transition to main app")
    }
    
    func testAppStateManagerPersistence() {
        // Given - App state manager that completes intro
        let stateManager1 = AppStateManager(userDefaults: userDefaults)
        stateManager1.completeIntro()
        
        // When - create new instance (simulating app restart)
        let stateManager2 = AppStateManager(userDefaults: userDefaults)
        
        // Then - should remember completed state
        XCTAssertEqual(stateManager2.currentState, .mainApp, "Should remember completed intro state")
    }
    
    // MARK: - Integration Tests
    
    func testFullAppLaunchFlow() {
        // Test complete flow from fresh install to intro completion
        
        // Step 1: Fresh install
        let initialDecision = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        XCTAssertTrue(initialDecision, "Fresh install should show intro")
        
        // Step 2: User goes through intro
        let introViewModel = IntroFlowViewModel(userDefaults: userDefaults)
        XCTAssertTrue(introViewModel.isFirstLaunch, "Should be first launch")
        
        // Step 3: Complete intro
        introViewModel.completeIntro()
        
        // Step 4: Check app launch decision after completion
        let postIntroDecision = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        XCTAssertFalse(postIntroDecision, "Should not show intro after completion")
        
        // Step 5: Verify persistence across app "restarts"
        let newViewModel = IntroFlowViewModel(userDefaults: userDefaults)
        XCTAssertFalse(newViewModel.isFirstLaunch, "Should not be first launch anymore")
    }
    
    func testSkipIntroFlow() {
        // Test flow when user skips intro
        
        // Given - User at intro
        let introViewModel = IntroFlowViewModel(userDefaults: userDefaults)
        introViewModel.currentStep = .locationWhenInUse
        
        // When - User skips
        introViewModel.confirmSkip()
        
        // Then - Should mark intro as completed
        XCTAssertTrue(userDefaults.hasCompletedIntro, "Skip should mark intro as completed")
        XCTAssertEqual(introViewModel.currentStep, .completion, "Skip should go to completion")
        
        // And subsequent launches should skip intro
        let postSkipDecision = AppLaunchDecision.shouldShowIntroFlow(userDefaults: userDefaults)
        XCTAssertFalse(postSkipDecision, "Should not show intro after skip")
    }
}

// MARK: - Mock App Launch Components for Testing

enum AppState {
    case intro
    case mainApp
}

class AppLaunchDecision {
    static func shouldShowIntroFlow(userDefaults: UserDefaults) -> Bool {
        return !userDefaults.hasCompletedIntro
    }
}

class MainAppCoordinator: ObservableObject {
    @Published var isFirstLaunch: Bool
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.isFirstLaunch = !userDefaults.hasCompletedIntro
    }
    
    func onIntroCompleted() {
        userDefaults.setIntroCompleted(true)
        isFirstLaunch = false
    }
}

class AppStateManager: ObservableObject {
    @Published var currentState: AppState
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.currentState = userDefaults.hasCompletedIntro ? .mainApp : .intro
    }
    
    func completeIntro() {
        userDefaults.setIntroCompleted(true)
        currentState = .mainApp
    }
}
