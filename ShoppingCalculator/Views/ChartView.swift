import SwiftUI
import SwiftData
import Charts

struct ChartView: View {
    var purchases: [Purchase]
    @State private var selectedSegment = 0

    var products: [Product] {
        var products: [Product] = []
        for purchase in purchases {
            for product in purchase.products {
                products.append(product)
            }
        }
        
        return products.sorted {
            $0.category.rawValue < $1.category.rawValue
        }
    }
    
    var purchasesByDay: [(day: String, total: Double)] {
        let calendar = Calendar.current
        
        // Group purchases by day
        let grouped = Dictionary(grouping: purchases) { purchase in
            calendar.startOfDay(for: purchase.date)
        }
        
        // Sum totals for each day
        let summed = grouped.map { (date, purchases) in
            let total = purchases.reduce(0) { $0 + $1.total }
            let dayString = formatDate(date: date)
            return (day: dayString, total: total)
        }
        
        // Sort by date
        return summed.sorted {
            let formatter = dateFormatter()
            guard let date1 = formatter.date(from: $0.day),
                  let date2 = formatter.date(from: $1.day) else {
                return false
            }
            return date1 < date2
        }
    }

    
    private let segments = ["Nutritions", "Expense"]
    
    var body: some View {
        VStack {
            SegmentControl(selectedIndex: $selectedSegment, labels: segments)
            
            if selectedSegment == 0 {
                Chart(products) { product in
                    SectorMark(angle: .value("Type", 1), innerRadius: .ratio(0.6))
                        .foregroundStyle(by: .value("products", product.category.rawValue))
                }
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let anchor = chartProxy.plotFrame {
                            let frame = geometry[anchor]
                            Image(systemName: "fork.knife")
                                .position(x: frame.midX, y: frame.midY)
                                .font(.caption)
                        }
                    }
                }
                .chartLegend(position: .trailing, alignment: .center)
                .frame(height: 200)
                .padding()
            } else {
                Chart(purchasesByDay, id: \.day) { item in
                    BarMark(
                        x: .value("Days", item.day),
                        y: .value("Price", item.total)
                    )
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .annotation(position: .top) {
                        Text(item.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .padding()
            }
        }
    }
    
    private func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }

    private func formatDate(date: Date) -> String {
        let formatter = dateFormatter()
        return formatter.string(from: date)
    }
}
