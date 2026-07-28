import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    
    @Query(HomeView.recentPurchasesDescriptor) private var recentPurchases: [Purchase]
    @Query(filter: Purchase.currentMonthPredicate()) private var currentMonthPurchases: [Purchase]
    @Query(sort: \Purchase.date, order: .reverse) private var purchases: [Purchase]
    
    @State private var showModal = false /// Trigger search modal view
    @State private var showRecentHistory = true
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var searchFilter = ""
    @Binding var showUserModal: Bool /// Control user modal view
    @EnvironmentObject private var userService: UserService
    
    static var recentPurchasesDescriptor: FetchDescriptor<Purchase> {
        
        var descriptor = FetchDescriptor<Purchase>(
            sortBy: [
                SortDescriptor(\Purchase.date, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 10
        return descriptor
    }
    
    private var filteredRecentPurchases: [Purchase]{
        guard !userService.userId.isEmpty else {
            return []
        }
        
        return recentPurchases.filter { $0.userId == userService.userId }
    }
    
    private var filteredPurchases: [Purchase] {
        guard !userService.userId.isEmpty else {
            return []
        }
        let filtered = purchases.filter { $0.userId == userService.userId }
        return filtered
    }
    
    private var monthTotal: Double {
        // sum up total
        let total = currentMonthPurchases.reduce(0) { result, purchase in
            result + purchase.total
        }
        return round(total * 100) / 100
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                if showSearch {
                    SearchView(showSearch: $showSearch)
                        .transition(.move(edge: .bottom))
                        .zIndex(1.0)
                }
                else if userService.userId.isEmpty {
                    VStack(spacing: 12) {
                        Text("Could not load your data.")
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await userService.refresh() }
                        }
                        .foregroundStyle(Color.line)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                else {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(.wallet)
                                    .foregroundStyle(.white)
                                    .padding(7)
                                    .background(.indigo)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                
                                Text("\(Date.now, format: .dateTime.month())")
                                    .foregroundStyle(Color.line)
                                    .font(.title2)
                            }
                            
                            Text(monthTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .foregroundStyle(Color.line)
                                .font(.largeTitle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.purple.opacity(0.2), lineWidth: 2)
                        }
                        .padding(.horizontal, 10)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Recent histories")
                                    .font(.title)
                                
                                Spacer()
                                
                                NavigationLink("View All") {
                                    HistoryView(purchases: filteredPurchases, searchFilter: $searchFilter)
                                }
                                .foregroundStyle(Color.line)
                                .font(.callout)
                            }
                            HistoryView(purchases: filteredRecentPurchases, searchFilter: $searchFilter)
                        }
                        .padding(.vertical, 5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            if !showSearch && !showModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            showUserModal.toggle()
                        }
                    } label: {
                        if let avatarImage = userService.avatarImage {
                            avatarImage.image.resizable()
                                .clipShape(Circle())
                                .frame(width: 35, height: 35)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundStyle(Color.line)
                        }
                    }
                    .accessibilityLabel("Open user menu")
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Text("Home")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ToolbarItem {
                    Button {
                        withAnimation {
                            showSearch.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundStyle(Color.line)
                    }
                    .accessibilityLabel("Search")
                }

                ToolbarItem {
                    NavigationLink {
                        withAnimation {
                            SettingView()
                        }
                    } label: {
                        Image(.settings)
                            .resizable()
                            .foregroundStyle(Color.line)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .toolbarRole(.editor)
        .task {
            await userService.load()
        }
    }
}
