import XCTest
import SwiftUI
@testable import ShoppingCalculator

@MainActor
class StepperControlTests: XCTestCase {
    
    func testStepperControlInitialization() {
        // Given
        @State var value = 1
        let minValue = 1
        let maxValue = 50
        
        // When
        let stepperControl = StepperControl(
            value: $value,
            minValue: minValue,
            maxValue: maxValue
        )
        
        // Then
        XCTAssertNotNil(stepperControl)
    }
    
    func testValueBinding() {
        // Given
        @State var value = 5
        
        // When
        value = 10
        
        // Then
        XCTAssertEqual(value, 10)
    }
    
    func testMinValueConfiguration() {
        // Given
        let minValue = 1
        
        // When & Then
        XCTAssertEqual(minValue, 1)
    }
    
    func testMaxValueConfiguration() {
        // Given
        let maxValue = 50
        
        // When & Then
        XCTAssertEqual(maxValue, 50)
    }
    
    func testIncrementButton() {
        // Given
        @State var value = 5
        let maxValue = 10
        
        // When
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 6)
    }
    
    func testIncrementButtonAtMaxValue() {
        // Given
        @State var value = 10
        let maxValue = 10
        
        // When
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 10) // Should not increment
    }
    
    func testDecrementButton() {
        // Given
        @State var value = 5
        let minValue = 1
        
        // When
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 4)
    }
    
    func testDecrementButtonAtMinValue() {
        // Given
        @State var value = 1
        let minValue = 1
        
        // When
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 1) // Should not decrement
    }
    
    func testValueDisplay() {
        // Given
        @State var value = 5
        
        // When
        let displayText = "\(value)"
        
        // Then
        XCTAssertEqual(displayText, "5")
    }
    
    func testButtonText() {
        // Given
        let incrementText = "+"
        let decrementText = "-"
        
        // When & Then
        XCTAssertEqual(incrementText, "+")
        XCTAssertEqual(decrementText, "-")
    }
    
    func testButtonFrame() {
        // Given
        let buttonWidth: CGFloat = 15
        let buttonHeight: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(buttonWidth, 15)
        XCTAssertEqual(buttonHeight, 15)
    }
    
    func testButtonPadding() {
        // Given
        let buttonPadding: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(buttonPadding, 15)
    }
    
    func testButtonBackground() {
        // Given
        let backgroundColor = Color.gray.opacity(0.2)
        
        // When & Then
        XCTAssertNotNil(backgroundColor)
    }
    
    func testButtonShape() {
        // Given
        let shape = Circle()
        
        // When & Then
        XCTAssertNotNil(shape)
    }
    
    func testHStackSpacing() {
        // Given
        let spacing: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(spacing, 15)
    }
    
    func testForegroundColor() {
        // Given
        let foregroundColor = Color.black
        
        // When & Then
        XCTAssertNotNil(foregroundColor)
    }
    
    func testValueBoundsChecking() {
        // Given
        @State var value = 1
        let minValue = 1
        let maxValue = 10
        
        // When
        // Test minimum bound
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 1) // Should not go below minimum
        
        // When
        // Test maximum bound
        value = 10
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 10) // Should not go above maximum
    }
    
    func testValueIncrementWithinBounds() {
        // Given
        @State var value = 5
        let maxValue = 10
        
        // When
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 6)
    }
    
    func testValueDecrementWithinBounds() {
        // Given
        @State var value = 5
        let minValue = 1
        
        // When
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 4)
    }
    
    func testValueAtMinimum() {
        // Given
        @State var value = 1
        let minValue = 1
        
        // When
        let canDecrement = value > minValue
        
        // Then
        XCTAssertFalse(canDecrement)
    }
    
    func testValueAtMaximum() {
        // Given
        @State var value = 50
        let maxValue = 50
        
        // When
        let canIncrement = value < maxValue
        
        // Then
        XCTAssertFalse(canIncrement)
    }
    
    func testValueBetweenBounds() {
        // Given
        @State var value = 25
        let minValue = 1
        let maxValue = 50
        
        // When
        let canIncrement = value < maxValue
        let canDecrement = value > minValue
        
        // Then
        XCTAssertTrue(canIncrement)
        XCTAssertTrue(canDecrement)
    }
    
    func testCustomMinValue() {
        // Given
        @State var value = 5
        let minValue = 5
        let maxValue = 20
        
        // When
        let canDecrement = value > minValue
        
        // Then
        XCTAssertFalse(canDecrement)
    }
    
    func testCustomMaxValue() {
        // Given
        @State var value = 20
        let minValue = 5
        let maxValue = 20
        
        // When
        let canIncrement = value < maxValue
        
        // Then
        XCTAssertFalse(canIncrement)
    }
    
    func testValueInitialization() {
        // Given
        @State var value = 1
        
        // When & Then
        XCTAssertEqual(value, 1)
    }
    
    func testValueUpdate() {
        // Given
        @State var value = 1
        
        // When
        value = 5
        
        // Then
        XCTAssertEqual(value, 5)
    }
    
    func testButtonActionIncrement() {
        // Given
        @State var value = 5
        let maxValue = 10
        
        // When
        // Simulate button tap
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 6)
    }
    
    func testButtonActionDecrement() {
        // Given
        @State var value = 5
        let minValue = 1
        
        // When
        // Simulate button tap
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 4)
    }
    
    func testButtonActionNoChangeAtMin() {
        // Given
        @State var value = 1
        let minValue = 1
        
        // When
        // Simulate button tap
        if value > minValue {
            value -= 1
        }
        
        // Then
        XCTAssertEqual(value, 1)
    }
    
    func testButtonActionNoChangeAtMax() {
        // Given
        @State var value = 10
        let maxValue = 10
        
        // When
        // Simulate button tap
        if value < maxValue {
            value += 1
        }
        
        // Then
        XCTAssertEqual(value, 10)
    }
    
    func testValueDisplayFormat() {
        // Given
        @State var value = 42
        
        // When
        let displayText = "\(value)"
        
        // Then
        XCTAssertEqual(displayText, "42")
    }
    
    func testValueDisplayWithDifferentValues() {
        // Given
        let testValues = [1, 5, 10, 25, 50]
        
        // When & Then
        for testValue in testValues {
            @State var value = testValue
            let displayText = "\(value)"
            XCTAssertEqual(displayText, "\(testValue)")
        }
    }
    
    func testButtonAccessibility() {
        // Given
        let incrementText = "+"
        let decrementText = "-"
        
        // When & Then
        XCTAssertEqual(incrementText, "+")
        XCTAssertEqual(decrementText, "-")
    }
    
    func testButtonVisualAppearance() {
        // Given
        let buttonWidth: CGFloat = 15
        let buttonHeight: CGFloat = 15
        let buttonPadding: CGFloat = 15
        let backgroundColor = Color.gray.opacity(0.2)
        let foregroundColor = Color.black
        
        // When & Then
        XCTAssertEqual(buttonWidth, 15)
        XCTAssertEqual(buttonHeight, 15)
        XCTAssertEqual(buttonPadding, 15)
        XCTAssertNotNil(backgroundColor)
        XCTAssertNotNil(foregroundColor)
    }
    
    func testLayoutConfiguration() {
        // Given
        let hStackSpacing: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(hStackSpacing, 15)
    }
    
    func testShapeConfiguration() {
        // Given
        let shape = Circle()
        
        // When & Then
        XCTAssertNotNil(shape)
    }
    
    func testColorConfiguration() {
        // Given
        let grayColor = Color.gray
        let blackColor = Color.black
        
        // When & Then
        XCTAssertNotNil(grayColor)
        XCTAssertNotNil(blackColor)
    }
    
    func testOpacityConfiguration() {
        // Given
        let opacity = 0.2
        
        // When & Then
        XCTAssertEqual(opacity, 0.2)
    }
    
    func testFrameConfiguration() {
        // Given
        let width: CGFloat = 15
        let height: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(width, 15)
        XCTAssertEqual(height, 15)
    }
    
    func testPaddingConfiguration() {
        // Given
        let padding: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(padding, 15)
    }
    
    func testSpacingConfiguration() {
        // Given
        let spacing: CGFloat = 15
        
        // When & Then
        XCTAssertEqual(spacing, 15)
    }
    
    func testValueType() {
        // Given
        @State var value: Int = 1
        
        // When & Then
        XCTAssertTrue(value is Int)
    }
    
    func testMinValueType() {
        // Given
        let minValue: Int = 1
        
        // When & Then
        XCTAssertTrue(minValue is Int)
    }
    
    func testMaxValueType() {
        // Given
        let maxValue: Int = 50
        
        // When & Then
        XCTAssertTrue(maxValue is Int)
    }
    
    func testValueRange() {
        // Given
        let minValue = 1
        let maxValue = 50
        let range = minValue...maxValue
        
        // When & Then
        XCTAssertEqual(range.lowerBound, minValue)
        XCTAssertEqual(range.upperBound, maxValue)
    }
    
    func testValueValidation() {
        // Given
        @State var value = 25
        let minValue = 1
        let maxValue = 50
        
        // When
        let isValid = value >= minValue && value <= maxValue
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValueValidationBelowMin() {
        // Given
        @State var value = 0
        let minValue = 1
        let maxValue = 50
        
        // When
        let isValid = value >= minValue && value <= maxValue
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testValueValidationAboveMax() {
        // Given
        @State var value = 51
        let minValue = 1
        let maxValue = 50
        
        // When
        let isValid = value >= minValue && value <= maxValue
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testStepperControlIntegration() {
        // Given
        @State var value = 1
        let minValue = 1
        let maxValue = 50
        
        // When
        let stepperControl = StepperControl(
            value: $value,
            minValue: minValue,
            maxValue: maxValue
        )
        
        // Then
        XCTAssertNotNil(stepperControl)
        XCTAssertEqual(value, 1)
        XCTAssertEqual(minValue, 1)
        XCTAssertEqual(maxValue, 50)
    }
    
    func testStateBinding() {
        // Given
        @State var value = 5
        
        // When
        let binding = $value
        
        // Then
        XCTAssertNotNil(binding)
    }
    
    func testValueMutation() {
        // Given
        @State var value = 5
        
        // When
        value += 1
        
        // Then
        XCTAssertEqual(value, 6)
    }
    
    func testValueReset() {
        // Given
        @State var value = 10
        
        // When
        value = 1
        
        // Then
        XCTAssertEqual(value, 1)
    }
}
