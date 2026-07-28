import Foundation
import SwiftData

@Model
class UserNotification {
    var userId: String
    var createdAt: Date
    var mealReminder: Bool
    var monthlyExpenseSummary: Bool
    var weeklyExpenseSummary: Bool
    var lastPurchaseReminder: Bool

    init(userId: String, mealReminder: Bool = false, monthlyExpenseSummary: Bool = false, weeklyExpenseSummary: Bool = false, lastPurchaseReminder: Bool = false) {
        self.userId = userId
        self.createdAt = Date()
        self.mealReminder = mealReminder
        self.monthlyExpenseSummary = monthlyExpenseSummary
        self.weeklyExpenseSummary = weeklyExpenseSummary
        self.lastPurchaseReminder = lastPurchaseReminder
    }
}
