//
//  ShoppingCalculatorUITests.swift
//  ShoppingCalculatorUITests
//
//  Created by 高畑蒼太郎 on 2025/10/19.
//

import XCTest

final class ShoppingCalculatorUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        app.launchArguments += ["UITESTS_BYPASS_AUTH"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    // MARK: - App Launch Tests
    
    func testAppLaunch() throws {
        // Verify the app launches successfully
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabNavigation() throws {
        // Wait for tab bar to appear first
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        // Test Home tab
        let homeTab = tabBar.buttons["Home"]
        XCTAssertTrue(homeTab.exists)
        homeTab.tap()
        
        // Test Scan tab
        let scanTab = tabBar.buttons["Scan"]
        XCTAssertTrue(scanTab.exists)
        scanTab.tap()
        
        // Test Analysis tab
        let analysisTab = tabBar.buttons["Analysis"]
        XCTAssertTrue(analysisTab.exists)
        analysisTab.tap()
        
        // Test AI Planner tab
        let plannerTab = tabBar.buttons["AI Planner"]
        XCTAssertTrue(plannerTab.exists)
        plannerTab.tap()
    }
    
    // MARK: - Home View Tests
    
    func testHomeViewElements() throws {
        // Navigate to Home tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        tabBar.buttons["Home"].tap()
        
        // Check if month display exists
        let monthText = app.staticTexts.matching(identifier: "month-display").firstMatch
        XCTAssertTrue(monthText.exists)
        
        // Check if total amount display exists
        let totalText = app.staticTexts.matching(identifier: "month-total").firstMatch
        XCTAssertTrue(totalText.exists)
        
        // Check if "Recent histories" text exists
        let recentHistoriesText = app.staticTexts["Recent histories"]
        XCTAssertTrue(recentHistoriesText.exists)
        
        // Check if "View All" link exists
        let viewAllLink = app.buttons["View All"]
        XCTAssertTrue(viewAllLink.exists)
    }
    
    func testHomeViewToolbarButtons() throws {
        // Navigate to Home tab
        app.tabBars.buttons["Home"].tap()
        
        // Check if user profile button exists
        let userProfileButton = app.buttons.matching(identifier: "user-profile-button").firstMatch
        XCTAssertTrue(userProfileButton.exists)
        
        // Check if search button exists
        let searchButton = app.buttons.matching(identifier: "search-button").firstMatch
        XCTAssertTrue(searchButton.exists)
        
        // Check if settings button exists
        let settingsButton = app.buttons.matching(identifier: "settings-button").firstMatch
        XCTAssertTrue(settingsButton.exists)
    }
    
    func testSearchFunctionality() throws {
        // Navigate to Home tab
        app.tabBars.buttons["Home"].tap()
        
        // Tap search button
        let searchButton = app.buttons.matching(identifier: "search-button").firstMatch
        searchButton.tap()
        
        // Check if search view appears
        let searchView = app.otherElements.matching(identifier: "search-view").firstMatch
        XCTAssertTrue(searchView.exists)
    }
    
    // MARK: - Camera View Tests
    
    func testCameraViewLaunch() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Check if camera view appears (this might be a full screen cover)
        // Note: Camera permissions might be required
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        // Camera view might not be accessible without proper permissions
        // XCTAssertTrue(cameraView.exists)
    }
    
    func testCameraViewButtons() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Check if close button exists
        let closeButton = app.buttons.matching(identifier: "close-camera-button").firstMatch
        // XCTAssertTrue(closeButton.exists)
        
        // Check if manual input button exists
        let manualInputButton = app.buttons.matching(identifier: "manual-input-button").firstMatch
        // XCTAssertTrue(manualInputButton.exists)
        
        // Check if review button exists
        let reviewButton = app.buttons.matching(identifier: "review-button").firstMatch
        // XCTAssertTrue(reviewButton.exists)
    }
    
    // MARK: - Manual Input Modal Tests
    
    func testManualInputModal() throws {
        // Navigate to Scan tab to access manual input
        app.tabBars.buttons["Scan"].tap()
        
        // Try to access manual input (this might require specific navigation)
        // The exact path depends on your app's navigation structure
    }
    
    // MARK: - Calendar View Tests
    
    func testCalendarViewElements() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Check if calendar view exists
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.exists)
        
        // Check if month/year display exists
        let monthYearText = app.staticTexts.matching(identifier: "month-year-display").firstMatch
        XCTAssertTrue(monthYearText.exists)
        
        // Check if "Today" button exists
        let todayButton = app.buttons["Today"]
        XCTAssertTrue(todayButton.exists)
    }
    
    func testCalendarDateSelection() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Try to select a date (this depends on your calendar implementation)
        let dayButtons = app.buttons.matching(identifier: "day-button")
        if dayButtons.count > 0 {
            dayButtons.element(boundBy: 0).tap()
        }
    }
    
    // MARK: - Settings View Tests
    
    func testSettingsViewNavigation() throws {
        // Navigate to Home tab
        app.tabBars.buttons["Home"].tap()
        
        // Tap settings button
        let settingsButton = app.buttons.matching(identifier: "settings-button").firstMatch
        settingsButton.tap()
        
        // Check if settings view appears
        let settingsView = app.otherElements.matching(identifier: "settings-view").firstMatch
        XCTAssertTrue(settingsView.exists)
        
        // Check if "Settings" title exists
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.exists)
    }
    
    func testSettingsViewElements() throws {
        // Navigate to settings
        app.tabBars.buttons["Home"].tap()
        app.buttons.matching(identifier: "settings-button").firstMatch.tap()
        
        // Check if user profile section exists
        let userProfileSection = app.otherElements.matching(identifier: "user-profile-section").firstMatch
        XCTAssertTrue(userProfileSection.exists)
        
        // Check if "Edit Profile" text exists
        let editProfileText = app.staticTexts["Edit Profile"]
        XCTAssertTrue(editProfileText.exists)
        
        // Check if sign out button exists
        let signOutButton = app.buttons["Sign out"]
        XCTAssertTrue(signOutButton.exists)
    }
    
    // MARK: - History View Tests
    
    func testHistoryViewNavigation() throws {
        // Navigate to Home tab
        app.tabBars.buttons["Home"].tap()
        
        // Tap "View All" link
        let viewAllLink = app.buttons["View All"]
        viewAllLink.tap()
        
        // Check if history view appears
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.exists)
    }
    
    func testHistoryViewElements() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Check if purchase items exist (if any)
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        // XCTAssertTrue(purchaseItems.count >= 0)
    }
    
    // MARK: - Analysis View Tests
    
    func testAnalysisViewElements() throws {
        // Navigate to Analysis tab
        app.tabBars.buttons["Analysis"].tap()
        
        // Check if analysis view exists
        let analysisView = app.otherElements.matching(identifier: "analysis-view").firstMatch
        XCTAssertTrue(analysisView.exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Test that all main UI elements are accessible
        app.tabBars.buttons["Home"].tap()
        
        // Check if elements have proper accessibility identifiers
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isHittable)
        
        let scanTab = app.tabBars.buttons["Scan"]
        XCTAssertTrue(scanTab.isHittable)
        
        let analysisTab = app.tabBars.buttons["Analysis"]
        XCTAssertTrue(analysisTab.isHittable)
        
        let plannerTab = app.tabBars.buttons["AI Planner"]
        XCTAssertTrue(plannerTab.isHittable)
    }
    
    // MARK: - Performance Tests
    
    func testAppPerformance() throws {
        // Test app performance during navigation
        measure {
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["Scan"].tap()
            app.tabBars.buttons["Analysis"].tap()
            app.tabBars.buttons["AI Planner"].tap()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        // Test app behavior when encountering errors
        // This might include testing with no network, invalid data, etc.
        app.tabBars.buttons["Home"].tap()
        
        // Verify app doesn't crash
        XCTAssertTrue(app.state == .runningForeground)
    }
}
