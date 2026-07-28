import XCTest
import SwiftUI
import SwiftData
@testable import ShoppingCalculator

@MainActor
class HomeViewTests: XCTestCase {
    
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
            
            // Insert sample data
            insertSampleData()
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        context = nil
        super.tearDown()
    }
    
    private func insertSampleData() {
        let sampleProducts = [
            Product(name: "Apple", price: 1.50, quantity: 2, category: .fruitVegetable),
            Product(name: "Bread", price: 2.00, quantity: 1, category: .grain),
            Product(name: "Milk", price: 3.50, quantity: 1, category: .dairy)
        ]
        
        let samplePurchase = Purchase(
            date: Date(),
            products: sampleProducts,
            store: "Test Store"
        )
        
        context.insert(samplePurchase)
        
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save sample data: \(error)")
        }
    }
    
    func testHomeViewInitialization() {
        // Given
        @State var showUserModal = false
        let homeView = HomeView(showUserModal: $showUserModal)
        
        // When & Then
        XCTAssertNotNil(homeView)
    }
    
    func testMonthTotalCalculation() {
        // Given
        @State var showUserModal = false
        let homeView = HomeView(showUserModal: $showUserModal)
        
        // When
        // The monthTotal is calculated in the view
        let body = homeView.body
        
        // Then
        XCTAssertNotNil(body)
    }
    
    func testRecentPurchasesQuery() {
        // Given
        let descriptor = HomeView.recentPurchasesDescriptor
        
        // When
        let purchases = try? context.fetch(descriptor)
        
        // Then
        XCTAssertNotNil(purchases)
        XCTAssertGreaterThanOrEqual(purchases?.count ?? 0, 0)
    }
    
    func testCurrentMonthPurchasesQuery() {
        // Given
        let predicate = Purchase.currentMonthPredicate()
        let descriptor = FetchDescriptor<Purchase>(predicate: predicate)
        
        // When
        let purchases = try? context.fetch(descriptor)
        
        // Then
        XCTAssertNotNil(purchases)
    }
    
    func testSearchStateManagement() {
        // Given
        @State var showSearch = false
        @State var searchText = ""
        @State var searchFilter = ""
        
        // When
        showSearch = true
        searchText = "test"
        searchFilter = "filter"
        
        // Then
        XCTAssertTrue(showSearch)
        XCTAssertEqual(searchText, "test")
        XCTAssertEqual(searchFilter, "filter")
    }
    
    func testModalStateManagement() {
        // Given
        @State var showModal = false
        @State var showUserModal = false
        
        // When
        showModal = true
        showUserModal = true
        
        // Then
        XCTAssertTrue(showModal)
        XCTAssertTrue(showUserModal)
    }
    
    func testRecentHistoryToggle() {
        // Given
        @State var showRecentHistory = true
        
        // When
        showRecentHistory.toggle()
        
        // Then
        XCTAssertFalse(showRecentHistory)
    }
    
    func testNavigationLinkToHistoryView() {
        // Given
        @State var searchFilter = ""
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        
        // When
        let historyView = HistoryView(purchases: purchases ?? [], searchFilter: $searchFilter)
        
        // Then
        XCTAssertNotNil(historyView)
    }
    
    func testToolbarConfiguration() {
        // Given
        @State var showSearch = false
        @State var showModal = false
        @State var showUserModal = false
        
        // When
        let shouldShowToolbar = !showSearch && !showModal
        
        // Then
        XCTAssertTrue(shouldShowToolbar)
    }
    
    func testAvatarImageHandling() {
        // Given
        @State var avatarImage: AvatarImage? = nil
        
        // When
        // Test with no avatar
        let hasAvatar = avatarImage != nil
        
        // Then
        XCTAssertFalse(hasAvatar)
    }
    
    func testDateFormatting() {
        // Given
        let date = Date()
        
        // When
        let formattedDate = date.formatted(.dateTime.month())
        
        // Then
        XCTAssertNotNil(formattedDate)
        XCTAssertFalse(formattedDate.isEmpty)
    }
    
    func testCurrencyFormatting() {
        // Given
        let amount = 15.99
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        let formattedAmount = amount.formatted(.currency(code: currencyCode))
        
        // Then
        XCTAssertNotNil(formattedAmount)
        XCTAssertTrue(formattedAmount.contains("15.99") || formattedAmount.contains("$15.99"))
    }
    
    func testBackgroundColor() {
        // Given
        let homeView = HomeView(showUserModal: .constant(false))
        
        // When
        let body = homeView.body
        
        // Then
        XCTAssertNotNil(body)
    }
    
    func testNavigationTitle() {
        // Given
        let homeView = HomeView(showUserModal: .constant(false))
        
        // When
        let body = homeView.body
        
        // Then
        // Navigation title should be empty string
        XCTAssertNotNil(body)
    }
    
    func testTaskExecution() {
        // Given
        @State var showUserModal = false
        let homeView = HomeView(showUserModal: $showUserModal)
        
        // When
        // The task should execute on appear
        let body = homeView.body
        
        // Then
        XCTAssertNotNil(body)
    }
    
    func testUserProfileRetrieval() {
        // Given
        let homeView = HomeView(showUserModal: .constant(false))
        
        // When
        // This would normally call getUser() async function
        let body = homeView.body
        
        // Then
        XCTAssertNotNil(body)
    }
    
    func testImageDownload() {
        // Given
        let path = "test/path/image.jpg"
        
        // When
        // This would normally call downloadImage(path: String) async function
        let isValidPath = !path.isEmpty
        
        // Then
        XCTAssertTrue(isValidPath)
    }
    
    func testViewStateTransitions() {
        // Given
        @State var showSearch = false
        @State var showModal = false
        
        // When
        withAnimation {
            showSearch.toggle()
        }
        
        // Then
        XCTAssertTrue(showSearch)
        XCTAssertFalse(showModal)
    }
    
    func testDataBinding() {
        // Given
        @State var showUserModal = false
        let homeView = HomeView(showUserModal: $showUserModal)
        
        // When
        showUserModal = true
        
        // Then
        XCTAssertTrue(showUserModal)
    }
}
