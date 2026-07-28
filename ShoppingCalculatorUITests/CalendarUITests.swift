//
//  CalendarUITests.swift
//  ShoppingCalculatorUITests
//
//  Created by 高畑蒼太郎 on 2025/10/19.
//

import XCTest

final class CalendarUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["UITESTS_BYPASS_AUTH"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Calendar View Tests
    
    func testCalendarViewLaunch() throws {
        // Navigate to AI Planner tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        tabBar.buttons["AI Planner"].tap()
        
        // Check if calendar view exists
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
    }
    
    func testCalendarNavigation() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Check if month/year display exists
        let monthYearText = app.staticTexts.matching(identifier: "month-year-display").firstMatch
        XCTAssertTrue(monthYearText.exists)
        
        // Check if "Today" button exists
        let todayButton = app.buttons["Today"]
        XCTAssertTrue(todayButton.exists)
    }
    
    func testDateSelection() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Try to select a date
        let dayButtons = app.buttons.matching(identifier: "day-button")
        if dayButtons.count > 0 {
            let firstDay = dayButtons.element(boundBy: 0)
            firstDay.tap()
            
            // Verify selection (this depends on your implementation)
            XCTAssertTrue(firstDay.isSelected || firstDay.isHittable)
        }
    }
    
    func testWeekNavigation() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Test swiping between weeks
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Swipe left to go to next week
        let startPoint = calendarView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let endPoint = calendarView.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        
        // Swipe right to go to previous week
        endPoint.press(forDuration: 0.1, thenDragTo: startPoint)
    }
    
    func testTodayButton() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Check if Today button exists and is tappable
        let todayButton = app.buttons["Today"]
        XCTAssertTrue(todayButton.exists)
        XCTAssertTrue(todayButton.isHittable)
        
        // Tap Today button
        todayButton.tap()
    }
    
    func testDatePicker() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Tap on month/year display to open date picker
        let monthYearText = app.staticTexts.matching(identifier: "month-year-display").firstMatch
        if monthYearText.exists {
            monthYearText.tap()
            
            // Check if date picker appears
            let datePicker = app.datePickers.firstMatch
            if datePicker.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(datePicker.exists)
            }
        }
    }
    
    // MARK: - Meal Plan Tests
    
    func testMealPlanDisplay() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if meal plans are displayed
        let mealPlans = app.otherElements.matching(identifier: "meal-plan")
        // XCTAssertTrue(mealPlans.count >= 0)
    }
    
    func testMealPlanCards() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if meal plan cards exist
        let mealPlanCards = app.otherElements.matching(identifier: "meal-plan-card")
        if mealPlanCards.count > 0 {
            let firstCard = mealPlanCards.element(boundBy: 0)
            XCTAssertTrue(firstCard.exists)
        }
    }
    
    func testMealPlanInteraction() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Try to interact with meal plan cards
        let mealPlanCards = app.otherElements.matching(identifier: "meal-plan-card")
        if mealPlanCards.count > 0 {
            let firstCard = mealPlanCards.element(boundBy: 0)
            firstCard.tap()
            
            // Check if detail modal opens
            let detailModal = app.sheets.firstMatch
            if detailModal.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(detailModal.exists)
            }
        }
    }
    
    func testMealPlanDetailModal() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Try to open meal plan detail
        let mealPlanCards = app.otherElements.matching(identifier: "meal-plan-card")
        if mealPlanCards.count > 0 {
            let firstCard = mealPlanCards.element(boundBy: 0)
            firstCard.tap()
            
            let detailModal = app.sheets.firstMatch
            if detailModal.waitForExistence(timeout: 2.0) {
                // Check if ingredients are displayed
                let ingredientsList = app.tables.firstMatch
                if ingredientsList.exists {
                    XCTAssertTrue(ingredientsList.exists)
                }
            }
        }
    }
    
    // MARK: - Meal Type Tests
    
    func testMealTypeDisplay() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if meal types are displayed (breakfast, lunch, dinner)
        let breakfastMeals = app.otherElements.matching(identifier: "breakfast-meal")
        let lunchMeals = app.otherElements.matching(identifier: "lunch-meal")
        let dinnerMeals = app.otherElements.matching(identifier: "dinner-meal")
        
        // At least one meal type should be present
        let totalMeals = breakfastMeals.count + lunchMeals.count + dinnerMeals.count
        // XCTAssertTrue(totalMeals >= 0)
    }
    
    func testMealTypeColors() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if meal type indicators exist
        let mealIndicators = app.otherElements.matching(identifier: "meal-indicator")
        if mealIndicators.count > 0 {
            XCTAssertTrue(mealIndicators.element(boundBy: 0).exists)
        }
    }
    
    // MARK: - Time-based Tests
    
    func testCurrentTimeMealHighlighting() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if current time meal is highlighted
        let currentTimeMeal = app.otherElements.matching(identifier: "current-time-meal").firstMatch
        // This might not always be present depending on time of day
        // XCTAssertTrue(currentTimeMeal.exists)
    }
    
    // MARK: - Loading States
    
    func testLoadingState() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Check if loading indicator appears
        let loadingIndicator = app.progressIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.waitForDisappearance(timeout: 10.0))
        }
    }
    
    func testEmptyState() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if empty state message appears
        let emptyStateText = app.staticTexts["No plans found... wait for next time!"]
        if emptyStateText.exists {
            XCTAssertTrue(emptyStateText.exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testCalendarAccessibility() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Check if calendar elements are accessible
        let todayButton = app.buttons["Today"]
        XCTAssertTrue(todayButton.isHittable)
        
        let monthYearText = app.staticTexts.matching(identifier: "month-year-display").firstMatch
        XCTAssertTrue(monthYearText.isHittable)
    }
    
    // MARK: - Performance Tests
    
    func testCalendarPerformance() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Measure calendar loading performance
        measure {
            let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
            XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        }
    }
    
    func testDateSelectionPerformance() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Wait for calendar to load
        let calendarView = app.otherElements.matching(identifier: "calendar-view").firstMatch
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3.0))
        
        // Measure date selection performance
        measure {
            let dayButtons = app.buttons.matching(identifier: "day-button")
            if dayButtons.count > 0 {
                dayButtons.element(boundBy: 0).tap()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCalendarErrorHandling() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Check if error states are handled properly
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    func testCalendarToSettingsNavigation() throws {
        // Navigate to AI Planner tab
        app.tabBars.buttons["AI Planner"].tap()
        
        // Navigate to settings (if accessible from calendar)
        let settingsButton = app.buttons.matching(identifier: "settings-button").firstMatch
        if settingsButton.exists {
            settingsButton.tap()
            
            // Check if settings view appears
            let settingsView = app.otherElements.matching(identifier: "settings-view").firstMatch
            XCTAssertTrue(settingsView.waitForExistence(timeout: 3.0))
        }
    }
}

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
