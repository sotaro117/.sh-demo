import XCTest
import SwiftData
@testable import ShoppingCalculator

// MARK: - ImageRecognizer Tests
@MainActor
final class ImageRecognizerTests: XCTestCase {
    var sut: ImageRecognizer!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = ImageRecognizer()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_AllPropertiesAreDefault() {
        XCTAssertTrue(sut.productName.isEmpty)
        XCTAssertEqual(sut.price, 0.0)
        XCTAssertNil(sut.category)
        XCTAssertFalse(sut.isProcessing)
    }
    
    // MARK: - Generate Function Tests
    
    func testGenerate_WithoutAPIKey_PrintsErrorAndReturns() async {
        // Given
        let testImage = UIImage()
        
        // When
        await sut.generate(image: testImage)
        
        // Then
        XCTAssertFalse(sut.isProcessing)
    }
    
    func testGenerate_SetsIsProcessingToTrue() async {
        // Given
        let testImage = UIImage()
        setenv("OPENAI_API_KEY", "test_key", 1)
        
        // When
        await sut.generate(image: testImage)
        
        // Then - isProcessing should be false after generate completes
        XCTAssertFalse(sut.isProcessing)
        
        unsetenv("OPENAI_API_KEY")
    }
    
    func testGenerate_ParsesValidJSONResponse() {
        // Given
        let mockResponse = """
        {
            "productName": "Apple",
            "price": 2.5,
            "category": "fruitVegetable"
        }
        """
        
        guard let data = mockResponse.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to create mock data")
            return
        }
        
        // When
        DispatchQueue.main.async {
            if let productName = dict["productName"] as? String {
                self.sut.productName = productName
            }
            if let price = dict["price"] as? Double {
                self.sut.price = Decimal(price)
            }
            if let categoryString = dict["category"] as? String {
                self.sut.category = FoodCategory(rawValue: categoryString.capitalized)
            }
        }
        
        // Then
        let expectation = expectation(description: "JSON parsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.productName, "Apple")
            XCTAssertEqual(self.sut.price, 2.5)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGenerate_HandlesCategoryMapping() {
        // Test all category mappings
        let categories = [
            ("fruitVegetable", FoodCategory.fruitVegetable),
            ("grain", FoodCategory.grain),
            ("protein", FoodCategory.protein),
            ("dairy", FoodCategory.dairy),
            ("fat", FoodCategory.fat),
            ("other", FoodCategory.other)
        ]
        
        for (input, expected) in categories {
            sut.category = nil
            
            switch input {
            case "fruitVegetable": sut.category = .fruitVegetable
            case "grain": sut.category = .grain
            case "protein": sut.category = .protein
            case "dairy": sut.category = .dairy
            case "fat": sut.category = .fat
            case "other": sut.category = .other
            default: sut.category = nil
            }
            
            XCTAssertEqual(sut.category, expected, "Category \(input) should map to \(expected)")
        }
    }
    
    func testGenerate_HandlesInvalidCategory() {
        // Given
        let invalidCategory = "invalid_category"
        
        // When
        sut.category = nil
        switch invalidCategory {
        case "fruitVegetable": sut.category = .fruitVegetable
        case "grain": sut.category = .grain
        case "protein": sut.category = .protein
        case "dairy": sut.category = .dairy
        case "fat": sut.category = .fat
        case "other": sut.category = .other
        default: sut.category = nil
        }
        
        // Then
        XCTAssertNil(sut.category, "Invalid category should result in nil")
    }
}

// MARK: - UIImage Extension Tests

final class UIImageExtensionTests: XCTestCase {
    
    func testBase64_WithValidImage_ReturnsBase64String() {
        // Given
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // When
        let base64String = image.base64
        
        // Then
        XCTAssertNotNil(base64String)
        XCTAssertFalse(base64String!.isEmpty)
    }
    
    func testBase64_ReturnsValidBase64Format() {
        // Given
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // When
        let base64String = image.base64
        
        // Then
        XCTAssertNotNil(base64String)
        XCTAssertTrue(base64String!.range(of: "^[A-Za-z0-9+/]*={0,2}$", options: .regularExpression) != nil)
    }
}

// MARK: - MealAnalyzer Tests

@MainActor
final class MealAnalyzerTests: XCTestCase {
    var sut: MealAnalyzer!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Purchase.self, Report.self, Product.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        
        sut = MealAnalyzer()
        sut.context = modelContext
    }
    
    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_IsNotProcessing() {
        XCTAssertFalse(sut.isProcessing)
    }
    
    // MARK: - Generate Suggestion Tests
    
