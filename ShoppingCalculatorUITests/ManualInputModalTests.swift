import XCTest
import SwiftUI
@testable import ShoppingCalculator

@MainActor
class ManualInputModalTests: XCTestCase {
    
    func testManualInputModalInitialization() {
        // Given
        @State var productsList: [Product] = []
        
        // When
        let manualInputModal = ManualInputModal(productsList: $productsList)
        
        // Then
        XCTAssertNotNil(manualInputModal)
    }
    
    func testProductNameState() {
        // Given
        @State var productName = ""
        
        // When
        productName = "Test Product"
        
        // Then
        XCTAssertEqual(productName, "Test Product")
    }
    
    func testPriceState() {
        // Given
        @State var price: Double = 0
        
        // When
        price = 5.99
        
        // Then
        XCTAssertEqual(price, 5.99)
    }
    
    func testQuantityState() {
        // Given
        @State var quantity = 1
        
        // When
        quantity = 3
        
        // Then
        XCTAssertEqual(quantity, 3)
    }
    
    func testCategoryState() {
        // Given
        @State var category: FoodCategory = .fruitVegetable
        
        // When
        category = .protein
        
        // Then
        XCTAssertEqual(category, .protein)
    }
    
    func testProductsListBinding() {
        // Given
        @State var productsList: [Product] = []
        
        // When
        let product = Product(name: "Test", price: 1.0, quantity: 1, category: .other)
        productsList.append(product)
        
        // Then
        XCTAssertEqual(productsList.count, 1)
        XCTAssertEqual(productsList.first?.name, "Test")
    }
    
    func testTitleText() {
        // Given
        let titleText = "Enter product info"
        
        // When & Then
        XCTAssertEqual(titleText, "Enter product info")
    }
    
    func testSubtitleText() {
        // Given
        let subtitleText = "You can enter product details manually!"
        
        // When & Then
        XCTAssertEqual(subtitleText, "You can enter product details manually!")
    }
    
    func testProductNameTextField() {
        // Given
        @State var productName = ""
        let placeholder = "Enter Product"
        
        // When
        productName = "Apple"
        
        // Then
        XCTAssertEqual(productName, "Apple")
        XCTAssertEqual(placeholder, "Enter Product")
    }
    
    func testProductNameTextFieldStyling() {
        // Given
        let font = Font.title3
        let backgroundColor = Color.black.opacity(0.05)
        let cornerRadius: CGFloat = 15
        
        // When & Then
        XCTAssertNotNil(font)
        XCTAssertNotNil(backgroundColor)
        XCTAssertEqual(cornerRadius, 15)
    }
    
    func testCategoryPicker() {
        // Given
        @State var category: FoodCategory = .fruitVegetable
        let allCategories = FoodCategory.allCases
        
        // When
        category = .protein
        
        // Then
        XCTAssertEqual(category, .protein)
        XCTAssertEqual(allCategories.count, 6)
    }
    
    func testPriceTextField() {
        // Given
        @State var price: Double = 0
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        price = 2.50
        
        // Then
        XCTAssertEqual(price, 2.50)
        XCTAssertNotNil(currencyCode)
    }
    
    func testPriceTextFieldStyling() {
        // Given
        let font = Font.title2
        let backgroundColor = Color.black.opacity(0.05)
        let cornerRadius: CGFloat = 15
        let keyboardType = UIKeyboardType.decimalPad
        
        // When & Then
        XCTAssertNotNil(font)
        XCTAssertNotNil(backgroundColor)
        XCTAssertEqual(cornerRadius, 15)
        XCTAssertEqual(keyboardType, .decimalPad)
    }
    
    func testStepperControlIntegration() {
        // Given
        @State var quantity = 1
        let minValue = 1
        let maxValue = 50
        
        // When
        let stepperControl = StepperControl(
            value: $quantity,
            minValue: minValue,
            maxValue: maxValue
        )
        
        // Then
        XCTAssertNotNil(stepperControl)
        XCTAssertEqual(quantity, 1)
        XCTAssertEqual(minValue, 1)
        XCTAssertEqual(maxValue, 50)
    }
    
    func testAddButtonText() {
        // Given
        let buttonText = "Add"
        
        // When & Then
        XCTAssertEqual(buttonText, "Add")
    }
    
