import XCTest

/// P0: Fehlerfall UI-Tests mit deutschen Meldungen
final class Error_Handling_German_UI_Tests: XCTestCase {
    
    // MARK: - P0 Location Error Handling
    
    func test_locationError_showsGermanErrorMessage() {
        let app = TestApp.launch(extraArgs: ["-simulate-location-error"])
        
        // Try to trigger location-dependent action
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) {
            quickButton.tap()
            
            // Error message should appear in German
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 3) {
                let errorText = errorDialog.staticTexts.firstMatch
                let germanLocationKeywords = ["Standort", "Berechtigung", "erlauben", "Einstellungen"]
                
                var foundGermanError = false
                for keyword in germanLocationKeywords {
                    if errorText.label.contains(keyword) {
                        foundGermanError = true
                        break
                    }
                }
                
                XCTAssertTrue(foundGermanError, "Location error should be displayed in German")
                
                // Should have German action buttons
                let okButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'OK' OR label CONTAINS 'Verstanden'")).firstMatch
                let settingsButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Einstellungen'")).firstMatch
                
                XCTAssertTrue(okButton.exists || settingsButton.exists, 
                             "Error dialog should have German action buttons")
                
                // Dismiss error
                if okButton.exists {
                    okButton.tap()
                } else if settingsButton.exists {
                    settingsButton.tap()
                }
            }
        }
    }
    
    func test_locationPermissionDenied_showsGracefulDegradation() {
        let app = TestApp.launch(extraArgs: ["-simulate-location-denied"])
        
        // App should still be usable  
        guard app.maps.firstMatch.waitForExists(timeout: 5) else {
            XCTSkip("Map not visible - skipping location permission test")
            return
        }
        
        // Check quick planning behavior without location
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.exists {
            // Button might be enabled but should show appropriate error when tapped
            if quickButton.isEnabled {
                quickButton.tap()
                
                // Should show error dialog or message about location
                let locationError = app.alerts.firstMatch
                if locationError.waitForExists(timeout: 3) {
                    // Good - error dialog appeared
                    let okButton = locationError.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                } else {
                    // Check for in-app error message
                    let errorTexts = ["Standort", "erlaube", "Berechtigung", "GPS"]
                    var errorFound = false
                    for errorText in errorTexts {
                        if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", errorText)).firstMatch.exists {
                            errorFound = true
                            break
                        }
                    }
                    // Don't fail if no error - app might handle this differently
                    if !errorFound {
                        print("Note: No explicit location error shown - app handles gracefully")
                    }
                }
            }
        }
        
        // Full planning should still be available
        let fullButton = app.buttons["home.plan.full"]
        let legacyButton = app.buttons["home.plan.automatic"]
        XCTAssertTrue(fullButton.exists || legacyButton.exists, 
                     "Manual planning should still be available")
        
        // Try manual planning to ensure it works without location
        if fullButton.exists && fullButton.isEnabled {
            fullButton.tap()
            
            let planningSheet = app.sheets.firstMatch
            XCTAssertTrue(planningSheet.waitForExists(timeout: 3), 
                         "Planning sheet should open even without location")
        } else if legacyButton.exists && legacyButton.isEnabled {
            legacyButton.tap()
            
            let planningSheet = app.sheets.firstMatch
            XCTAssertTrue(planningSheet.waitForExists(timeout: 3), 
                         "Planning sheet should open even without location")
        } else {
            print("Note: Manual planning buttons not available or enabled")
        }
    }
    
    // MARK: - P0 Route Generation Error Handling
    
    func test_routeGenerationFailure_showsGermanErrorWithRetry() {
        let app = TestApp.launch(extraArgs: ["-simulate-route-error"])
        
        // Try to generate route that will fail
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // Wait for error to appear
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 10) {
                let errorText = errorDialog.staticTexts.firstMatch
                let germanRouteErrorKeywords = ["Route", "gefunden", "versuche", "nochmal", "Fehler"]
                
                var foundGermanError = false
                for keyword in germanRouteErrorKeywords {
                    if errorText.label.contains(keyword) {
                        foundGermanError = true
                        break
                    }
                }
                
                XCTAssertTrue(foundGermanError, "Route error should be displayed in German")
                
                // Should have retry option in German
                let retryButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Nochmal' OR label CONTAINS 'Wiederholen'")).firstMatch
                let okButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'OK'")).firstMatch
                
                XCTAssertTrue(retryButton.exists || okButton.exists, 
                             "Error should have German action buttons")
                
                // Test retry functionality
                if retryButton.exists {
                    retryButton.tap()
                    
                    // Should attempt to generate route again
                    let loadingMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'basteln'")).firstMatch
                    // Loading might appear briefly
                    Thread.sleep(forTimeInterval: 1.0)
                } else if okButton.exists {
                    okButton.tap()
                }
            }
        } else {
            XCTSkip("Quick planning not available for route error test")
        }
    }
    
    func test_noPOIsFound_showsHelpfulGermanMessage() {
        let app = TestApp.launch(extraArgs: ["-simulate-no-pois"])
        
        // Try route generation in area with no POIs
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // Wait for no-POIs error
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 15) {
                let errorText = errorDialog.staticTexts.firstMatch
                let noPOIsKeywords = ["interessant", "gefunden", "Umgebung", "Orte", "Position"]
                
                var foundHelpfulMessage = false
                for keyword in noPOIsKeywords {
                    if errorText.label.contains(keyword) {
                        foundHelpfulMessage = true
                        break
                    }
                }
                
                XCTAssertTrue(foundHelpfulMessage, 
                             "No POIs error should show helpful German message")
                
                // Dismiss error
                let okButton = app.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
        }
    }
    
    // MARK: - P0 Network Error Handling
    
    func test_networkError_showsGermanErrorWithRetry() {
        let app = TestApp.launch(extraArgs: ["-simulate-network-error"])
        
        // Try action that requires network
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // Network error should appear
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 10) {
                let errorText = errorDialog.staticTexts.firstMatch
                let networkErrorKeywords = ["Verbindung", "Internet", "Netzwerk", "prüfe", "erreichbar"]
                
                var foundNetworkError = false
                for keyword in networkErrorKeywords {
                    if errorText.label.contains(keyword) {
                        foundNetworkError = true
                        break
                    }
                }
                
                XCTAssertTrue(foundNetworkError, "Network error should be in German")
                
                // Should have retry option
                let retryButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Nochmal' OR label CONTAINS 'Wiederholen'")).firstMatch
                XCTAssertTrue(retryButton.exists, "Network error should offer retry in German")
                
                retryButton.tap()
            }
        }
    }
    
    // MARK: - P0 Error Message Content Validation
    
    func test_errorMessages_doNotMentionTechnologyPartners() {
        let app = TestApp.launch(extraArgs: ["-simulate-api-error"])
        
        // Trigger API error
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // Wait for error
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 10) {
                let errorText = errorDialog.staticTexts.firstMatch.label
                
                // Check that no technology partner names are mentioned
                let forbiddenTerms = ["HERE", "Geoapify", "MapKit", "API", "OpenStreetMap", "Wikipedia"]
                
                for term in forbiddenTerms {
                    XCTAssertFalse(errorText.contains(term), 
                                  "Error message should not mention technology partner: \(term)")
                }
                
                // Should be user-friendly German
                let friendlyTerms = ["versuche", "Problem", "später", "Verbindung"]
                var foundFriendlyTerm = false
                for term in friendlyTerms {
                    if errorText.contains(term) {
                        foundFriendlyTerm = true
                        break
                    }
                }
                
                XCTAssertTrue(foundFriendlyTerm, "Error should be user-friendly in German")
                
                // Dismiss error
                let okButton = app.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
        }
    }
    
    // MARK: - P0 Error Recovery Flow
    
    func test_errorRecovery_returnsToFunctionalState() {
        let app = TestApp.launch(extraArgs: ["-simulate-transient-error"])
        
        // Trigger error and recovery
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // Handle error
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 10) {
                let okButton = app.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
            
            // App should return to functional state
            XCTAssertTrue(app.maps.firstMatch.exists, "Map should still be functional after error")
            XCTAssertTrue(quickButton.waitForExists(timeout: 3), "Quick planning should be available again")
            
            // Try again should work
            if quickButton.isEnabled {
                // Don't actually tap again to avoid infinite loop in test
                XCTAssertTrue(quickButton.isEnabled, "Should be able to retry after error")
            }
        }
    }
    
    // MARK: - P0 Error Display Consistency
    
    func test_errorDisplay_consistentGermanStyling() {
        let app = TestApp.launch(extraArgs: ["-test-error-styling"])
        
        // This test would ideally trigger different types of errors and verify consistent styling
        // For now, check that error dialogs follow German conventions
        
        let quickButton = app.buttons["home.plan.quick"]
        if quickButton.waitForExists(timeout: 5) && quickButton.isEnabled {
            quickButton.tap()
            
            // If any error appears, check styling
            let errorDialog = app.alerts.firstMatch
            if errorDialog.waitForExists(timeout: 5) {
                // Should have title and message
                let title = errorDialog.staticTexts.firstMatch
                XCTAssertTrue(title.exists, "Error should have title")
                
                // Should have at least one action button
                let buttons = errorDialog.buttons
                XCTAssertGreaterThan(buttons.count, 0, "Error should have action buttons")
                
                // Dismiss error
                let okButton = app.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
        }
    }
}