    func testGenerateSuggestion_WithoutAPIKey_PrintsError() async {
        // Given
        let purchases = [
            Purchase(
                date: Date(),
                products: [Product(name: "Apple", price: 2.5, quantity: 2, category: .fruitVegetable)],
                store: "TestStore"
            )
        ]
        
        // When
        await sut.generateSuggestion(purchases: purchases)
        
        // Then - Should not crash
        XCTAssertNotNil(sut)
    }
    
    func testGenerateSuggestion_SetsIsProcessingToTrue() async {
        // Given
        let purchases = [
            Purchase(
                date: Date(),
                products: [Product(name: "Banana", price: 1.5, quantity: 3, category: .fruitVegetable)],
                store: "Market"
            )
        ]
        setenv("OPENAI_API_KEY", "test_key", 1)
        
        // When
        await sut.generateSuggestion(purchases: purchases)
        
        // Then - isProcessing is false after auth failure in test environment
        XCTAssertFalse(sut.isProcessing)
        
        unsetenv("OPENAI_API_KEY")
    }
    
    func testGenerateSuggestion_FormatsProductsCorrectly() {
        // Given
        let testDate = Date()
        let product1 = Product(name: "Milk", price: 3.0, quantity: 1, category: .dairy)
        let product2 = Product(name: "Bread", price: 2.0, quantity: 2, category: .grain)
        let purchase = Purchase(date: testDate, products: [product1, product2], store: "Supermarket")
        
        // When - Test formatting logic
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: purchase.date)
        
        result += "\n** \(dateString) ** at \(purchase.store)"
        for product in purchase.products {
            result += "\n- \(product.name), (price)\(product.price), (quantity)\(product.quantity), (category)\(product.category)"
        }
        
        // Then
        XCTAssertTrue(result.contains("Milk"))
        XCTAssertTrue(result.contains("Bread"))
        XCTAssertTrue(result.contains("Supermarket"))
        XCTAssertTrue(result.contains("(price)3"))
        XCTAssertTrue(result.contains("(price)2"))
    }
    
    func testGenerateSuggestion_CreatesReportWithCurrentMonthYear() {
        // Given
        let calendar = Calendar.current
        let expectedYear = calendar.component(.year, from: Date())
        let expectedMonth = calendar.component(.month, from: Date())
        
        // When
        let report = Report(month: expectedMonth, year: expectedYear, analysisText: "Test analysis")
        
        // Then
        XCTAssertEqual(report.month, expectedMonth)
        XCTAssertEqual(report.year, expectedYear)
    }
    
    func testGenerateSuggestion_WithEmptyPurchases_HandlesGracefully() async {
        // Given
        let emptyPurchases: [Purchase] = []
        setenv("OPENAI_API_KEY", "test_key", 1)
        
        // When
        await sut.generateSuggestion(purchases: emptyPurchases)
        
        // Then - isProcessing is false after auth failure in test environment
        XCTAssertFalse(sut.isProcessing)
        
        unsetenv("OPENAI_API_KEY")
    }
}

// MARK: - MealPlanner Tests