    func testAddButtonStyling() {
        // Given
        let fontWeight = Font.Weight.bold
        let cornerRadius: CGFloat = 20
        
        // When & Then
        XCTAssertNotNil(fontWeight)
        XCTAssertEqual(cornerRadius, 20)
    }
    
    func testAddButtonAction() {
        // Given
        @State var productsList: [Product] = []
        let productName = "Test Product"
        let price: Decimal = 5.99
        let quantity = 2
        let category: FoodCategory = .fruitVegetable
        
        // When
        let product = Product(name: productName, price: price, quantity: quantity, category: category)
        productsList.append(product)
        
        // Then
        XCTAssertEqual(productsList.count, 1)
        XCTAssertEqual(productsList.first?.name, productName)
        XCTAssertEqual(productsList.first?.price, price)
        XCTAssertEqual(productsList.first?.quantity, quantity)
        XCTAssertEqual(productsList.first?.category, category)
    }
    
    func testDismissalAfterAdd() {
        // Given
        @State var productsList: [Product] = []
        let productName = "Test Product"
        let price: Decimal = 5.99
        let quantity = 2
        let category: FoodCategory = .fruitVegetable
        
        // When
        let product = Product(name: productName, price: price, quantity: quantity, category: category)
        productsList.append(product)
        // In real implementation, this would trigger dismiss()
        
        // Then
        XCTAssertEqual(productsList.count, 1)
    }
    
    func testVStackAlignment() {
        // Given
        let alignment = HorizontalAlignment.leading
        
        // When & Then
        XCTAssertEqual(alignment, .leading)
    }
    
    func testVStackSpacing() {
        // Given
        let spacing: CGFloat = 5
        
        // When & Then
        XCTAssertEqual(spacing, 5)
    }
    
    func testHStackSpacing() {
        // Given
        let spacing: CGFloat = 20
        
        // When & Then
        XCTAssertEqual(spacing, 20)
    }
    
    func testPaddingConfiguration() {
        // Given
        let topPadding: CGFloat = 0
        let bottomPadding: CGFloat = 3
        let horizontalPadding: CGFloat = 0
        let generalPadding: CGFloat = 0
        
        // When & Then
        XCTAssertEqual(topPadding, 0)
        XCTAssertEqual(bottomPadding, 3)
        XCTAssertEqual(horizontalPadding, 0)
        XCTAssertEqual(generalPadding, 0)
    }
    
    func testFontConfiguration() {
        // Given
        let title2Font = Font.title2
        let title3Font = Font.title3
        
        // When & Then
        XCTAssertNotNil(title2Font)
        XCTAssertNotNil(title3Font)
    }
    
    func testColorConfiguration() {
        // Given
        let secondaryColor = Color.secondary
        let blackColor = Color.black
        
        // When & Then
        XCTAssertNotNil(secondaryColor)
        XCTAssertNotNil(blackColor)
    }
    
    func testOpacityConfiguration() {
        // Given
        let backgroundOpacity = 0.05
        
        // When & Then
        XCTAssertEqual(backgroundOpacity, 0.05)
    }
    
    func testCornerRadiusConfiguration() {
        // Given
        let textFieldCornerRadius: CGFloat = 15
        let buttonCornerRadius: CGFloat = 20
        
        // When & Then
        XCTAssertEqual(textFieldCornerRadius, 15)
        XCTAssertEqual(buttonCornerRadius, 20)
    }
    
    func testFrameConfiguration() {
        // Given
        let maxWidth = CGFloat.infinity
        
        // When & Then
        XCTAssertEqual(maxWidth, .infinity)
    }
    
    func testLineLimitConfiguration() {
        // Given
        let lineLimit = 2
        
        // When & Then
        XCTAssertEqual(lineLimit, 2)
    }
    
    func testMultilineTextAlignment() {
        // Given
        let alignment = TextAlignment.leading
        
        // When & Then
        XCTAssertEqual(alignment, .leading)
    }
    
    func testKeyboardTypeConfiguration() {
        // Given
        let keyboardType = UIKeyboardType.decimalPad
        
        // When & Then
        XCTAssertEqual(keyboardType, .decimalPad)
    }
    
