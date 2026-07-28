import SwiftUI

// MARK: Main calendar view
struct CalendarView: View {
    @State private var isShowingChatModal = false
    @State private var selectedDate = Date()
    @State private var isShowPremium = false
//    @State private var tier: Profile.Tier?
    
    var body: some View {
        ZStack {
            // Background for the entire view
            VStack(spacing: 0) {
                // Black background for top area (navigation + WeekView)
                Color.line
                    .ignoresSafeArea(.container, edges: .top) // Covers navigation area
                
                // Original background for TaskListView area
                Color.bg
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                WeekView(selectedDate: $selectedDate)
                    .padding(.bottom, 4)
                
                TaskListView(selectedDate: selectedDate)
            }
            .padding(.top)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Planner")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.bg)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    /*
                    if tier == .free {
                        isShowPremium = true
                    } else {
                        isShowingChatModal = true
                    }
                     */
                    isShowingChatModal = true
                } label: {
                    Image(systemName: "ellipsis.message.fill")
                        .foregroundStyle(.bg)
                }
            }
        }
//        .task {
//            await getUser()
//        }
        .toolbarRole(.editor)
        .sheet(isPresented: $isShowingChatModal) {
            ChatModal()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isShowPremium){
            TierGatewayView()
        }
    }
    
    /*
    func getUser() async {
        do {
            let currentUser = try await supabase.auth.session.user
            
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            print(profile)
            
            tier = profile.tier
         } catch {
           debugPrint(error)
         }
    }
     */
}

// MARK: Week view
struct WeekView: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false
    @State private var weekOffset = 0
    
    private let calendar = Calendar.current
    private let weekCount = 301
    private let centerIndex = 150
    
    private var currentWeekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }
    
    private func getDateForWeek(_ offset: Int) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func isDateInDisplayedWeek(_ date: Date, for offset: Int) -> Bool {
        let displayedWeek = getDateForWeek(offset)
        return calendar.isDate(date, equalTo: displayedWeek, toGranularity: .weekOfYear)
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        if isDateInDisplayedWeek(selectedDate, for: weekOffset) {
            return formatter.string(from: selectedDate)
        }
        
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text("\(monthYearString(for: getDateForWeek(weekOffset)))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.bg) // Changed to white
                
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray) // Changed to gray for better contrast
                    .frame(width: 40, height: 40)
                    .font(.system(size: 18))
                
                Spacer()
                
                Button {
                    withAnimation {
                        weekOffset = 0
                        selectedDate = Date()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Today")
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(
                        ZStack {
                            Color.gray.opacity(0.2) // Darker background for black theme
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        }
                    )
                    .foregroundColor(.white) // Changed to white
                    .cornerRadius(8)
                }
                .opacity(isDateInDisplayedWeek(Date(), for: weekOffset) ? 0 : 1)
                .blur(radius: isDateInDisplayedWeek(Date(), for: weekOffset) ? 10 : 0)
                .animation(.easeInOut, value: isDateInDisplayedWeek(Date(), for: weekOffset))
                .opacity(isDateInDisplayedWeek(Date(), for: weekOffset) ? 0 : 1)
                .offset(y: isDateInDisplayedWeek(Date(), for: weekOffset) ? 20 : 0)
                .scaleEffect(isDateInDisplayedWeek(Date(), for: weekOffset) ? 0.9 : 1)
                .animation(.easeInOut(duration: 0.3), value: isDateInDisplayedWeek(Date(), for: weekOffset))
            }
            .padding(.leading, 8)
            .onTapGesture {
                showDatePicker = true
            }
            .overlay {
                if showDatePicker {
                    DatePicker(
                        "Test",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accentColor(.orange)
                    .onChange(of: selectedDate) { _, _ in
                        showDatePicker = false
                    }
                    .blendMode(.destinationOver)
                }
            }
            
            TabView(selection: $weekOffset) {
                ForEach(-centerIndex..<centerIndex, id: \.self) { offset in
                    VStack {
                        WeekRowView(
                            baseDate: getDateForWeek(offset),
                            selectedDate: $selectedDate
                        )
                        .padding(.horizontal, 4)
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .padding(.horizontal)
        // No background needed - parent handles it
        .onChange(of: selectedDate) { _, newDate in
            let startOfNewDateWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: newDate)) ?? newDate
            
            if startOfNewDateWeek != getDateForWeek(weekOffset) {
                let newOffset = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: startOfNewDateWeek).weekOfYear ?? 0
                
                withAnimation {
                    weekOffset = newOffset
                }
            }
        }
    }
}

// MARK: Week raw view
struct WeekRowView: View {
    let baseDate: Date
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private var datesForWeek: [Date] {
        (0..<7).compactMap { index in
            calendar.date(byAdding: .day, value: index, to: baseDate)
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(datesForWeek, id: \.timeIntervalSince1970) { date in
                DayView(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                )
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
    }
}

// MARK: Day view
struct DayView: View {
    let date: Date
    let isSelected: Bool
    
    private let calendar = Calendar.current
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private var borderColor: Color {
        if isSelected {
            return .bg
        }
        return isToday ? .bg : .gray.opacity(0.3) // Subtle border for black theme
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(weekdayString)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
            
            Text(dayString)
                .font(.title3)
                .fontWeight(isSelected ? .bold : .semibold)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(isSelected ? Color.line : Color.bg)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // FIXED: Dark background for non-selected, teal for selected
                Color(isSelected ? Color.bg : Color.clear)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: isToday ? 5 : 1)
            }
        )
        .cornerRadius(10)
    }
}

import SwiftData

