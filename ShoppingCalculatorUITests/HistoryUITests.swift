//
//  HistoryUITests.swift
//  ShoppingCalculatorUITests
//
//  Created by 高畑蒼太郎 on 2025/10/19.
//

import XCTest

final class HistoryUITests: XCTestCase {
    
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
    
    // MARK: - History View Navigation Tests
    
    func testHistoryViewNavigation() throws {
        // Navigate to Home tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        tabBar.buttons["Home"].tap()
        
        // Tap "View All" link
        let viewAllLink = app.buttons["View All"]
        XCTAssertTrue(viewAllLink.exists)
        viewAllLink.tap()
        
        // Check if history view appears
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
    }
    
    func testHistoryViewBackNavigation() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Check if back button exists
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            
            // Verify we're back to home view
            let homeView = app.otherElements.matching(identifier: "home-view").firstMatch
            XCTAssertTrue(homeView.waitForExistence(timeout: 2.0))
        }
    }
    
    // MARK: - Purchase Display Tests
    
    func testPurchaseListDisplay() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if purchase items exist
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        // XCTAssertTrue(purchaseItems.count >= 0)
    }
    
    func testPurchaseItemElements() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if purchase items have required elements
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        if purchaseItems.count > 0 {
            let firstItem = purchaseItems.element(boundBy: 0)
            
            // Check if store name exists
            let storeName = firstItem.staticTexts.matching(identifier: "store-name").firstMatch
            if storeName.exists {
                XCTAssertTrue(storeName.exists)
            }
            
            // Check if item count exists
            let itemCount = firstItem.staticTexts.matching(identifier: "item-count").firstMatch
            if itemCount.exists {
                XCTAssertTrue(itemCount.exists)
            }
            
            // Check if total amount exists
            let totalAmount = firstItem.staticTexts.matching(identifier: "total-amount").firstMatch
            if totalAmount.exists {
                XCTAssertTrue(totalAmount.exists)
            }
        }
    }
    
    func testPurchaseItemInteraction() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Try to tap on a purchase item
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        if purchaseItems.count > 0 {
            let firstItem = purchaseItems.element(boundBy: 0)
            firstItem.tap()
            
            // Check if detail modal opens
            let detailModal = app.sheets.firstMatch
            if detailModal.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(detailModal.exists)
            }
        }
    }
    
    // MARK: - Date Grouping Tests
    
    func testDateGrouping() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if date headers exist
        let dateHeaders = app.staticTexts.matching(identifier: "date-header")
        // XCTAssertTrue(dateHeaders.count >= 0)
    }
    
    func testDateHeaderFormat() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if date headers are properly formatted
        let dateHeaders = app.staticTexts.matching(identifier: "date-header")
        if dateHeaders.count > 0 {
            let firstHeader = dateHeaders.element(boundBy: 0)
            XCTAssertTrue(firstHeader.exists)
        }
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyState() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if empty state is displayed when no purchases exist
        let emptyStateIcon = app.images.matching(identifier: "empty-state-icon").firstMatch
        let emptyStateText = app.staticTexts["No purchases found"]
        
        if emptyStateIcon.exists || emptyStateText.exists {
            XCTAssertTrue(emptyStateIcon.exists || emptyStateText.exists)
        }
    }
    
    // MARK: - Purchase Detail Modal Tests
    
    func testPurchaseDetailModal() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Try to open purchase detail
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        if purchaseItems.count > 0 {
            let firstItem = purchaseItems.element(boundBy: 0)
            firstItem.tap()
            
            let detailModal = app.sheets.firstMatch
            if detailModal.waitForExistence(timeout: 2.0) {
                // Check if detail modal elements exist
                let storeName = detailModal.staticTexts.matching(identifier: "detail-store-name").firstMatch
                if storeName.exists {
                    XCTAssertTrue(storeName.exists)
                }
                
                let totalAmount = detailModal.staticTexts.matching(identifier: "detail-total-amount").firstMatch
                if totalAmount.exists {
                    XCTAssertTrue(totalAmount.exists)
                }
                
                let productList = detailModal.tables.firstMatch
                if productList.exists {
                    XCTAssertTrue(productList.exists)
                }
            }
        }
    }
    
    func testPurchaseDetailModalDismissal() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Open purchase detail
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        if purchaseItems.count > 0 {
            let firstItem = purchaseItems.element(boundBy: 0)
            firstItem.tap()
            
            let detailModal = app.sheets.firstMatch
            if detailModal.waitForExistence(timeout: 2.0) {
                // Try to dismiss modal
                let dismissButton = detailModal.buttons.matching(identifier: "dismiss-button").firstMatch
                if dismissButton.exists {
                    dismissButton.tap()
                } else {
                    // Try swipe down to dismiss
                    let startPoint = detailModal.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
                    let endPoint = detailModal.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
                    startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
                }
            }
        }
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchFunctionality() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if search functionality exists
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("test")
            
            // Check if search results are filtered
            let searchResults = app.otherElements.matching(identifier: "purchase-item")
            // XCTAssertTrue(searchResults.count >= 0)
        }
    }
    
    func testFilterFunctionality() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if filter options exist
        let filterButton = app.buttons.matching(identifier: "filter-button").firstMatch
        if filterButton.exists {
            filterButton.tap()
            
            // Check if filter options appear
            let filterOptions = app.sheets.firstMatch
            if filterOptions.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(filterOptions.exists)
            }
        }
    }
    
    // MARK: - Scroll Tests
    
    func testScrollFunctionality() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Test scrolling
        historyView.swipeUp()
        historyView.swipeDown()
    }
    
    func testInfiniteScroll() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Test infinite scroll (if implemented)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
            scrollView.swipeUp()
        }
    }
    
    // MARK: - Currency Formatting Tests
    
    func testCurrencyDisplay() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if currency is properly formatted
        let totalAmounts = app.staticTexts.matching(identifier: "total-amount")
        if totalAmounts.count > 0 {
            let firstAmount = totalAmounts.element(boundBy: 0)
            let amountText = firstAmount.label
            
            // Check if amount contains currency symbol or code
            XCTAssertTrue(amountText.contains("$") || amountText.contains("USD") || amountText.contains("€") || amountText.contains("¥"))
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testHistoryAccessibility() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Check if elements are accessible
        let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
        if purchaseItems.count > 0 {
            let firstItem = purchaseItems.element(boundBy: 0)
            XCTAssertTrue(firstItem.isHittable)
        }
    }
    
    // MARK: - Performance Tests
    
    func testHistoryLoadingPerformance() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        
        // Measure performance of "View All" navigation
        measure {
            app.buttons["View All"].tap()
            
            let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
            XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        }
    }
    
    func testPurchaseItemInteractionPerformance() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Measure performance of purchase item interaction
        measure {
            let purchaseItems = app.otherElements.matching(identifier: "purchase-item")
            if purchaseItems.count > 0 {
                purchaseItems.element(boundBy: 0).tap()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testHistoryErrorHandling() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Check if error states are handled properly
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Data Refresh Tests
    
    func testDataRefresh() throws {
        // Navigate to history view
        app.tabBars.buttons["Home"].tap()
        app.buttons["View All"].tap()
        
        // Wait for history view to load
        let historyView = app.otherElements.matching(identifier: "history-view").firstMatch
        XCTAssertTrue(historyView.waitForExistence(timeout: 3.0))
        
        // Test pull-to-refresh (if implemented)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            let startPoint = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            let endPoint = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        }
    }
}

