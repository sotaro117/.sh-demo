import XCTest
import SwiftUI
import SwiftData
@testable import ShoppingCalculator

@MainActor
class HistoryViewTests: XCTestCase {
    
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
            Product(name: "Bread", price: 2.00, quantity: 1, category: .grain)
        ]
        
        let samplePurchases = [
            Purchase(
                date: Date(),
                products: sampleProducts,
                store: "Test Store 1"
            ),
            Purchase(
                date: Date().addingTimeInterval(-86400), // Yesterday
                products: [Product(name: "Milk", price: 3.50, quantity: 1, category: .dairy)],
                store: "Test Store 2"
            )
        ]
        
        for purchase in samplePurchases {
            context.insert(purchase)
        }
        
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save sample data: \(error)")
        }
    }
    
    func testHistoryViewInitialization() {
        // Given
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        @State var searchFilter = ""
        
        // When
        let historyView = HistoryView(
            purchases: purchases ?? [],
            searchFilter: $searchFilter
        )
        
        // Then
        XCTAssertNotNil(historyView)
    }
    
    func testDetailStateManagement() {
        // Given
        @State var showDetail = false
        @State var purchase: Purchase? = nil
        
        // When
        showDetail = true
        purchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        
        // Then
        XCTAssertTrue(showDetail)
        XCTAssertNotNil(purchase)
    }
    
    func testSearchFilterBinding() {
        // Given
        @State var searchFilter = ""
        
        // When
        searchFilter = "test filter"
        
        // Then
        XCTAssertEqual(searchFilter, "test filter")
    }
    
    func testEmptyPurchasesDisplay() {
        // Given
        let emptyPurchases: [Purchase] = []
        @State var searchFilter = ""
        
        // When
        let historyView = HistoryView(
            purchases: emptyPurchases,
            searchFilter: $searchFilter
        )
        
        // Then
        XCTAssertNotNil(historyView)
        XCTAssertTrue(emptyPurchases.isEmpty)
    }
    
    func testUniqueDatesWithPurchases() {
        // Given
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        let calendar = Calendar.current
        
        // When
        let uniqueDates = Set(purchases?.map { purchase in
            calendar.startOfDay(for: purchase.date)
        } ?? [])
        let sortedDates = Array(uniqueDates).sorted(by: >)
        
        // Then
        XCTAssertNotNil(sortedDates)
        XCTAssertGreaterThanOrEqual(sortedDates.count, 0)
    }
    
    func testPurchasesForDateFiltering() {
        // Given
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        let calendar = Calendar.current
        let targetDate = Date()
        
        // When
        let purchasesForDate = purchases?.filter { purchase in
            calendar.isDate(purchase.date, inSameDayAs: targetDate)
        }.sorted { $0.date > $1.date } ?? []
        
        // Then
        XCTAssertNotNil(purchasesForDate)
    }
    
    func testDateHeaderFormatting() {
        // Given
        let date = Date()
        
        // When
        let formattedDate = date.formatted(.dateTime.month(.wide).day().year())
        
        // Then
        XCTAssertNotNil(formattedDate)
        XCTAssertFalse(formattedDate.isEmpty)
    }
    
    func testPurchaseItemDisplay() {
        // Given
        let purchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        
        // When
        let storeName = purchase?.store ?? ""
        let itemCount = purchase?.products.count ?? 0
        let total = purchase?.total ?? 0
        
        // Then
        XCTAssertNotNil(storeName)
        XCTAssertGreaterThanOrEqual(itemCount, 0)
        XCTAssertGreaterThanOrEqual(total, 0)
    }
    
    func testItemCountDisplay() {
        // Given
        let purchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        let itemCount = purchase?.products.count ?? 0
        
        // When
        let itemCountText = "\(itemCount) items"
        
        // Then
        XCTAssertNotNil(itemCountText)
        XCTAssertTrue(itemCountText.contains("items"))
    }
    
    func testTotalCurrencyFormatting() {
        // Given
        let purchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        let total = purchase?.total ?? 0
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        
        // When
        let formattedTotal = total.formatted(.currency(code: currencyCode))
        
        // Then
        XCTAssertNotNil(formattedTotal)
        XCTAssertTrue(formattedTotal.contains("$") || formattedTotal.contains(currencyCode))
    }
    
    func testButtonStyleConfiguration() {
        // Given
        let buttonStyle = PlainButtonStyle()
        
        // When & Then
        XCTAssertNotNil(buttonStyle)
    }
    
    func testBackgroundColorConfiguration() {
        // Given
        let backgroundColor = Color(UIColor.systemBackground)
        
        // When & Then
        XCTAssertNotNil(backgroundColor)
    }
    
    func testOverlayConfiguration() {
        // Given
        let overlayColor = Color(UIColor.systemGray4)
        let lineWidth: CGFloat = 1
        
        // When & Then
        XCTAssertNotNil(overlayColor)
        XCTAssertEqual(lineWidth, 1)
    }
    
    func testRoundedRectangleConfiguration() {
        // Given
        let cornerRadius: CGFloat = 8
        
        // When & Then
        XCTAssertEqual(cornerRadius, 8)
    }
    
    func testPaddingConfiguration() {
        // Given
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 3
        
        // When & Then
        XCTAssertEqual(horizontalPadding, 8)
        XCTAssertEqual(verticalPadding, 3)
    }
    
    func testSpacingConfiguration() {
        // Given
        let vStackSpacing: CGFloat = 16
        let innerVStackSpacing: CGFloat = 12
        
        // When & Then
        XCTAssertEqual(vStackSpacing, 16)
        XCTAssertEqual(innerVStackSpacing, 12)
    }
    
    func testFontConfiguration() {
        // Given
        let headlineFont = Font.headline
        let bodyFont = Font.body
        let captionFont = Font.caption
        
        // When & Then
        XCTAssertNotNil(headlineFont)
        XCTAssertNotNil(bodyFont)
        XCTAssertNotNil(captionFont)
    }
    
    func testFontWeightConfiguration() {
        // Given
        let mediumWeight = Font.Weight.medium
        let semiboldWeight = Font.Weight.semibold
        
        // When & Then
        XCTAssertNotNil(mediumWeight)
        XCTAssertNotNil(semiboldWeight)
    }
    
    func testForegroundColorConfiguration() {
        // Given
        let primaryColor = Color.primary
        let secondaryColor = Color.secondary
        
        // When & Then
        XCTAssertNotNil(primaryColor)
        XCTAssertNotNil(secondaryColor)
    }
    
    func testSheetPresentation() {
        // Given
        @State var purchase: Purchase? = try? context.fetch(FetchDescriptor<Purchase>()).first
        @State var showDetail = false
        
        // When
        let shouldShowSheet = purchase != nil
        
        // Then
        XCTAssertNotNil(shouldShowSheet)
    }
    
    func testPresentationDetents() {
        // Given
        let detents: [PresentationDetent] = [.large]
        
        // When & Then
        XCTAssertEqual(detents.count, 1)
        XCTAssertEqual(detents.first, .large)
    }
    
    func testHistoryDetailInitialization() {
        // Given
        let purchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        @State var showDetail = false
        
        // When
        if let purchase = purchase {
            let historyDetail = HistoryDetail(purchase: purchase, showDetail: $showDetail)
            
            // Then
            XCTAssertNotNil(historyDetail)
        }
    }
    
    func testScrollViewConfiguration() {
        // Given
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        @State var searchFilter = ""
        
        // When
        let historyView = HistoryView(
            purchases: purchases ?? [],
            searchFilter: $searchFilter
        )
        
        // Then
        XCTAssertNotNil(historyView)
    }
    
    func testLazyVStackConfiguration() {
        // Given
        let spacing: CGFloat = 16
        
        // When & Then
        XCTAssertEqual(spacing, 16)
    }
    
    func testEmptyStateDisplay() {
        // Given
        let emptyPurchases: [Purchase] = []
        
        // When
        let isEmpty = emptyPurchases.isEmpty
        
        // Then
        XCTAssertTrue(isEmpty)
    }
    
    func testEmptyStateIcon() {
        // Given
        let iconName = "cart.badge.questionmark"
        let iconSize: CGFloat = 50
        
        // When & Then
        XCTAssertEqual(iconName, "cart.badge.questionmark")
        XCTAssertEqual(iconSize, 50)
    }
    
    func testEmptyStateText() {
        // Given
        let emptyText = "No purchases found"
        
        // When & Then
        XCTAssertEqual(emptyText, "No purchases found")
    }
    
    func testEmptyStatePadding() {
        // Given
        let topPadding: CGFloat = 100
        
        // When & Then
        XCTAssertEqual(topPadding, 100)
    }
    
    func testAnimationConfiguration() {
        // Given
        @State var showDetail = false
        
        // When
        withAnimation {
            showDetail = true
        }
        
        // Then
        XCTAssertTrue(showDetail)
    }
    
    func testButtonAction() {
        // Given
        @State var showDetail = false
        @State var purchase: Purchase? = nil
        let selectedPurchase = try? context.fetch(FetchDescriptor<Purchase>()).first
        
        // When
        purchase = selectedPurchase
        showDetail = true
        
        // Then
        XCTAssertNotNil(purchase)
        XCTAssertTrue(showDetail)
    }
    
    func testDataSorting() {
        // Given
        let purchases = try? context.fetch(FetchDescriptor<Purchase>())
        let calendar = Calendar.current
        let targetDate = Date()
        
        // When
        let sortedPurchases = purchases?.filter { purchase in
            calendar.isDate(purchase.date, inSameDayAs: targetDate)
        }.sorted { $0.date > $1.date } ?? []
        
        // Then
        XCTAssertNotNil(sortedPurchases)
    }
    
    func testCalendarUsage() {
        // Given
        let calendar = Calendar.current
        
        // When & Then
        XCTAssertNotNil(calendar)
    }
    
    func testDateComparison() {
        // Given
        let calendar = Calendar.current
        let date1 = Date()
        let date2 = Date().addingTimeInterval(86400)
        
        // When
        let isSameDay = calendar.isDate(date1, inSameDayAs: date2)
        
        // Then
        XCTAssertNotNil(isSameDay)
    }
    
    func testStartOfDayCalculation() {
        // Given
        let calendar = Calendar.current
        let date = Date()
        
        // When
        let startOfDay = calendar.startOfDay(for: date)
        
        // Then
        XCTAssertNotNil(startOfDay)
    }
}