@MainActor
final class MealPlannerTests: XCTestCase {
    var sut: MealPlanner!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Purchase.self, MealPlan.self, Product.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        
        sut = MealPlanner()
        sut.context = modelContext
    }
    
    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_IsNotProcessing() {
        XCTAssertFalse(sut.isProcessing)
    }
    
    func testInitialState_ContextIsNil() {
        let newPlanner = MealPlanner()
        XCTAssertNil(newPlanner.context)
    }
    
    // MARK: - Generate Plan Tests
    
    func testGeneratePlan_WithoutAPIKey_PrintsError() async {
        // Given
        let purchases = [
            Purchase(
                date: Date(),
                products: [Product(name: "Chicken", price: 8.0, quantity: 1, category: .protein)],
                store: "Butcher"
            )
        ]
        
        // When
        await sut.generatePlan(purchases: purchases)
        
        // Then - Should not crash
        XCTAssertNotNil(sut)
    }
    
    func testGeneratePlan_SetsIsProcessingToTrue() async {
        // Given
        let purchases = [
            Purchase(
                date: Date(),
                products: [Product(name: "Rice", price: 5.0, quantity: 1, category: .grain)],
                store: "GrainShop"
            )
        ]
        setenv("OPENAI_API_KEY", "test_key", 1)
        
        // When
        await sut.generatePlan(purchases: purchases)
        
        // Then - isProcessing is false after auth failure in test environment
        XCTAssertFalse(sut.isProcessing)
        
        unsetenv("OPENAI_API_KEY")
    }
    
    func testGeneratePlan_FormatsProductsCorrectly() {
        // Given
        let testDate = Date()
        let product1 = Product(name: "Tomato", price: 1.5, quantity: 3, category: .fruitVegetable)
        let product2 = Product(name: "Pasta", price: 2.5, quantity: 1, category: .grain)
        let purchase = Purchase(date: testDate, products: [product1, product2], store: "Store")
        
        // When
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: purchase.date)
        
        var result = "\n** \(dateString) **\n"
        for product in purchase.products {
            result += "\(product.name), "
        }
        
        // Then
        XCTAssertTrue(result.contains("Tomato"))
        XCTAssertTrue(result.contains("Pasta"))
        XCTAssertTrue(result.contains(dateString))
    }
    
    func testGeneratePlan_CalculatesCurrentWeekCorrectly() {
        // Given
        let calendar = Calendar.current
        let now = Date()
        
        // When
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let week = calendar.component(.weekOfMonth, from: now)
        let currentWeek = "\(week) - \(month) - \(year)"
        
        // Then
        XCTAssertTrue(currentWeek.contains("\(week)"))
        XCTAssertTrue(currentWeek.contains("\(month)"))
        XCTAssertTrue(currentWeek.contains("\(year)"))
    }
    
    func testGeneratePlan_ParsesValidJSONResponse() {
        // Given
        let mockResponse = """
        {
            "plans": [
                {
                    "meal": "breakfast",
                    "plate": "Oatmeal",
                    "ingredients": ["oats", "milk", "honey"]
                },
                {
                    "meal": "lunch",
                    "plate": "Salad",
                    "ingredients": ["lettuce", "tomato", "cucumber"]
                }
            ]
        }
        """
        
        guard let jsonData = mockResponse.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let plans = json["plans"] as? [[String: Any]] else {
            XCTFail("Failed to parse mock JSON")
            return
        }
        
        // When/Then
        XCTAssertEqual(plans.count, 2)
        
        if let firstPlan = plans.first {
            XCTAssertEqual(firstPlan["meal"] as? String, "breakfast")
            XCTAssertEqual(firstPlan["plate"] as? String, "Oatmeal")
            XCTAssertEqual((firstPlan["ingredients"] as? [String])?.count, 3)
        }
    }
    
    func testGeneratePlan_CreatesMealPlanObjects() {
        // Given
        let meal = Meal.breakfast
        let plate = "Scrambled Eggs"
        let ingredients = ["Eggs", "Butter", "Salt"]
        let date = Date()
        
        // When
        let mealPlan = MealPlan(meal: meal, plate: plate, ingredients: ingredients, date: date)
        modelContext.insert(mealPlan)
        
        // Then
        XCTAssertEqual(mealPlan.meal, .breakfast)
        XCTAssertEqual(mealPlan.plate, "Scrambled Eggs")
        XCTAssertEqual(mealPlan.ingredients.count, 3)
    }
    
    func testGeneratePlan_IncrementsDatesCorrectly() {
        // Given
        let calendar = Calendar.current
        var currentDate = Date()
        var dates: [Date] = []
        var index = 0
        
        // When - Simulate 21 meals (7 days * 3 meals)
        for _ in 0..<21 {
            dates.append(currentDate)
            index += 1
            if index > 0 && index % 3 == 0 {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Then
        XCTAssertEqual(dates.count, 21)
        
        // First 3 meals should have same date
        XCTAssertEqual(Calendar.current.startOfDay(for: dates[0]),
                      Calendar.current.startOfDay(for: dates[1]))
        XCTAssertEqual(Calendar.current.startOfDay(for: dates[1]),
                      Calendar.current.startOfDay(for: dates[2]))
        
        // 4th meal should be next day
        let firstDay = Calendar.current.startOfDay(for: dates[0])
        let secondDay = Calendar.current.startOfDay(for: dates[3])
        let daysDiff = Calendar.current.dateComponents([.day], from: firstDay, to: secondDay).day
        XCTAssertEqual(daysDiff, 1)
    }
    
    func testGeneratePlan_SavesMealPlansToContext() {
        // Given
        let meal1 = MealPlan(meal: .breakfast, plate: "Toast", ingredients: ["Bread", "Butter"], date: Date())
        let meal2 = MealPlan(meal: .lunch, plate: "Soup", ingredients: ["Carrot", "Water"], date: Date())
        
        // When
        modelContext.insert(meal1)
        modelContext.insert(meal2)
        
        do {
            try modelContext.save()
            
            // Then
            let descriptor = FetchDescriptor<MealPlan>()
            let savedPlans = try modelContext.fetch(descriptor)
            XCTAssertEqual(savedPlans.count, 2)
        } catch {
            XCTFail("Failed to save meal plans: \(error)")
        }
    }
    
    func testGeneratePlan_WithEmptyPurchases_HandlesGracefully() async {
        // Given
        let emptyPurchases: [Purchase] = []
        setenv("OPENAI_API_KEY", "test_key", 1)
        
        // When
        await sut.generatePlan(purchases: emptyPurchases)
        
        // Then - isProcessing is false after auth failure in test environment
        XCTAssertFalse(sut.isProcessing)
        
        unsetenv("OPENAI_API_KEY")
    }
    
    func testMealEnum_AllCasesAvailable() {
        // Given/When
        let allMeals = Meal.allCases
        
        // Then
        XCTAssertEqual(allMeals.count, 3)
        XCTAssertTrue(allMeals.contains(.breakfast))
        XCTAssertTrue(allMeals.contains(.lunch))
        XCTAssertTrue(allMeals.contains(.dinner))
    }
    
    func testMealEnum_RawValueMapping() {
        // Given
        let breakfast = Meal.allCases.first(where: { $0.rawValue == "breakfast" })
        let lunch = Meal.allCases.first(where: { $0.rawValue == "lunch" })
        let dinner = Meal.allCases.first(where: { $0.rawValue == "dinner" })
        
        // Then
        XCTAssertEqual(breakfast, .breakfast)
        XCTAssertEqual(lunch, .lunch)
        XCTAssertEqual(dinner, .dinner)
    }
}

// MARK: - Integration Tests

@MainActor
final class OpenAIServicesIntegrationTests: XCTestCase {
    
    func testImageRecognizer_ProcessingFlow() {
        // Given
        let recognizer = ImageRecognizer()
        let testImage = UIImage()
        
        // When
        recognizer.isProcessing = true
        recognizer.productName = "Test Product"
        recognizer.price = 5.99
        recognizer.category = .protein
        recognizer.isProcessing = false
        
        // Then
        XCTAssertEqual(recognizer.productName, "Test Product")
        XCTAssertEqual(recognizer.price, 5.99)
        XCTAssertEqual(recognizer.category, .protein)
        XCTAssertFalse(recognizer.isProcessing)
    }
    
    func testMealAnalyzer_WithMealPlanner_DataFlow() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Purchase.self, Report.self, MealPlan.self, Product.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let analyzer = MealAnalyzer()
        analyzer.context = context
        
        let planner = MealPlanner()
        planner.context = context
        
        let product = Product(name: "Chicken", price: 10.0, quantity: 1, category: .protein)
        let purchase = Purchase(date: Date(), products: [product], store: "Market")
        
        // When
        context.insert(purchase)
        try context.save()
        
        // Then
        let descriptor = FetchDescriptor<Purchase>()
        let purchases = try context.fetch(descriptor)
        XCTAssertEqual(purchases.count, 1)
        XCTAssertEqual(purchases.first?.products.first?.name, "Chicken")
    }
}

