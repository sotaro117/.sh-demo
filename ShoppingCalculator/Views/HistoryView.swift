import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context 
        
    var purchases: [Purchase]
    @State private var showDetail = false
    @State private var purchase: Purchase?
    @Binding var searchFilter: String
        
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if purchases.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No purchases found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                } else {
                    // FIXED: Get unique dates that actually have purchases
                    let uniqueDates = getUniqueDatesWithPurchases(purchases)
                    
                    ForEach(uniqueDates, id: \.timeIntervalSince1970) { date in
                        VStack(alignment: .leading, spacing: 12) {
                            // Date header
                            Text(date, format: .dateTime.month(.wide).day().year())
                                .font(.headline)
                                .padding(.vertical, 3)
                            
                            // FIXED: Only show purchases for this specific date
                            let purchasesForDate = getPurchasesForDate(date: date, purchases: purchases)
                            
                            ForEach(purchasesForDate) { purchase in
                                Button {
                                    withAnimation {
                                        self.purchase = purchase
                                        showDetail = true // FIXED: Use true instead of toggle
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(purchase.store)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
                                            Text("\(purchase.products.count) items")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(purchase.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                            .font(.body)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(Color.primary) // FIXED: Use proper color
                                    .padding()
                                    .background(Color(UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle()) // FIXED: Add button style for proper touch handling
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .sheet(item: $purchase) { purchase in
            HistoryDetail(purchase: purchase, showDetail: $showDetail)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // FIXED: More efficient function to get unique dates that actually have purchases
    private func getUniqueDatesWithPurchases(_ purchases: [Purchase]) -> [Date] {
        let calendar = Calendar.current
        
        // Get unique dates from purchases and sort them
        let uniqueDates = Set(purchases.map { purchase in
            calendar.startOfDay(for: purchase.date)
        })
        
        return Array(uniqueDates).sorted(by: >) // Most recent first
    }
    
    // FIXED: Efficient function to get purchases for a specific date
    private func getPurchasesForDate(date: Date, purchases: [Purchase]) -> [Purchase] {
        let calendar = Calendar.current
        return purchases.filter { purchase in
            calendar.isDate(purchase.date, inSameDayAs: date)
        }.sorted { $0.date > $1.date } // Most recent first within the day
    }
}
