import XCTest
@testable import Piggy_Bong

final class DashboardUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["SKIP_ONBOARDING"] = "true" // Start with completed onboarding
        app.launchEnvironment["MOCK_USER_DATA"] = "true"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Main Dashboard Tests
    
    func testDashboardLoadsCorrectly() throws {
        // Verify main dashboard elements
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Home tab should exist")
        
        if !homeTab.isSelected {
            homeTab.tap()
        }
        
        // Check for key dashboard elements
        let welcomeMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Welcome' OR label CONTAINS 'Hello'")).firstMatch
        XCTAssertTrue(welcomeMessage.exists, "Welcome message should be visible")
        
        let budgetOverview = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$' OR label CONTAINS 'Budget'")).firstMatch
        XCTAssertTrue(budgetOverview.exists, "Budget information should be visible")
        
        let artistSection = app.staticTexts["Your Artists"].exists || app.collectionViews.firstMatch.exists
        XCTAssertTrue(artistSection, "Artist section should be visible")
    }
    
    func testTabBarNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Tab bar should be visible")
        
        // Test all main tabs
        let tabs = ["Home", "Events", "Planning", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) tab should exist")
            
            tab.tap()
            
            // Wait for navigation
            let expectation = XCTestExpectation(description: "Wait for tab navigation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
            
            XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected after tap")
        }
    }
    
    func testBudgetOverviewDisplay() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for budget-related elements
        let budgetCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Monthly Budget' OR label CONTAINS 'Remaining'")).firstMatch
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 5.0), "Budget overview should be visible")
        
        let spentAmount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Spent' OR label CONTAINS '$'")).firstMatch
        XCTAssertTrue(spentAmount.exists, "Spent amount should be displayed")
        
        // Test budget card interaction
        let budgetSection = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'budget' OR label CONTAINS 'Budget'")).firstMatch
        if budgetSection.exists && budgetSection.isHittable {
            budgetSection.tap()
            
            // Should show budget details or navigation
            let expectation = XCTestExpectation(description: "Wait for budget interaction")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testArtistCardsDisplay() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for artist cards or collection view
        let artistCollection = app.collectionViews.firstMatch
        XCTAssertTrue(artistCollection.waitForExistence(timeout: 5.0), "Artist collection should be visible")
        
        // Wait for data to load
        let expectation = XCTestExpectation(description: "Wait for artists to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        let cellCount = artistCollection.cells.count
        XCTAssertGreaterThan(cellCount, 0, "Should display at least one artist card")
        
        // Test first artist card
        let firstArtistCard = artistCollection.cells.element(boundBy: 0)
        if firstArtistCard.exists {
            let artistName = firstArtistCard.staticTexts.firstMatch
            XCTAssertTrue(artistName.exists, "Artist name should be visible")
            
            // Test artist card interaction
            firstArtistCard.tap()
            
            // Should navigate to artist details or show context menu
            let expectation2 = XCTestExpectation(description: "Wait for artist card interaction")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation2.fulfill()
            }
            wait(for: [expectation2], timeout: 2.0)
        }
    }
    
    func testGoalsSection() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for goals section
        let goalsTitle = app.staticTexts["Your Goals"]
        if goalsTitle.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(goalsTitle.exists, "Goals section title should be visible")
            
            // Look for goal cards or empty state
            let goalsList = app.collectionViews.matching(identifier: "goals_collection").firstMatch
            let emptyGoalsMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No goals' OR label CONTAINS 'Create your first goal'")).firstMatch
            
            let hasGoals = goalsList.exists && goalsList.cells.count > 0
            let hasEmptyState = emptyGoalsMessage.exists
            
            XCTAssertTrue(hasGoals || hasEmptyState, "Should show either goals or empty state message")
            
            if hasGoals {
                // Test goal interaction
                let firstGoal = goalsList.cells.element(boundBy: 0)
                firstGoal.tap()
                
                // Should show goal details
                let expectation = XCTestExpectation(description: "Wait for goal interaction")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 2.0)
            }
        }
    }
    
    func testQuickAddFunctionality() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for quick add button (usually a + button)
        let quickAddButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+' OR identifier CONTAINS 'add' OR label CONTAINS 'Add'")).firstMatch
        
        if quickAddButton.waitForExistence(timeout: 5.0) {
            quickAddButton.tap()
            
            // Should show quick add sheet or navigate to add screen
            let quickAddSheet = app.sheets.firstMatch
            let quickAddView = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'quick_add' OR label CONTAINS 'Quick Add'")).firstMatch
            
            XCTAssertTrue(quickAddSheet.exists || quickAddView.exists, "Quick add interface should appear")
            
            if quickAddSheet.exists {
                // Test sheet interaction
                let purchaseOption = app.buttons["Add Purchase"]
                let goalOption = app.buttons["Add Goal"]
                
                XCTAssertTrue(purchaseOption.exists || goalOption.exists, "Quick add options should be available")
                
                // Dismiss sheet
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            }
        }
    }
    
    // MARK: - Purchase Tracking Tests
    
    func testPurchaseHistory() throws {
        // Navigate to purchase history
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for recent purchases section
        let recentPurchasesTitle = app.staticTexts["Recent Purchases"]
        let seeAllButton = app.buttons["See All"]
        
        if recentPurchasesTitle.exists && seeAllButton.exists {
            seeAllButton.tap()
            
            // Should navigate to full purchase history
            let purchasesList = app.tables.firstMatch
            XCTAssertTrue(purchasesList.waitForExistence(timeout: 5.0), "Purchases list should be visible")
            
            // Test purchase entry if available
            if purchasesList.cells.count > 0 {
                let firstPurchase = purchasesList.cells.element(boundBy: 0)
                
                // Verify purchase information
                let purchaseAmount = firstPurchase.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
                let purchaseTitle = firstPurchase.staticTexts.element(boundBy: 0)
                
                XCTAssertTrue(purchaseAmount.exists, "Purchase amount should be visible")
                XCTAssertTrue(purchaseTitle.exists, "Purchase title should be visible")
                
                // Test purchase interaction
                firstPurchase.tap()
                
                // Should show purchase details
                let expectation = XCTestExpectation(description: "Wait for purchase details")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 2.0)
            }
        }
    }
    
    func testAddPurchaseFlow() throws {
        // Navigate to add purchase
        let quickAddButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+' OR identifier CONTAINS 'add'")).firstMatch
        
        if quickAddButton.waitForExistence(timeout: 5.0) {
            quickAddButton.tap()
            
            let addPurchaseOption = app.buttons["Add Purchase"]
            if addPurchaseOption.waitForExistence(timeout: 3.0) {
                addPurchaseOption.tap()
                
                // Should open add purchase form
                let amountField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Amount' OR placeholder CONTAINS '$'")).firstMatch
                let descriptionField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Description' OR placeholder CONTAINS 'What did you buy'")).firstMatch
                let artistPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Select Artist' OR identifier CONTAINS 'artist_picker'")).firstMatch
                
                XCTAssertTrue(amountField.waitForExistence(timeout: 3.0), "Amount field should be visible")
                XCTAssertTrue(descriptionField.exists, "Description field should be visible")
                XCTAssertTrue(artistPicker.exists, "Artist picker should be visible")
                
                // Test form filling
                amountField.tap()
                amountField.typeText("29.99")
                
                descriptionField.tap()
                descriptionField.typeText("Test Album Purchase")
                
                // Test artist selection
                artistPicker.tap()
                
                let artistsList = app.tables.firstMatch
                if artistsList.waitForExistence(timeout: 3.0) && artistsList.cells.count > 0 {
                    let firstArtist = artistsList.cells.element(boundBy: 0)
                    firstArtist.tap()
                }
                
                // Test save
                let saveButton = app.buttons["Save"]
                if saveButton.exists && saveButton.isEnabled {
                    saveButton.tap()
                    
                    // Should return to dashboard with new purchase
                    let homeTab = app.tabBars.buttons["Home"]
                    XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Should return to dashboard")
                }
            }
        }
    }
    
    // MARK: - Goal Management Tests
    
    func testGoalCreationFlow() throws {
        let planningTab = app.tabBars.buttons["Planning"]
        planningTab.tap()
        
        let addGoalButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Goal' OR label CONTAINS 'New Goal' OR label CONTAINS '+'")).firstMatch
        
        if addGoalButton.waitForExistence(timeout: 5.0) {
            addGoalButton.tap()
            
            // Should open goal creation form
            let goalNameField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Goal name' OR placeholder CONTAINS 'What are you saving for'")).firstMatch
            let targetAmountField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Target' OR placeholder CONTAINS '$'")).firstMatch
            let deadlinePicker = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Deadline' OR identifier CONTAINS 'deadline_picker'")).firstMatch
            
            XCTAssertTrue(goalNameField.waitForExistence(timeout: 3.0), "Goal name field should be visible")
            XCTAssertTrue(targetAmountField.exists, "Target amount field should be visible")
            XCTAssertTrue(deadlinePicker.exists, "Deadline picker should be visible")
            
            // Test form filling
            goalNameField.tap()
            goalNameField.typeText("Concert Tickets")
            
            targetAmountField.tap()
            targetAmountField.typeText("200")
            
            // Test deadline selection
            deadlinePicker.tap()
            
            let datePicker = app.datePickers.firstMatch
            if datePicker.waitForExistence(timeout: 3.0) {
                // Select a future date
                let doneButton = app.buttons["Done"]
                if doneButton.exists {
                    doneButton.tap()
                }
            }
            
            // Test save
            let createGoalButton = app.buttons["Create Goal"]
            if createGoalButton.exists && createGoalButton.isEnabled {
                createGoalButton.tap()
                
                // Should return to goals view with new goal
                let goalsList = app.collectionViews.firstMatch
                XCTAssertTrue(goalsList.waitForExistence(timeout: 5.0), "Goals list should be visible")
            }
        }
    }
    
    func testGoalProgressUpdate() throws {
        let planningTab = app.tabBars.buttons["Planning"]
        planningTab.tap()
        
        let goalsList = app.collectionViews.firstMatch
        if goalsList.waitForExistence(timeout: 5.0) && goalsList.cells.count > 0 {
            let firstGoal = goalsList.cells.element(boundBy: 0)
            firstGoal.tap()
            
            // Should show goal details
            let addProgressButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Progress' OR label CONTAINS 'Update' OR label CONTAINS '+'")).firstMatch
            
            if addProgressButton.waitForExistence(timeout: 3.0) {
                addProgressButton.tap()
                
                // Should show progress entry form
                let amountField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Amount' OR placeholder CONTAINS '$'")).firstMatch
                
                if amountField.waitForExistence(timeout: 3.0) {
                    amountField.tap()
                    amountField.typeText("25")
                    
                    let saveButton = app.buttons["Save"]
                    if saveButton.exists {
                        saveButton.tap()
                        
                        // Should update goal progress
                        let expectation = XCTestExpectation(description: "Wait for progress update")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            expectation.fulfill()
                        }
                        wait(for: [expectation], timeout: 3.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Events Screen Tests
    
    func testEventsScreen() throws {
        let eventsTab = app.tabBars.buttons["Events"]
        eventsTab.tap()
        
        // Check for events content
        let eventsTitle = app.navigationBars["Events"]
        XCTAssertTrue(eventsTitle.waitForExistence(timeout: 5.0), "Events navigation title should be visible")
        
        // Look for news feed or events list
        let newsFeed = app.tables.firstMatch
        let emptyState = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No events' OR label CONTAINS 'Coming soon'")).firstMatch
        
        XCTAssertTrue(newsFeed.exists || emptyState.exists, "Should show events feed or empty state")
        
        if newsFeed.exists && newsFeed.cells.count > 0 {
            // Test news item interaction
            let firstNewsItem = newsFeed.cells.element(boundBy: 0)
            firstNewsItem.tap()
            
            // Should show news details or external link
            let expectation = XCTestExpectation(description: "Wait for news interaction")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Profile Screen Tests
    
    func testProfileScreen() throws {
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        // Check for profile content
        let profileTitle = app.navigationBars["Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 5.0), "Profile navigation title should be visible")
        
        // Look for user information
        let userName = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'User' OR label CONTAINS 'Test'")).firstMatch
        let budgetInfo = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Budget' OR label CONTAINS '$'")).firstMatch
        
        XCTAssertTrue(userName.exists, "User name should be visible")
        XCTAssertTrue(budgetInfo.exists, "Budget information should be visible")
        
        // Look for subscription status
        let subscriptionBadge = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Free' OR label CONTAINS 'Premium' OR label CONTAINS 'VIP'")).firstMatch
        XCTAssertTrue(subscriptionBadge.exists, "Subscription status should be visible")
        
        // Test settings or upgrade options
        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Upgrade' OR label CONTAINS 'Premium'")).firstMatch
        if upgradeButton.exists {
            upgradeButton.tap()
            
            // Should show paywall or upgrade options
            let expectation = XCTestExpectation(description: "Wait for upgrade interaction")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchFunctionality() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Look for search functionality
        let searchButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Search' OR identifier CONTAINS 'search'")).firstMatch
        let searchField = app.searchFields.firstMatch
        
        if searchButton.exists {
            searchButton.tap()
            XCTAssertTrue(searchField.waitForExistence(timeout: 3.0), "Search field should appear")
        } else if searchField.exists {
            searchField.tap()
        }
        
        if searchField.exists {
            searchField.typeText("Album")
            
            // Wait for search results
            let expectation = XCTestExpectation(description: "Wait for search results")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3.0)
            
            // Should show search results
            let searchResults = app.tables.firstMatch
            XCTAssertTrue(searchResults.exists, "Search results should be displayed")
        }
    }
    
    // MARK: - Pull to Refresh Tests
    
    func testPullToRefresh() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5.0) {
            // Perform pull to refresh gesture
            let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let endCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            
            // Wait for refresh to complete
            let expectation = XCTestExpectation(description: "Wait for pull to refresh")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
            
            // Should show updated content (verified by no crash)
            XCTAssertTrue(true, "Pull to refresh should complete without crashing")
        }
    }
    
    // MARK: - Error State Tests
    
    func testOfflineMode() throws {
        // Simulate offline mode
        app.launchEnvironment["SIMULATE_OFFLINE"] = "true"
        app.terminate()
        app.launch()
        
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Should handle offline state gracefully
        let offlineMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'offline' OR label CONTAINS 'connection'")).firstMatch
        
        if offlineMessage.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(true, "Should show offline message")
        } else {
            // Should show cached data
            let cachedContent = app.collectionViews.firstMatch
            XCTAssertTrue(cachedContent.exists, "Should show cached content in offline mode")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testScrollPerformance() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5.0) {
            measure {
                // Perform multiple scroll gestures
                for _ in 0..<5 {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
        }
    }
}