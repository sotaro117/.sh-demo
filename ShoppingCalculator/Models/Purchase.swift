import Foundation
import SwiftData

@Model
class Purchase {
    var userId: String
    var date: Date
    var products: [Product]
    var store: String
    var total: Double {
        let decimalTotal = products.compactMap {$0}
            .reduce(Decimal(0)) { result, product in
                result + (product.price * Decimal(product.quantity))
            }
        return NSDecimalNumber(decimal: decimalTotal).doubleValue
    }
    
    init(userId: String, date: Date, products: [Product], store: String) {
        self.userId = userId
        self.date = date
        self.products = products
        self.store = store
    }
    
    /*
    static let sampleData = [
        Purchase(date: Date(), products: Product.sampleData.first!, store: "Lidl"),
        Purchase(date: Date(timeIntervalSinceNow: -86400), products: Product.sampleData.last!, store: "Mercadona"),
    ]
     */
}

extension Purchase {
    
    // get monthly purchases
    static func currentMonthPredicate() -> Predicate<Purchase> {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        
        return #Predicate<Purchase> { purchase in
            purchase.date >= startOfMonth && purchase.date < startOfNextMonth
        }
    }
    
    // get weekly purchases
    static func currentWeekPredicate() -> Predicate<Purchase> {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let startOfNextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        
        return #Predicate<Purchase> { purchase in
            purchase.date >= startOfWeek && purchase.date < startOfNextWeek
        }
    }
    
    // get the current week & last week purchases for meal planner
    static func recentWeekPredicate() -> Predicate<Purchase> {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStartOfWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek) ?? now
        let startOfNextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        
        return #Predicate<Purchase> { purchase in
            purchase.date >= lastWeekStartOfWeek && purchase.date < startOfNextWeek
        }
    }
}
