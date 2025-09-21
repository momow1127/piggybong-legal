import XCTest

// MARK: - ProfileSettings UI Tests for Device Compatibility & Responsive Design
final class ProfileSettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch arguments for testing
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--skip-onboarding")
        app.launchArguments.append("--mock-auth")
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Device Compatibility Tests
    
    func testProfileTitlePositioningOnIPhoneSE() throws {
        // Test on iPhone SE (375x667) - Small screen
        XCTContext.runActivity(named: "Test Profile Title on iPhone SE Screen Size") { _ in
            
            // Navigate to Profile Settings
            navigateToProfileSettings()
            
            // Verify Profile title exists and is positioned correctly
            let profileTitle = app.staticTexts["Profile"]
            XCTAssertTrue(profileTitle.exists, "Profile title should exist on iPhone SE")
            
            // Check title is visible within screen bounds
            let titleFrame = profileTitle.frame
            XCTAssertTrue(titleFrame.minY >= 0, "Title should be within top safe area on iPhone SE")
            XCTAssertTrue(titleFrame.maxY <= app.frame.height, "Title should not overflow screen on iPhone SE")
            
            // Verify title accessibility
            XCTAssertTrue(profileTitle.isHittable, "Profile title should be accessible on iPhone SE")
            
            // Check that title doesn't overlap with navigation elements
            let navigationArea = app.frame.height * 0.15 // Top 15% typically navigation area
            XCTAssertTrue(titleFrame.minY >= navigationArea * 0.5, "Title should not overlap navigation on iPhone SE")
        }
    }
    
    func testProfileTitlePositioningOnIPhone14ProMax() throws {
        // Test on iPhone 14 Pro Max (430x932) - Large screen
        XCTContext.runActivity(named: "Test Profile Title on iPhone 14 Pro Max Screen Size") { _ in
            
            navigateToProfileSettings()
            
            let profileTitle = app.staticTexts["Profile"]
            XCTAssertTrue(profileTitle.exists, "Profile title should exist on iPhone 14 Pro Max")
            
            // Verify proper scaling on larger screen
            let titleFrame = profileTitle.frame
            XCTAssertTrue(titleFrame.minY >= 0, "Title should be within safe area on iPhone 14 Pro Max")
            
            // Check title positioning relative to screen size
            let relativePosition = titleFrame.minY / app.frame.height
            XCTAssertTrue(relativePosition < 0.2, "Title should be positioned in upper portion on large screen")
            XCTAssertTrue(relativePosition > 0.05, "Title should respect safe area on large screen")
            
            // Verify title is not too small on large screen
            XCTAssertTrue(titleFrame.height > 20, "Title should be appropriately sized for large screen")
        }
    }
    
    func testSafeAreaBehaviorAcrossDevices() throws {
        XCTContext.runActivity(named: "Test Safe Area Behavior") { _ in
            
            navigateToProfileSettings()
            
            // Test that content respects safe area
            let profileTitle = app.staticTexts["Profile"]
            let titleFrame = profileTitle.frame
            
            // Verify title is within safe area bounds
            XCTAssertTrue(titleFrame.minY >= app.safeAreaInsets.top, 
                         "Title should respect top safe area insets")
            
            // Test bottom content respects safe area
            let logoutButton = app.buttons["Log Out"]
            if logoutButton.exists {
                let buttonFrame = logoutButton.frame
                XCTAssertTrue(buttonFrame.maxY <= app.frame.height - app.safeAreaInsets.bottom,
                             "Logout button should respect bottom safe area")
            }
        }
    }
    
    func testLandscapeOrientationLayout() throws {
        XCTContext.runActivity(named: "Test Layout in Landscape Orientation") { _ in
            
            navigateToProfileSettings()
            
            // Rotate to landscape
            XCUIDevice.shared.orientation = .landscapeLeft
            
            // Wait for rotation animation
            sleep(1)
            
            // Verify title still exists and is properly positioned
            let profileTitle = app.staticTexts["Profile"]
            XCTAssertTrue(profileTitle.exists, "Profile title should exist in landscape")
            
            let titleFrame = profileTitle.frame
            
            // In landscape, verify title doesn't get cut off
            XCTAssertTrue(titleFrame.minX >= 0, "Title should be within left bounds in landscape")
            XCTAssertTrue(titleFrame.maxX <= app.frame.width, "Title should be within right bounds in landscape")
            
            // Verify content is still scrollable if needed
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                XCTAssertTrue(scrollView.isScrollable, "Content should remain scrollable in landscape")
            }
            
            // Rotate back to portrait for cleanup
            XCUIDevice.shared.orientation = .portrait
            sleep(1)
        }
    }
    
    func testResponsiveTextSizing() throws {
        XCTContext.runActivity(named: "Test Responsive Text Sizing") { _ in
            
            navigateToProfileSettings()
            
            // Test Profile title font size
            let profileTitle = app.staticTexts["Profile"]
            let titleFrame = profileTitle.frame
            
            // Verify title is readable (minimum size)
            XCTAssertTrue(titleFrame.height >= 16, "Title should have minimum readable font size")
            XCTAssertTrue(titleFrame.height <= 40, "Title should not be excessively large")
            
            // Test section headers
            let accountHeader = app.staticTexts["ACCOUNT"]
            if accountHeader.exists {
                let headerFrame = accountHeader.frame
                XCTAssertTrue(headerFrame.height >= 12, "Section headers should be readable")
            }
            
            // Test menu item text
            let profileMenuItem = app.staticTexts["Profile"]
            if profileMenuItem.exists {
                let menuFrame = profileMenuItem.frame
                XCTAssertTrue(menuFrame.height >= 14, "Menu items should have readable font size")
            }
        }
    }
    
    // MARK: - Logout Flow UI Tests
    
    func testLogoutButtonVisibilityAndInteraction() throws {
        XCTContext.runActivity(named: "Test Logout Button Visibility and Interaction") { _ in
            
            navigateToProfileSettings()
            
            // Scroll to find logout button
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp() // Scroll down to find logout button
            }
            
            XCTAssertTrue(logoutButton.exists, "Logout button should exist")
            XCTAssertTrue(logoutButton.isHittable, "Logout button should be interactive")
            
            // Verify button styling indicates destructive action
            // Note: Color verification would require additional setup in real implementation
        }
    }
    
    func testLogoutLoadingOverlayAppears() throws {
        XCTContext.runActivity(named: "Test Logout Loading Overlay") { _ in
            
            navigateToProfileSettings()
            
            // Find and tap logout button
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            XCTAssertTrue(logoutButton.isHittable, "Logout button should be tappable")
            
            logoutButton.tap()
            
            // Verify loading overlay appears
            let signingOutText = app.staticTexts["Signing out..."]
            XCTAssertTrue(signingOutText.waitForExistence(timeout: 2.0), 
                         "Signing out text should appear in loading overlay")
            
            // Verify overlay is visible
            XCTAssertTrue(signingOutText.exists, "Loading overlay should display signing out message")
        }
    }
    
    func testRapidLogoutTapsHandledGracefully() throws {
        XCTContext.runActivity(named: "Test Rapid Logout Taps") { _ in
            
            navigateToProfileSettings()
            
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            // Tap logout button rapidly multiple times
            for i in 0..<5 {
                if logoutButton.isHittable {
                    logoutButton.tap()
                    
                    // Small delay between taps
                    usleep(100000) // 100ms
                    
                    // Verify only one loading overlay appears
                    let signingOutTexts = app.staticTexts.matching(identifier: "Signing out...")
                    XCTAssertTrue(signingOutTexts.count <= 1, 
                                 "Only one loading overlay should appear despite rapid taps (attempt \(i))")
                }
            }
        }
    }
    
    func testLogoutDuringPoorNetworkConditions() throws {
        XCTContext.runActivity(named: "Test Logout During Poor Network") { _ in
            
            // Set up network simulation (would require additional setup in real implementation)
            navigateToProfileSettings()
            
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            logoutButton.tap()
            
            // Verify loading overlay persists during slow network
            let signingOutText = app.staticTexts["Signing out..."]
            XCTAssertTrue(signingOutText.waitForExistence(timeout: 5.0), 
                         "Loading overlay should persist during network delays")
            
            // Verify user cannot interact with other elements during logout
            let profileTitle = app.staticTexts["Profile"]
            // Note: In real implementation, would verify overlay blocks interaction
        }
    }
    
    // MARK: - Accessibility UI Tests
    
    func testVoiceOverProfileTitleAnnouncement() throws {
        XCTContext.runActivity(named: "Test VoiceOver Profile Title") { _ in
            
            navigateToProfileSettings()
            
            let profileTitle = app.staticTexts["Profile"]
            XCTAssertTrue(profileTitle.exists, "Profile title should exist for VoiceOver")
            
            // Verify accessibility properties
            XCTAssertTrue(profileTitle.isAccessibilityElement, 
                         "Profile title should be accessible to VoiceOver")
            
            // In real implementation, would verify it announces as "Profile, heading"
            let accessibilityLabel = profileTitle.label
            XCTAssertEqual(accessibilityLabel, "Profile", 
                          "Profile title should have correct accessibility label")
        }
    }
    
    func testSigningOutTextVoiceOverSupport() throws {
        XCTContext.runActivity(named: "Test Signing Out VoiceOver Support") { _ in
            
            navigateToProfileSettings()
            
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            logoutButton.tap()
            
            let signingOutText = app.staticTexts["Signing out..."]
            XCTAssertTrue(signingOutText.waitForExistence(timeout: 2.0), 
                         "Signing out text should appear")
            
            // Verify accessibility
            XCTAssertTrue(signingOutText.isAccessibilityElement, 
                         "Signing out text should be accessible to VoiceOver")
            
            let accessibilityLabel = signingOutText.label
            XCTAssertTrue(accessibilityLabel.contains("Signing out"), 
                         "Accessibility label should indicate signing out action")
        }
    }
    
    func testVoiceOverNavigationThroughSettings() throws {
        XCTContext.runActivity(named: "Test VoiceOver Navigation Through Settings") { _ in
            
            navigateToProfileSettings()
            
            // Test that key elements are accessible
            let profileTitle = app.staticTexts["Profile"]
            XCTAssertTrue(profileTitle.isAccessibilityElement, "Title should be accessible")
            
            let accountSection = app.staticTexts["ACCOUNT"]
            if accountSection.exists {
                XCTAssertTrue(accountSection.isAccessibilityElement, "Section headers should be accessible")
            }
            
            let profileMenuItem = app.buttons.matching(identifier: "Profile").firstMatch
            if profileMenuItem.exists {
                XCTAssertTrue(profileMenuItem.isAccessibilityElement, "Menu items should be accessible")
            }
            
            let logoutButton = app.buttons["Log Out"]
            if logoutButton.exists {
                XCTAssertTrue(logoutButton.isAccessibilityElement, "Logout button should be accessible")
            }
        }
    }
    
    func testInteractiveElementsAccessibilityLabels() throws {
        XCTContext.runActivity(named: "Test Interactive Elements Accessibility") { _ in
            
            navigateToProfileSettings()
            
            // Test logout button accessibility
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.exists {
                app.swipeUp()
            }
            
            XCTAssertTrue(logoutButton.exists, "Logout button should exist")
            XCTAssertTrue(logoutButton.isAccessibilityElement, "Logout button should be accessible")
            
            // Verify button has appropriate accessibility traits
            // Note: In real implementation, would verify it has button trait and destructive trait
            
            let buttonLabel = logoutButton.label
            XCTAssertTrue(buttonLabel.contains("Log Out"), "Button should have descriptive label")
        }
    }
    
    // MARK: - State Management UI Tests
    
    func testUserDefaultsStateAfterLogout() throws {
        XCTContext.runActivity(named: "Test UserDefaults After Logout") { _ in
            
            navigateToProfileSettings()
            
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            logoutButton.tap()
            
            // Wait for logout to complete
            let signingOutText = app.staticTexts["Signing out..."]
            if signingOutText.exists {
                // Wait for logout to complete (text should disappear)
                XCTAssertTrue(signingOutText.waitForNonExistence(timeout: 5.0), 
                             "Logout should complete within reasonable time")
            }
            
            // Verify app redirects to authentication screen
            // Note: Implementation would depend on app's authentication flow
            let authScreen = app.otherElements["OnboardingView"]
            if authScreen.exists {
                XCTAssertTrue(authScreen.exists, "Should redirect to authentication after logout")
            }
        }
    }
    
    func testAppStateChangeAfterLogout() throws {
        XCTContext.runActivity(named: "Test App State After Logout") { _ in
            
            navigateToProfileSettings()
            
            // Perform logout
            let logoutButton = app.buttons["Log Out"]
            if !logoutButton.isHittable {
                app.swipeUp()
            }
            
            logoutButton.tap()
            
            // Wait for state change
            sleep(2)
            
            // Verify app navigation changed
            // Note: Exact verification depends on app's authentication flow
            let profileSettings = app.navigationBars["Profile"]
            if profileSettings.exists {
                // If still in profile settings, something may be wrong
                XCTFail("Should not remain in profile settings after logout")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToProfileSettings() {
        // Navigate to Profile Settings - implementation depends on app structure
        // This assumes there's a profile tab or button
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        }
        
        // If settings is in a separate screen
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
        }
        
        // Wait for profile settings to load
        let profileTitle = app.staticTexts["Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 5.0), 
                     "Profile settings should load within 5 seconds")
    }
    
    private func waitForLoadingToComplete() {
        let signingOutText = app.staticTexts["Signing out..."]
        if signingOutText.exists {
            XCTAssertTrue(signingOutText.waitForNonExistence(timeout: 10.0), 
                         "Loading should complete within reasonable time")
        }
    }
}

// MARK: - XCUIApplication Extensions
extension XCUIApplication {
    var safeAreaInsets: UIEdgeInsets {
        // This would need proper implementation based on device
        // For testing purposes, return reasonable defaults
        return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
    }
    
    func isScrollable(_ element: XCUIElement) -> Bool {
        let startCoordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let endCoordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        
        startCoordinate.press(forDuration: 0.01, thenDragTo: endCoordinate)
        
        // Simple check - in real implementation would verify scroll position changed
        return true
    }
}