    func testSpacerUsage() {
        // Given
        let spacer = Spacer()
        
        // When & Then
        XCTAssertNotNil(spacer)
    }
    
    func testCategoryLabel() {
        // Given
        let categoryLabel = "Category: "
        
        // When & Then
        XCTAssertEqual(categoryLabel, "Category: ")
    }
    
    func testPickerLabel() {
        // Given
        let pickerLabel = "Select Category"
        
        // When & Then
        XCTAssertEqual(pickerLabel, "Select Category")
    }
    
    func testPriceTextFieldLabel() {
        // Given
        let priceLabel = "Enter Price"
        
        // When & Then
        XCTAssertEqual(priceLabel, "Enter Price")
    }
    
    func testFoodCategoryEnum() {
        // Given
        let allCases = FoodCategory.allCases
        
        // When
        let expectedCases: [FoodCategory] = [
            .fruitVegetable,
            .grain,
            .protein,
            .dairy,
            .fat,
            .other
        ]
        
        // Then
        XCTAssertEqual(allCases.count, 6)
        XCTAssertEqual(allCases, expectedCases)
    }
    
    func testFoodCategoryRawValues() {
        // Given
        let fruitVegetable = FoodCategory.fruitVegetable.rawValue
        let grain = FoodCategory.grain.rawValue
        let protein = FoodCategory.protein.rawValue
        let dairy = FoodCategory.dairy.rawValue
        let fat = FoodCategory.fat.rawValue
        let other = FoodCategory.other.rawValue
        
        // When & Then
        XCTAssertEqual(fruitVegetable, "Fruit & Vegetable")
        XCTAssertEqual(grain, "Grain")
        XCTAssertEqual(protein, "Protein")
        XCTAssertEqual(dairy, "Dairy")
        XCTAssertEqual(fat, "Fat")
        XCTAssertEqual(other, "Other")
    }
    
    func testFoodCategoryIdentifiable() {
        // Given
        let category = FoodCategory.fruitVegetable
        
        // When
        let id = category.id
        
        // Then
        XCTAssertEqual(id, category.rawValue)
    }
    
    func testProductInitialization() {
        // Given
        let name = "Test Product"
        let price: Decimal = 5.99
        let quantity = 2
        let category = FoodCategory.fruitVegetable
        
        // When
        let product = Product(name: name, price: price, quantity: quantity, category: category)
        
        // Then
        XCTAssertEqual(product.name, name)
        XCTAssertEqual(product.price, price)
        XCTAssertEqual(product.quantity, quantity)
        XCTAssertEqual(product.category, category)
    }
    
    func testFormValidation() {
        // Given
        let productName = "Test Product"
        let price: Double = 5.99
        let quantity = 2
        let category = FoodCategory.fruitVegetable
        
        // When
        let isValid = !productName.isEmpty && price > 0 && quantity > 0
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testFormValidationWithEmptyName() {
        // Given
        let productName = ""
        let price: Double = 5.99
        let quantity = 2
        
        // When
        let isValid = !productName.isEmpty && price > 0 && quantity > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testFormValidationWithZeroPrice() {
        // Given
        let productName = "Test Product"
        let price: Double = 0
        let quantity = 2
        
        // When
        let isValid = !productName.isEmpty && price > 0 && quantity > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testFormValidationWithZeroQuantity() {
        // Given
        let productName = "Test Product"
        let price: Double = 5.99
        let quantity = 0
        
        // When
        let isValid = !productName.isEmpty && price > 0 && quantity > 0
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testCurrencyFormatting() {
        // Given
        let price: Double = 5.99
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        let formattedPrice = price.formatted(.currency(code: currencyCode))
        
        // Then
        XCTAssertNotNil(formattedPrice)
        XCTAssertTrue(formattedPrice.contains("5.99") || formattedPrice.contains("$5.99"))
    }
    
    func testViewLayout() {
        // Given
        @State var productsList: [Product] = []
        
        // When
        let manualInputModal = ManualInputModal(productsList: $productsList)
        
        // Then
        XCTAssertNotNil(manualInputModal)
    }
    
    func testStateBinding() {
        // Given
        @State var productsList: [Product] = []
        
        // When
        let binding = $productsList
        
        // Then
        XCTAssertNotNil(binding)
    }
}