// MARK: Meal plan view
struct TaskListView: View {
    let selectedDate: Date
    @EnvironmentObject private var userService: UserService
    // let mealPlans = MealPlan.sampleData
    @Environment(\.modelContext) private var context
    @Query(sort: \MealPlan.date, order: .reverse) private var mealPlans: [MealPlan]
    @Query(filter: MealPlan.currentWeekPredicate()) private var currentWeekPlans: [MealPlan]
    @Query(filter: Purchase.recentWeekPredicate()) private var recentWeekPurchases: [Purchase]
    @StateObject private var mealPlanner = MealPlanner()
    @State private var isShowPremium = false
//    @State private var tier: Profile.Tier?
    
    let calendar = Calendar.current
    
    private var filteredCurrentWeekPlans: [MealPlan] {
        currentWeekPlans.filter { $0.userId == userService.userId }
    }
    
    private var filteredRecentWeekPurchases: [Purchase] {
        recentWeekPurchases.filter { $0.userId == userService.userId }
    }
    
    private var mealsForSelectedDate: [MealPlan] {
        let order: [Meal: Int] = [.breakfast: 0, .lunch: 1, .dinner: 2]
        
        return mealPlans.filter { mealPlan in
            calendar.isDate(mealPlan.date, inSameDayAs: selectedDate)
        }
        .filter { mealPlan in
            mealPlan.userId == userService.userId
        }
        .sorted { (order[$0.meal] ?? 0) < (order[$1.meal] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.line) // Back to original color
                
                Spacer()
                
                if !mealsForSelectedDate.isEmpty {
                    Button{
                        Task {
                            await mealPlanner.generatePlan(purchases: filteredRecentWeekPurchases)
                        }
                    } label: {
                        if mealPlanner.isProcessing {
                            ProgressView()
                        } else {
                            Text("Update meal plan")
                        }
                    }
                    .foregroundStyle(.bg)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(mealPlanner.isProcessing ? .line.opacity(0.2) : .line, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if mealsForSelectedDate.isEmpty {
                                Button{
                                    /*
                                    if tier == .free {
                                        isShowPremium = true
                                    } else {
                                        Task {
                                            await mealPlanner.generatePlan(purchases: recentWeekPurchases)
                                        }
                                    }
                                     */
                                    Task {
                                        await mealPlanner.generatePlan(purchases: filteredRecentWeekPurchases)
                                    }
                                } label: {
                                    if mealPlanner.isProcessing {
                                        ProgressView()
                                    } else {
                                        Text("New weekly meal plan")
                                    }
                                }
                                .foregroundStyle(.bg)
                                .padding()
                                .background(filteredRecentWeekPurchases.isEmpty || mealPlanner.isProcessing ? .line.opacity(0.2) : .line, in: RoundedRectangle(cornerRadius: 20))
                                .offset(y: geometry.size.height * 0.5)
                                .disabled(filteredRecentWeekPurchases.isEmpty)
                            } else {
                                ForEach(mealsForSelectedDate) { mealPlan in
                                    TaskView(mealPlan: mealPlan)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            }
        .onAppear{
            mealPlanner.context = context
        }
        .task {
            await userService.load()
        }
        .padding()
        .background(Color.bg)
        .cornerRadius(20)
        .fullScreenCover(isPresented: $isShowPremium){
            TierGatewayView()
        }
    }
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d / EEEE"
        return formatter
    }()
}

// MARK: Meal plan's cards
struct TaskView: View {
    @Environment(\.colorScheme) var colorScheme
    let mealPlan: MealPlan
    @State private var showDetailModal = false
    
    private var mealColor: Color {
        switch mealPlan.meal {
        case .breakfast:
            return Color.orange
        case .lunch:
            return Color.green
        case .dinner:
            return Color.indigo
        }
    }
    
    var ingredientsStr: String {
        var ingredients = ""
        for ingredient in mealPlan.ingredients {
            ingredients += ingredient + ", "
        }
        return ingredients
    }
    
//    private var isTimeForMeal: Meal? {
//        let calendar = Calendar.current
//        let now = Date.now
//        
//        let startOfDay = calendar.startOfDay(for: Date())
//        let breakfastStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: startOfDay)!
//        let breakfastEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: startOfDay)!
//        
//        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfDay)!
//        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: startOfDay)!
//        
//        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startOfDay)!
//        let dinnerEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: startOfDay)!
//        
//        if(now >= breakfastStart && now <= breakfastEnd){
//            return .breakfast
//        } else if (now >= lunchStart && now <= lunchEnd){
//            return .lunch
//        } else if (now >= dinnerStart && now <= dinnerEnd){
//            return .dinner
//        }
//        
//        return nil
//    }
    
    var body: some View {
        VStack(alignment: .leading) {
                Text(mealPlan.meal.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray) // Back to original
                
                HStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(mealColor)
                        .frame(width: 15, height: 15)
                        .padding(.trailing, 3)
                    
                    Text(mealPlan.plate)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.line) // Back to original color
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(ingredientsStr.prefix(30))...")
                            .foregroundStyle(.gray)
                    }
                    
                    VStack(alignment: .trailing) {
                        Button {
                            showDetailModal = true
                        } label: {
                            Image(systemName: "chevron.down")
                                .resizable()
                                .foregroundStyle(.line)
                                .frame(width: 15, height: 10)
                                .padding(.horizontal, 5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding()
        .background(colorScheme == .light ? .white : .black, in: RoundedRectangle(cornerRadius: 5))
        .sheet(isPresented: $showDetailModal){
            TaskModal(mealPlan: mealPlan)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .padding(.horizontal, 10)
    }
}

// MARK: Meal plan's ingredients modal
struct TaskModal: View {
    let mealPlan: MealPlan
    var body: some View {
        List {
            ForEach(mealPlan.ingredients, id: \.description) { ingredient in
                Text(ingredient)
                    .font(.caption)
                    .foregroundColor(.line)
            }
        }
        .listStyle(.plain)
    }
}