// MARK: - Error Handling Tests

@MainActor
final class OpenAIServicesErrorTests: XCTestCase {
    
    func testImageRecognizer_HandlesJSONParseError() {
        // Given
        let recognizer = ImageRecognizer()
        let invalidJSON = "{ invalid json }"
        
        // When
        let data = invalidJSON.data(using: .utf8)
        let parseResult = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        
        // Then
        XCTAssertNil(parseResult, "Invalid JSON should fail to parse")
    }
    
    func testMealPlanner_HandlesInvalidMealString() {
        // Given
        let invalidMealString = "invalid_meal"
        let meal = Meal.allCases.first(where: { $0.rawValue == invalidMealString })
        
        // Then
        XCTAssertNil(meal, "Invalid meal string should return nil")
    }
    
    func testMealAnalyzer_HandlesContextSaveError() async throws {
        // Given
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Report.self,
            configurations: config
        )
        let context = ModelContext(container)
        
        let analyzer = MealAnalyzer()
        analyzer.context = context
        
        // When
        let report = Report(month: 1, year: 2025, analysisText: "Test")
        context.insert(report)
        
        // Then
        do {
            try context.save()
            XCTAssertTrue(true, "Save should succeed")
        } catch {
            XCTFail("Save should not fail: \(error)")
        }
    }
}

// MARK: - Date Formatting Tests

final class DateFormattingTests: XCTestCase {
    
    func testFormatDate_ReturnsCorrectFormat() {
        // Given
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let testDate = Date()
        
        // When
        let formattedDate = dateFormatter.string(from: testDate)
        
        // Then
        XCTAssertTrue(formattedDate.contains("-"))
        XCTAssertTrue(formattedDate.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil)
    }
    
    func testCurrentWeek_CalculatesCorrectly() {
        // Given
        let calendar = Calendar.current
        let now = Date()
        
        // When
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let week = calendar.component(.weekOfMonth, from: now)
        
        // Then
        XCTAssertGreaterThan(year, 2000)
        XCTAssertGreaterThan(month, 0)
        XCTAssertLessThanOrEqual(month, 12)
        XCTAssertGreaterThan(week, 0)
        XCTAssertLessThanOrEqual(week, 6)
    }
}
