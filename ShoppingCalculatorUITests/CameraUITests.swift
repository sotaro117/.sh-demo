//
//  CameraUITests.swift
//  ShoppingCalculatorUITests
//
//  Created by 高畑蒼太郎 on 2025/10/19.
//

import XCTest

final class CameraUITests: XCTestCase {
    
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
    
    // MARK: - Camera View Tests
    
    func testCameraViewLaunch() throws {
        // Navigate to Scan tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        tabBar.buttons["Scan"].tap()
        
        // Wait for camera view to appear
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
    }
    
    func testCameraViewDismissal() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Try to dismiss camera view (swipe down gesture)
        let startPoint = cameraView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endPoint = cameraView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
    }
    
    func testCameraViewButtons() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Check if close button exists
        let closeButton = app.buttons.matching(identifier: "close-camera-button").firstMatch
        if closeButton.exists {
            XCTAssertTrue(closeButton.isHittable)
        }
        
        // Check if manual input button exists
        let manualInputButton = app.buttons.matching(identifier: "manual-input-button").firstMatch
        if manualInputButton.exists {
            XCTAssertTrue(manualInputButton.isHittable)
        }
        
        // Check if review button exists
        let reviewButton = app.buttons.matching(identifier: "review-button").firstMatch
        if reviewButton.exists {
            XCTAssertTrue(reviewButton.isHittable)
        }
    }
    
    func testCaptureButton() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Check if capture button exists
        let captureButton = app.buttons.matching(identifier: "capture-button").firstMatch
        if captureButton.exists {
            XCTAssertTrue(captureButton.isHittable)
        }
    }
    
    func testCameraPermissions() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Check if permission alert appears
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.exists {
            // Handle permission alert
            let allowButton = permissionAlert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
            }
        }
    }
    
    // MARK: - Manual Input Modal Tests
    
    func testManualInputModalLaunch() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Try to access manual input
        let manualInputButton = app.buttons.matching(identifier: "manual-input-button").firstMatch
        if manualInputButton.exists {
            manualInputButton.tap()
            
            // Check if manual input modal appears
            let manualInputModal = app.sheets.firstMatch
            XCTAssertTrue(manualInputModal.waitForExistence(timeout: 3.0))
        }
    }
    
    func testManualInputForm() throws {
        // Navigate to manual input (if accessible)
        app.tabBars.buttons["Scan"].tap()
        
        // Try to access manual input modal
        let manualInputButton = app.buttons.matching(identifier: "manual-input-button").firstMatch
        if manualInputButton.exists {
            manualInputButton.tap()
            
            let manualInputModal = app.sheets.firstMatch
            if manualInputModal.waitForExistence(timeout: 3.0) {
                // Test product name input
                let productNameField = app.textFields["Enter Product"]
                if productNameField.exists {
                    productNameField.tap()
                    productNameField.typeText("Test Product")
                }
                
                // Test price input
                let priceField = app.textFields["Enter Price"]
                if priceField.exists {
                    priceField.tap()
                    priceField.typeText("5.99")
                }
                
                // Test quantity stepper
                let quantityStepper = app.steppers.firstMatch
                if quantityStepper.exists {
                    quantityStepper.buttons["Increment"].tap()
                }
                
                // Test category picker
                let categoryPicker = app.pickers.firstMatch
                if categoryPicker.exists {
                    categoryPicker.tap()
                }
                
                // Test add button
                let addButton = app.buttons["Add"]
                if addButton.exists {
                    XCTAssertTrue(addButton.isHittable)
                }
            }
        }
    }
    
    // MARK: - Scanner View Tests
    
    func testScannerViewLaunch() throws {
        // This would be triggered after taking a photo
        // The exact navigation depends on your app's flow
    }
    
    func testScannerViewElements() throws {
        // Test scanner view elements if accessible
    }
    
    // MARK: - Review Modal Tests
    
    func testReviewModalLaunch() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Try to access review modal
        let reviewButton = app.buttons.matching(identifier: "review-button").firstMatch
        if reviewButton.exists {
            reviewButton.tap()
            
            // Check if review modal appears
            let reviewModal = app.otherElements.matching(identifier: "review-modal").firstMatch
            XCTAssertTrue(reviewModal.waitForExistence(timeout: 3.0))
        }
    }
    
    func testReviewModalElements() throws {
        // Test review modal elements if accessible
        app.tabBars.buttons["Scan"].tap()
        
        let reviewButton = app.buttons.matching(identifier: "review-button").firstMatch
        if reviewButton.exists {
            reviewButton.tap()
            
            let reviewModal = app.otherElements.matching(identifier: "review-modal").firstMatch
            if reviewModal.waitForExistence(timeout: 3.0) {
                // Test store name input
                let storeField = app.textFields["Store Name"]
                if storeField.exists {
                    storeField.tap()
                    storeField.typeText("Test Store")
                }
                
                // Test finish button
                let finishButton = app.buttons["Finish"]
                if finishButton.exists {
                    XCTAssertTrue(finishButton.isHittable)
                }
            }
        }
    }
    
    // MARK: - Gesture Tests
    
    func testSwipeToDismiss() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Test swipe down to dismiss
        let startPoint = cameraView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endPoint = cameraView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
    }
    
    func testFocusTap() throws {
        // Navigate to Scan tab
        app.tabBars.buttons["Scan"].tap()
        
        // Wait for camera view
        let cameraView = app.otherElements.matching(identifier: "camera-view").firstMatch
        XCTAssertTrue(cameraView.waitForExistence(timeout: 5.0))
        
        // Test tap to focus
        let centerPoint = cameraView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerPoint.tap()
    }
    
    // MARK: - Error Handling Tests
    
    func testCameraErrorHandling() throws {
        // Test camera error scenarios
        app.tabBars.buttons["Scan"].tap()
        
        // Check if error alerts are handled properly
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    func testSettingsAlert() throws {
        // Test settings alert when camera permission is denied
        app.tabBars.buttons["Scan"].tap()
        
        // Check if settings alert appears
        let settingsAlert = app.alerts["Warning"]
        if settingsAlert.exists {
            let settingsButton = settingsAlert.buttons["Go to settings"]
            if settingsButton.exists {
                XCTAssertTrue(settingsButton.isHittable)
            }
        }
    }
}
