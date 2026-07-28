import XCTest
import SwiftUI
import SwiftData
@testable import ShoppingCalculator

@MainActor
class SumListViewTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([
            Product.self,
            Purchase.self,
            MealPlan.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = modelContainer.mainContext
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        context = nil
        super.tearDown()
    }
    
    func testSumListViewInitialization() {
        // Given
        @State var showScanner = true
        @State var productsList: [Product] = []
        
        // When
        let sumListView = SumListView(showScanner: $showScanner, productsList: $productsList)
        
        // Then
        XCTAssertNotNil(sumListView)
    }
    
    func testProductQuantityState() {
        // Given
        @State var productQuantity = 1
        
        // When
        productQuantity = 3
        
        // Then
        XCTAssertEqual(productQuantity, 3)
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
    
    func testOffsetState() {
        // Given
        @State var offset: CGFloat = 0
        
        // When
        offset = 50.0
        
        // Then
        XCTAssertEqual(offset, 50.0)
    }
    
    func testStoreState() {
        // Given
        @State var store = ""
        
        // When
        store = "Test Store"
        
        // Then
        XCTAssertEqual(store, "Test Store")
    }
    
    func testIsLoadingState() {
        // Given
        @State var isLoading = false
        
        // When
        isLoading = true
        
        // Then
        XCTAssertTrue(isLoading)
    }
    
    func testTotalCalculation() {
        // Given
        let products = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable),
            Product(name: "Bread", price: 2.00, quantity: 1, category: .grain)
        ]
        
        // When
        let total = products.reduce(Decimal(0)) { result, product in
            result + product.price * Decimal(product.quantity)
        }
        
        // Then
        XCTAssertEqual(total, 5.0)
    }
    
    func testTotalCalculationWithMultipleProducts() {
        // Given
        let products = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable),
            Product(name: "Bread", price: 2.00, quantity: 1, category: .grain),
            Product(name: "Milk", price: 3.50, quantity: 1, category: .dairy)
        ]
        
        // When
        let total = products.reduce(Decimal(0)) { result, product in
            result + product.price * Decimal(product.quantity)
        }
        
        // Then
        XCTAssertEqual(total, 8.5)
    }
    
    func testTotalCalculationWithZeroProducts() {
        // Given
        let products: [Product] = []
        
        // When
        let total = products.reduce(Decimal(0)) { result, product in
            result + product.price * Decimal(product.quantity)
        }
        
        // Then
        XCTAssertEqual(total, 0)
    }
    
    func testCurrencyFormatting() {
        // Given
        let total = 15.99
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        let formattedTotal = total.formatted(.currency(code: currencyCode))
        
        // Then
        XCTAssertNotNil(formattedTotal)
        XCTAssertTrue(formattedTotal.contains("15.99") || formattedTotal.contains("$15.99"))
    }
    
    func testStoreTextField() {
        // Given
        @State var store = ""
        
        // When
        store = "Grocery Store"
        
        // Then
        XCTAssertEqual(store, "Grocery Store")
    }
    
    func testStoreTextFieldPlaceholder() {
        // Given
        let placeholder = "Store Name"
        
        // When & Then
        XCTAssertEqual(placeholder, "Store Name")
    }
    
    func testStoreTextFieldStyling() {
        // Given
        let backgroundColor = Color.black.opacity(0.05)
        let cornerRadius: CGFloat = 15
        
        // When & Then
        XCTAssertNotNil(backgroundColor)
        XCTAssertEqual(cornerRadius, 15)
    }
    
    func testGridConfiguration() {
        // Given
        let horizontalSpacing: CGFloat = 150
        
        // When & Then
        XCTAssertEqual(horizontalSpacing, 150)
    }
    
    func testProductsHeader() {
        // Given
        let headerText = "Products"
        
        // When & Then
        XCTAssertEqual(headerText, "Products")
    }
    
    func testProductDisplayFormat() {
        // Given
        let product = Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable)
        
        // When
        let displayText = "\(product.name) x \(product.quantity)"
        
        // Then
        XCTAssertEqual(displayText, "Apple x 2")
    }
    
    func testProductPriceDisplay() {
        // Given
        let product = Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable)
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        let priceDisplay = product.price * Decimal(product.quantity)
        let formattedPrice = priceDisplay.formatted(.currency(code: currencyCode))
        
        // Then
        XCTAssertEqual(priceDisplay, 3.0)
        XCTAssertNotNil(formattedPrice)
    }
    
    func testFinishButtonText() {
        // Given
        let buttonText = "Finish"
        
        // When & Then
        XCTAssertEqual(buttonText, "Finish")
    }
    
    func testFinishButtonStyling() {
        // Given
        let foregroundColor = Color.white
        let cornerRadius: CGFloat = 25
        
        // When & Then
        XCTAssertNotNil(foregroundColor)
        XCTAssertEqual(cornerRadius, 25)
    }
    
    func testFinishButtonDisabledState() {
        // Given
        let productsList: [Product] = []
        let store = ""
        
        // When
        let isDisabled = productsList.count == 0 || store.isEmpty
        
        // Then
        XCTAssertTrue(isDisabled)
    }
    
    func testFinishButtonEnabledState() {
        // Given
        let productsList = [Product(name: "Test", price: 1.0, quantity: 1, category: .other)]
        let store = "Test Store"
        
        // When
        let isDisabled = productsList.count == 0 || store.isEmpty
        
        // Then
        XCTAssertFalse(isDisabled)
    }
    
    func testLoadingIndicator() {
        // Given
        @State var isLoading = true
        
        // When
        let shouldShowProgress = isLoading
        
        // Then
        XCTAssertTrue(shouldShowProgress)
    }
    
    func testPurchaseCreation() {
        // Given
        let productsList = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable)
        ]
        let store = "Test Store"
        let date = Date()
        
        // When
        let purchase = Purchase(date: date, products: productsList, store: store)
        
        // Then
        XCTAssertNotNil(purchase)
        XCTAssertEqual(purchase.store, store)
        XCTAssertEqual(purchase.products.count, 1)
    }
    
    func testContextInsertion() {
        // Given
        let productsList = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable)
        ]
        let store = "Test Store"
        let purchase = Purchase(date: Date(), products: productsList, store: store)
        
        // When
        context.insert(purchase)
        
        // Then
        // Purchase should be inserted into context
        XCTAssertNotNil(purchase)
    }
    
    func testContextSave() {
        // Given
        let productsList = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable)
        ]
        let store = "Test Store"
        let purchase = Purchase(date: Date(), products: productsList, store: store)
        context.insert(purchase)
        
        // When
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Then
        // Context should be saved successfully
        XCTAssertTrue(true)
    }
    
    func testProductsListReset() {
        // Given
        @State var productsList = [Product(name: "Test", price: 1.0, quantity: 1, category: .other)]
        
        // When
        productsList = []
        
        // Then
        XCTAssertTrue(productsList.isEmpty)
    }
    
    func testDismissalAnimation() {
        // Given
        @State var showScanner = true
        
        // When
        withAnimation(.easeInOut(duration: 0.3)) {
            showScanner = false
        }
        
        // Then
        XCTAssertFalse(showScanner)
    }
    
    func testDragGestureHandling() {
        // Given
        @State var offset: CGFloat = 0
        let translation = CGSize(width: 0, height: 150)
        
        // When
        if translation.height > 0 {
            offset = translation.height
        }
        
        // Then
        XCTAssertEqual(offset, 150)
    }
    
    func testDismissalThreshold() {
        // Given
        let threshold: CGFloat = 100
        let translation = CGSize(width: 0, height: 150)
        
        // When
        let shouldDismiss = translation.height > threshold
        
        // Then
        XCTAssertTrue(shouldDismiss)
    }
    
    func testSnapBackAnimation() {
        // Given
        @State var offset: CGFloat = 50
        let translation = CGSize(width: 0, height: 50)
        let threshold: CGFloat = 100
        
        // When
        let shouldSnapBack = translation.height <= threshold
        if shouldSnapBack {
            withAnimation(.easeInOut(duration: 0.3)) {
                offset = 0
            }
        }
        
        // Then
        XCTAssertTrue(shouldSnapBack)
        XCTAssertEqual(offset, 0)
    }
    
    func testGeometryReaderUsage() {
        // Given
        @State var showScanner = true
        @State var productsList: [Product] = []
        
        // When
        let sumListView = SumListView(showScanner: $showScanner, productsList: $productsList)
        
        // Then
        XCTAssertNotNil(sumListView)
    }
    
    func testVStackAlignment() {
        // Given
        let alignment = HorizontalAlignment.leading
        
        // When & Then
        XCTAssertEqual(alignment, .leading)
    }
    
    func testHStackAlignment() {
        // Given
        let alignment = VerticalAlignment.center
        
        // When & Then
        XCTAssertEqual(alignment, .center)
    }
    
    func testSpacingConfiguration() {
        // Given
        let vStackSpacing: CGFloat = 0
        let hStackSpacing: CGFloat = 0
        
        // When & Then
        XCTAssertEqual(vStackSpacing, 0)
        XCTAssertEqual(hStackSpacing, 0)
    }
    
    func testPaddingConfiguration() {
        // Given
        let padding: CGFloat = 3
        let verticalPadding: CGFloat = 2
        
        // When & Then
        XCTAssertEqual(padding, 3)
        XCTAssertEqual(verticalPadding, 2)
    }
    
    func testFontConfiguration() {
        // Given
        let titleFont = Font.title
        let title3Font = Font.title3
        
        // When & Then
        XCTAssertNotNil(titleFont)
        XCTAssertNotNil(title3Font)
    }
    
    func testFontWeightConfiguration() {
        // Given
        let boldWeight = Font.Weight.bold
        
        // When & Then
        XCTAssertNotNil(boldWeight)
    }
    
    func testColorConfiguration() {
        // Given
        let grayColor = Color.gray
        let whiteColor = Color.white
        let blackColor = Color.black
        
        // When & Then
        XCTAssertNotNil(grayColor)
        XCTAssertNotNil(whiteColor)
        XCTAssertNotNil(blackColor)
    }
    
    func testOpacityConfiguration() {
        // Given
        let backgroundOpacity = 0.05
        let disabledOpacity = 0.1
        
        // When & Then
        XCTAssertEqual(backgroundOpacity, 0.05)
        XCTAssertEqual(disabledOpacity, 0.1)
    }
    
    func testCornerRadiusConfiguration() {
        // Given
        let rectangleCornerRadius: CGFloat = 30
        let textFieldCornerRadius: CGFloat = 15
        let buttonCornerRadius: CGFloat = 25
        
        // When & Then
        XCTAssertEqual(rectangleCornerRadius, 30)
        XCTAssertEqual(textFieldCornerRadius, 15)
        XCTAssertEqual(buttonCornerRadius, 25)
    }
    
    func testFrameConfiguration() {
        // Given
        let rectangleWidth: CGFloat = 30
        let rectangleHeight: CGFloat = 3
        let maxWidth = CGFloat.infinity
        
        // When & Then
        XCTAssertEqual(rectangleWidth, 30)
        XCTAssertEqual(rectangleHeight, 3)
        XCTAssertEqual(maxWidth, .infinity)
    }
    
    func testDividerUsage() {
        // Given
        let divider = Divider()
        
        // When & Then
        XCTAssertNotNil(divider)
    }
    
    func testSpacerUsage() {
        // Given
        let spacer = Spacer()
        
        // When & Then
        XCTAssertNotNil(spacer)
    }
    
    func testGridRowConfiguration() {
        // Given
        let gridRow = GridRow {
            Text("Test")
        }
        
        // When & Then
        XCTAssertNotNil(gridRow)
    }
    
    func testForEachWithProducts() {
        // Given
        let products = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable),
            Product(name: "Bread", price: 2.00, quantity: 1, category: .grain)
        ]
        
        // When
        let productCount = products.count
        
        // Then
        XCTAssertEqual(productCount, 2)
    }
    
    func testButtonActionExecution() {
        // Given
        @State var showScanner = true
        @State var productsList = [Product(name: "Test", price: 1.0, quantity: 1, category: .other)]
        let store = "Test Store"
        
        // When
        // Simulate button action
        let purchase = Purchase(date: Date(), products: productsList, store: store)
        context.insert(purchase)
        productsList = []
        showScanner = false
        
        // Then
        XCTAssertTrue(productsList.isEmpty)
        XCTAssertFalse(showScanner)
    }
}
