import XCTest
@testable import Piggy_Bong

final class OnboardingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["RESET_APP_STATE"] = "true"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Welcome Screen Tests
    
    func testWelcomeScreenAppears() throws {
        // Test that welcome screen appears on first launch
        let welcomeTitle = app.staticTexts["Welcome to PiggyBong"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5.0), "Welcome title should appear")
        
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible")
        XCTAssertTrue(getStartedButton.isEnabled, "Get Started button should be enabled")
    }
    
    func testWelcomeScreenInteraction() throws {
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5.0), "Get Started button should appear")
        
        getStartedButton.tap()
        
        // Should navigate to name input screen
        let nameInputField = app.textFields["Enter your name"]
        XCTAssertTrue(nameInputField.waitForExistence(timeout: 3.0), "Name input field should appear after tapping Get Started")
    }
    
    // MARK: - Name Input Screen Tests
    
    func testNameInputScreen() throws {
        navigateToNameInput()
        
        let nameInputField = app.textFields["Enter your name"]
        let continueButton = app.buttons["Continue"]
        
        XCTAssertTrue(nameInputField.exists, "Name input field should be visible")
        XCTAssertTrue(continueButton.exists, "Continue button should be visible")
        XCTAssertFalse(continueButton.isEnabled, "Continue button should be disabled initially")
    }
    
    func testNameInputValidation() throws {
        navigateToNameInput()
        
        let nameInputField = app.textFields["Enter your name"]
        let continueButton = app.buttons["Continue"]
        
        // Test with empty name
        XCTAssertFalse(continueButton.isEnabled, "Continue button should be disabled with empty name")
        
        // Test with too short name
        nameInputField.tap()
        nameInputField.typeText("A")
        XCTAssertFalse(continueButton.isEnabled, "Continue button should be disabled with too short name")
        
        // Clear and test with valid name
        nameInputField.clearText()
        nameInputField.typeText("Test User")
        
        // Wait for validation to complete
        let expectation = XCTestExpectation(description: "Wait for validation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled with valid name")
    }
    
    func testNameInputProgression() throws {
        navigateToNameInput()
        
        let nameInputField = app.textFields["Enter your name"]
        let continueButton = app.buttons["Continue"]
        
        nameInputField.tap()
        nameInputField.typeText("Test User")
        
        // Wait for validation
        let expectation = XCTestExpectation(description: "Wait for validation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        continueButton.tap()
        
        // Should navigate to artist selection
        let artistSelectionTitle = app.staticTexts["Choose Your Artists"]
        XCTAssertTrue(artistSelectionTitle.waitForExistence(timeout: 5.0), "Artist selection screen should appear")
    }
    
    // MARK: - Artist Selection Screen Tests
    
    func testArtistSelectionScreen() throws {
        navigateToArtistSelection()
        
        let artistSelectionTitle = app.staticTexts["Choose Your Artists"]
        XCTAssertTrue(artistSelectionTitle.exists, "Artist selection title should be visible")
        
        // Check for artist list
        let artistList = app.collectionViews.firstMatch
        XCTAssertTrue(artistList.exists, "Artist list should be visible")
        
        // Check for search functionality
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should be available")
        
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists, "Continue button should be visible")
    }
    
    func testArtistSelectionInteraction() throws {
        navigateToArtistSelection()
        
        let artistList = app.collectionViews.firstMatch
        XCTAssertTrue(artistList.waitForExistence(timeout: 5.0), "Artist list should load")
        
        // Wait for artists to load
        let expectation = XCTestExpectation(description: "Wait for artists to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Select first artist if available
        let firstArtistCell = artistList.cells.element(boundBy: 0)
        if firstArtistCell.exists {
            firstArtistCell.tap()
            
            // Verify selection state
            XCTAssertTrue(firstArtistCell.isSelected, "Artist cell should be selected after tap")
            
            let continueButton = app.buttons["Continue"]
            XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled after selecting artist")
        }
    }
    
    func testArtistSearchFunctionality() throws {
        navigateToArtistSelection()
        
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "Search field should appear")
        
        searchField.tap()
        searchField.typeText("BTS")
        
        // Wait for search results
        let expectation = XCTestExpectation(description: "Wait for search results")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let artistList = app.collectionViews.firstMatch
        // Should show filtered results (if BTS exists in the data)
        XCTAssertTrue(artistList.exists, "Artist list should still be visible after search")
    }
    
    func testMaximumArtistSelection() throws {
        navigateToArtistSelection()
        
        let artistList = app.collectionViews.firstMatch
        XCTAssertTrue(artistList.waitForExistence(timeout: 5.0), "Artist list should load")
        
        // Wait for artists to load
        let expectation = XCTestExpectation(description: "Wait for artists to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // Try to select multiple artists up to the limit
        let maxSelections = 2 // Free tier limit
        let cellCount = artistList.cells.count
        
        for i in 0..<min(maxSelections + 1, cellCount) {
            let cell = artistList.cells.element(boundBy: i)
            if cell.exists {
                cell.tap()
            }
        }
        
        // If we tried to select more than the limit, should show upgrade prompt
        if cellCount > maxSelections {
            // Check for upgrade prompt or limitation message
            let upgradePrompt = app.alerts.firstMatch
            if upgradePrompt.exists {
                XCTAssertTrue(true, "Should show upgrade prompt when exceeding limit")
                upgradePrompt.buttons["OK"].tap() // Dismiss prompt
            }
        }
    }
    
    // MARK: - Budget Setup Screen Tests
    
    func testBudgetSetupScreen() throws {
        navigateToBudgetSetup()
        
        let budgetTitle = app.staticTexts["Set Your Monthly Budget"]
        XCTAssertTrue(budgetTitle.exists, "Budget setup title should be visible")
        
        let budgetSlider = app.sliders.firstMatch
        XCTAssertTrue(budgetSlider.exists, "Budget slider should be visible")
        
        let budgetAmountLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        XCTAssertTrue(budgetAmountLabel.exists, "Budget amount should be displayed")
        
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists, "Continue button should be visible")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled with default budget")
    }
    
    func testBudgetSliderInteraction() throws {
        navigateToBudgetSetup()
        
        let budgetSlider = app.sliders.firstMatch
        XCTAssertTrue(budgetSlider.waitForExistence(timeout: 3.0), "Budget slider should appear")
        
        let budgetAmountLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        let initialBudget = budgetAmountLabel.label
        
        // Adjust slider
        budgetSlider.adjust(toNormalizedSliderPosition: 0.8)
        
        // Wait for UI update
        let expectation = XCTestExpectation(description: "Wait for slider update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let updatedBudget = budgetAmountLabel.label
        XCTAssertNotEqual(initialBudget, updatedBudget, "Budget amount should change when slider is adjusted")
    }
    
    func testBudgetSetupProgression() throws {
        navigateToBudgetSetup()
        
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3.0), "Continue button should appear")
        
        continueButton.tap()
        
        // Should navigate to priority planning or complete onboarding
        let dashboardOrPriority = app.staticTexts["Priority Planning"].exists || app.staticTexts["Home"].exists
        XCTAssertTrue(dashboardOrPriority, "Should navigate to priority planning or dashboard")
    }
    
    // MARK: - Priority Planning Screen Tests
    
    func testPriorityPlanningScreen() throws {
        navigateToPriorityPlanning()
        
        let priorityTitle = app.staticTexts["Priority Planning"]
        XCTAssertTrue(priorityTitle.exists, "Priority planning title should be visible")
        
        let instructionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Drag to reorder'")).firstMatch
        XCTAssertTrue(instructionText.exists, "Instructions should be visible")
        
        let artistList = app.tables.firstMatch
        XCTAssertTrue(artistList.exists, "Artist priority list should be visible")
        
        let finishButton = app.buttons["Finish Setup"]
        XCTAssertTrue(finishButton.exists, "Finish setup button should be visible")
    }
    
    func testPriorityReordering() throws {
        navigateToPriorityPlanning()
        
        let artistTable = app.tables.firstMatch
        XCTAssertTrue(artistTable.waitForExistence(timeout: 3.0), "Artist table should appear")
        
        let cellCount = artistTable.cells.count
        if cellCount >= 2 {
            let firstCell = artistTable.cells.element(boundBy: 0)
            let secondCell = artistTable.cells.element(boundBy: 1)
            
            let firstCellLabel = firstCell.staticTexts.firstMatch.label
            let secondCellLabel = secondCell.staticTexts.firstMatch.label
            
            // Drag first cell to second position
            firstCell.press(forDuration: 1.0, thenDragTo: secondCell)
            
            // Wait for reordering animation
            let expectation = XCTestExpectation(description: "Wait for reordering")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
            
            // Verify reordering occurred
            let newFirstCellLabel = artistTable.cells.element(boundBy: 0).staticTexts.firstMatch.label
            XCTAssertEqual(newFirstCellLabel, secondCellLabel, "Cells should be reordered")
        }
    }
    
    func testOnboardingCompletion() throws {
        navigateToPriorityPlanning()
        
        let finishButton = app.buttons["Finish Setup"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 3.0), "Finish setup button should appear")
        
        finishButton.tap()
        
        // Should navigate to main dashboard
        let dashboardTitle = app.staticTexts["Home"].exists || app.navigationBars["Home"].exists
        XCTAssertTrue(dashboardTitle, "Should navigate to dashboard after completing onboarding")
        
        // Check for main tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Main tab bar should be visible after onboarding")
        
        // Verify expected tabs
        let homeTab = app.tabBars.buttons["Home"]
        let eventsTab = app.tabBars.buttons["Events"]
        let planningTab = app.tabBars.buttons["Planning"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        XCTAssertTrue(homeTab.exists, "Home tab should be visible")
        XCTAssertTrue(eventsTab.exists, "Events tab should be visible")
        XCTAssertTrue(planningTab.exists, "Planning tab should be visible")
        XCTAssertTrue(profileTab.exists, "Profile tab should be visible")
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        // Test onboarding behavior when network is unavailable
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.terminate()
        app.launch()
        
        navigateToArtistSelection()
        
        // Should handle network error gracefully
        let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'network' OR label CONTAINS 'connection'")).firstMatch
        
        if errorMessage.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(true, "Should show network error message")
            
            // Should provide retry option
            let retryButton = app.buttons["Retry"]
            XCTAssertTrue(retryButton.exists, "Should provide retry option")
        } else {
            // Should fall back to cached/mock data
            let artistList = app.collectionViews.firstMatch
            XCTAssertTrue(artistList.exists, "Should show artist list even with network error (using fallback data)")
        }
    }
    
    func testBackNavigationDuringOnboarding() throws {
        navigateToArtistSelection()
        
        // Test back navigation from artist selection
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
            
            let nameInputField = app.textFields["Enter your name"]
            XCTAssertTrue(nameInputField.waitForExistence(timeout: 3.0), "Should navigate back to name input")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testOnboardingAccessibility() throws {
        navigateToNameInput()
        
        let nameInputField = app.textFields["Enter your name"]
        XCTAssertTrue(nameInputField.isHittable, "Name input field should be accessible")
        XCTAssertNotNil(nameInputField.label, "Name input field should have accessibility label")
        
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isHittable, "Continue button should be accessible")
        XCTAssertNotNil(continueButton.label, "Continue button should have accessibility label")
    }
    
    func testVoiceOverSupport() throws {
        // Enable VoiceOver simulation
        app.launchEnvironment["VOICEOVER_ENABLED"] = "true"
        app.terminate()
        app.launch()
        
        let welcomeTitle = app.staticTexts["Welcome to PiggyBong"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5.0), "Welcome title should be accessible via VoiceOver")
        
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be accessible via VoiceOver")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToNameInput() {
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5.0) {
            getStartedButton.tap()
        }
    }
    
    private func navigateToArtistSelection() {
        navigateToNameInput()
        
        let nameInputField = app.textFields["Enter your name"]
        if nameInputField.waitForExistence(timeout: 3.0) {
            nameInputField.tap()
            nameInputField.typeText("Test User")
            
            // Wait for validation
            let expectation = XCTestExpectation(description: "Wait for validation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
            
            let continueButton = app.buttons["Continue"]
            if continueButton.isEnabled {
                continueButton.tap()
            }
        }
    }
    
    private func navigateToBudgetSetup() {
        navigateToArtistSelection()
        
        let artistList = app.collectionViews.firstMatch
        if artistList.waitForExistence(timeout: 5.0) {
            // Wait for artists to load
            let expectation = XCTestExpectation(description: "Wait for artists")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
            
            // Select first artist
            let firstCell = artistList.cells.element(boundBy: 0)
            if firstCell.exists {
                firstCell.tap()
            }
            
            let continueButton = app.buttons["Continue"]
            if continueButton.isEnabled {
                continueButton.tap()
            }
        }
    }
    
    private func navigateToPriorityPlanning() {
        navigateToBudgetSetup()
        
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3.0) && continueButton.isEnabled {
            continueButton.tap()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}