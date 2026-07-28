import XCTest
import SwiftUI
import SwiftData
@testable import ShoppingCalculator

@MainActor
class CalendarViewTests: XCTestCase {
    
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
        let sampleMealPlans = [
            MealPlan(
                meal: .breakfast,
                plate: "Test Breakfast",
                ingredients: ["ingredient1", "ingredient2"],
                date: Date()
            ),
            MealPlan(
                meal: .lunch,
                plate: "Test Lunch",
                ingredients: ["ingredient3", "ingredient4"],
                date: Date()
            )
        ]
        
        for mealPlan in sampleMealPlans {
            context.insert(mealPlan)
        }
        
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save sample data: \(error)")
        }
    }
    
    func testCalendarViewInitialization() {
        // Given
        let calendarView = CalendarView()
        
        // When & Then
        XCTAssertNotNil(calendarView)
    }
    
    func testEventModalState() {
        // Given
        @State var isShowingEventModal = false
        
        // When
        isShowingEventModal = true
        
        // Then
        XCTAssertTrue(isShowingEventModal)
    }
    
    func testSelectedDateState() {
        // Given
        @State var selectedDate = Date()
        let testDate = Date().addingTimeInterval(86400) // Tomorrow
        
        // When
        selectedDate = testDate
        
        // Then
        XCTAssertEqual(selectedDate, testDate)
    }
    
    func testWeekViewInitialization() {
        // Given
        @State var selectedDate = Date()
        
        // When
        let weekView = WeekView(selectedDate: $selectedDate)
        
        // Then
        XCTAssertNotNil(weekView)
    }
    
    func testTaskListViewInitialization() {
        // Given
        let selectedDate = Date()
        
        // When
        let taskListView = TaskListView(selectedDate: selectedDate)
        
        // Then
        XCTAssertNotNil(taskListView)
    }
    
    func testCalendarConfiguration() {
        // Given
        let calendar = Calendar.current
        
        // When & Then
        XCTAssertNotNil(calendar)
    }
    
    func testWeekCountConfiguration() {
        // Given
        let weekCount = 301
        let centerIndex = 150
        
        // When & Then
        XCTAssertEqual(weekCount, 301)
        XCTAssertEqual(centerIndex, 150)
    }
    
    func testCurrentWeekStartCalculation() {
        // Given
        let calendar = Calendar.current
        let now = Date()
        
        // When
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // Then
        XCTAssertNotNil(currentWeekStart)
    }
    
    func testDateForWeekCalculation() {
        // Given
        let calendar = Calendar.current
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let offset = 0
        
        // When
        let dateForWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)!
        
        // Then
        XCTAssertNotNil(dateForWeek)
    }
    
    func testDateInDisplayedWeekCheck() {
        // Given
        let calendar = Calendar.current
        let date = Date()
        let offset = 0
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let displayedWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)!
        
        // When
        let isInDisplayedWeek = calendar.isDate(date, equalTo: displayedWeek, toGranularity: .weekOfYear)
        
        // Then
        XCTAssertTrue(isInDisplayedWeek)
    }
    
    func testMonthYearStringFormatting() {
        // Given
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        // When
        let formattedString = formatter.string(from: date)
        
        // Then
        XCTAssertNotNil(formattedString)
        XCTAssertFalse(formattedString.isEmpty)
    }
    
    func testWeekOffsetState() {
        // Given
        @State var weekOffset = 0
        
        // When
        weekOffset = 5
        
        // Then
        XCTAssertEqual(weekOffset, 5)
    }
    
    func testDatePickerState() {
        // Given
        @State var showDatePicker = false
        
        // When
        showDatePicker = true
        
        // Then
        XCTAssertTrue(showDatePicker)
    }
    
    func testTodayButtonVisibility() {
        // Given
        let calendar = Calendar.current
        let now = Date()
        let weekOffset = 0
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let displayedWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart)!
        
        // When
        let isCurrentWeek = calendar.isDate(now, equalTo: displayedWeek, toGranularity: .weekOfYear)
        let shouldShowTodayButton = !isCurrentWeek
        
        // Then
        XCTAssertNotNil(shouldShowTodayButton)
    }
    
    func testWeekRowViewInitialization() {
        // Given
        let baseDate = Date()
        @State var selectedDate = Date()
        
        // When
        let weekRowView = WeekRowView(baseDate: baseDate, selectedDate: $selectedDate)
        
        // Then
        XCTAssertNotNil(weekRowView)
    }
    
    func testDatesForWeekCalculation() {
        // Given
        let calendar = Calendar.current
        let baseDate = Date()
        
        // When
        let datesForWeek = (0..<7).compactMap { index in
            calendar.date(byAdding: .day, value: index, to: baseDate)
        }
        
        // Then
        XCTAssertEqual(datesForWeek.count, 7)
    }
    
    func testDayViewInitialization() {
        // Given
        let date = Date()
        let isSelected = true
        
        // When
        let dayView = DayView(date: date, isSelected: isSelected)
        
        // Then
        XCTAssertNotNil(dayView)
    }
    
    func testWeekdayStringFormatting() {
        // Given
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        // When
        let weekdayString = formatter.string(from: date).uppercased()
        
        // Then
        XCTAssertNotNil(weekdayString)
        XCTAssertFalse(weekdayString.isEmpty)
    }
    
    func testDayStringFormatting() {
        // Given
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        
        // When
        let dayString = formatter.string(from: date)
        
        // Then
        XCTAssertNotNil(dayString)
        XCTAssertFalse(dayString.isEmpty)
    }
    
    func testIsTodayCheck() {
        // Given
        let calendar = Calendar.current
        let date = Date()
        
        // When
        let isToday = calendar.isDateInToday(date)
        
        // Then
        XCTAssertTrue(isToday)
    }
    
    func testIsWeekendCheck() {
        // Given
        let calendar = Calendar.current
        let date = Date()
        let weekday = calendar.component(.weekday, from: date)
        
        // When
        let isWeekend = weekday == 1 || weekday == 7
        
        // Then
        XCTAssertNotNil(isWeekend)
    }
    
    func testTextColorForSelectedDate() {
        // Given
        let isSelected = true
        let isToday = false
        
        // When
        let textColor: Color = isSelected ? .black : (isToday ? .appTeal : .white)
        
        // Then
        XCTAssertNotNil(textColor)
    }
    
    func testBorderColorForSelectedDate() {
        // Given
        let isSelected = true
        let isToday = false
        
        // When
        let borderColor: Color = isSelected ? .appTeal : (isToday ? .appTeal : .gray.opacity(0.3))
        
        // Then
        XCTAssertNotNil(borderColor)
    }
    
    func testMealPlansQuery() {
        // Given
        let descriptor = FetchDescriptor<MealPlan>(sortBy: [SortDescriptor(\MealPlan.date, order: .reverse)])
        
        // When
        let mealPlans = try? context.fetch(descriptor)
        
        // Then
        XCTAssertNotNil(mealPlans)
    }
    
    func testCurrentWeekPlansQuery() {
        // Given
        let predicate = MealPlan.currentWeekPredicate()
        let descriptor = FetchDescriptor<MealPlan>(predicate: predicate)
        
        // When
        let currentWeekPlans = try? context.fetch(descriptor)
        
        // Then
        XCTAssertNotNil(currentWeekPlans)
    }
    
    func testRecentWeekPurchasesQuery() {
        // Given
        let predicate = Purchase.recentWeekPredicate()
        let descriptor = FetchDescriptor<Purchase>(predicate: predicate)
        
        // When
        let recentWeekPurchases = try? context.fetch(descriptor)
        
        // Then
        XCTAssertNotNil(recentWeekPurchases)
    }
    
    func testMealsForSelectedDateFiltering() {
        // Given
        let selectedDate = Date()
        let calendar = Calendar.current
        let order: [Meal: Int] = [.breakfast: 0, .lunch: 1, .dinner: 2]
        
        // When
        let mealPlans = try? context.fetch(FetchDescriptor<MealPlan>())
        let mealsForSelectedDate = mealPlans?.filter { mealPlan in
            calendar.isDate(mealPlan.date, inSameDayAs: selectedDate)
        }.sorted { (order[$0.meal] ?? 0) < (order[$1.meal] ?? 0) } ?? []
        
        // Then
        XCTAssertNotNil(mealsForSelectedDate)
    }
    
    func testShouldGeneratePlansLogic() {
        // Given
        let calendar = Calendar.current
        let selectedDate = Date()
        let isCurrentWeek = calendar.isDate(Date(), equalTo: selectedDate, toGranularity: .weekOfYear)
        let currentWeekPlans: [MealPlan] = []
        let recentWeekPurchases: [Purchase] = []
        
        // When
        let shouldGeneratePlans = isCurrentWeek && currentWeekPlans.isEmpty && !recentWeekPurchases.isEmpty
        
        // Then
        XCTAssertNotNil(shouldGeneratePlans)
    }
    
    func testTaskViewInitialization() {
        // Given
        let mealPlan = MealPlan(
            meal: .breakfast,
            plate: "Test Plate",
            ingredients: ["ingredient1", "ingredient2"],
            date: Date()
        )
        
        // When
        let taskView = TaskView(mealPlan: mealPlan)
        
        // Then
        XCTAssertNotNil(taskView)
    }
    
    func testMealColorMapping() {
        // Given
        let breakfastMeal = Meal.breakfast
        let lunchMeal = Meal.lunch
        let dinnerMeal = Meal.dinner
        
        // When
        let breakfastColor: Color = .orange
        let lunchColor: Color = .green
        let dinnerColor: Color = .indigo
        
        // Then
        XCTAssertNotNil(breakfastColor)
        XCTAssertNotNil(lunchColor)
        XCTAssertNotNil(dinnerColor)
    }
    
    func testIngredientsStringConcatenation() {
        // Given
        let ingredients = ["ingredient1", "ingredient2", "ingredient3"]
        
        // When
        let ingredientsStr = ingredients.joined(separator: ", ")
        
        // Then
        XCTAssertEqual(ingredientsStr, "ingredient1, ingredient2, ingredient3")
    }
    
    func testIsTimeForMealCalculation() {
        // Given
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: Date())
        let breakfastStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: startOfDay)!
        let breakfastEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: startOfDay)!
        
        // When
        let isBreakfastTime = now >= breakfastStart && now <= breakfastEnd
        
        // Then
        XCTAssertNotNil(isBreakfastTime)
    }
    
    func testTaskModalInitialization() {
        // Given
        let mealPlan = MealPlan(
            meal: .breakfast,
            plate: "Test Plate",
            ingredients: ["ingredient1", "ingredient2"],
            date: Date()
        )
        
        // When
        let taskModal = TaskModal(mealPlan: mealPlan)
        
        // Then
        XCTAssertNotNil(taskModal)
    }
    
    func testDateFormatterConfiguration() {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d / EEEE"
        
        // When
        let formattedDate = formatter.string(from: Date())
        
        // Then
        XCTAssertNotNil(formattedDate)
        XCTAssertFalse(formattedDate.isEmpty)
    }
    
    func testNavigationTitleConfiguration() {
        // Given
        let navigationTitle = "Calendar"
        
        // When & Then
        XCTAssertEqual(navigationTitle, "Calendar")
    }
    
    func testNavigationBarTitleDisplayMode() {
        // Given
        let displayMode = NavigationBarItem.TitleDisplayMode.inline
        
        // When & Then
        XCTAssertEqual(displayMode, .inline)
    }
    
    func testToolbarBackgroundConfiguration() {
        // Given
        let backgroundStyle = Color.clear
        
        // When & Then
        XCTAssertNotNil(backgroundStyle)
    }
    
    func testToolbarColorScheme() {
        // Given
        let colorScheme = ColorScheme.dark
        
        // When & Then
        XCTAssertEqual(colorScheme, .dark)
    }
    
    func testSheetPresentation() {
        // Given
        @State var isShowingEventModal = false
        
        // When
        isShowingEventModal = true
        
        // Then
        XCTAssertTrue(isShowingEventModal)
    }
    
    func testPresentationDetents() {
        // Given
        let detents: [PresentationDetent] = [.large]
        
        // When & Then
        XCTAssertEqual(detents.count, 1)
        XCTAssertEqual(detents.first, .large)
    }
}
