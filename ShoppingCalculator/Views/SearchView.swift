import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var searchText = ""
    @Binding var showSearch: Bool
    @FocusState var isFocused: Bool
    @Query(sort: \Purchase.date, order: .reverse) private var purchases: [Purchase]
    
    var filteredPurchases: [Purchase] {
        guard !searchText.isEmpty else { return purchases }
        
        return purchases.filter { purchase in
            var isFound = false
            isFound = purchase.products.contains {
                return $0.name.localizedStandardContains(searchText)
            }
            
            if !isFound {
                return purchase.store.localizedStandardContains(searchText)
            }
            return true
        }
    }
    
    var body: some View {
        VStack {
            HistoryView(purchases: filteredPurchases, searchFilter: $searchText)
                .searchable(text: $searchText)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation {
                        showSearch = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .foregroundStyle(Color.line)
                }
            }
        }
    }
}
