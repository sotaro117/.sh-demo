import Foundation
import SwiftUI
import SwiftData
import UserNotifications
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "NotificationPreference")

// MARK: - Notification identifiers
private enum NotificationID {
    static let mealBreakfast = "meal-reminder-breakfast"
    static let mealLunch = "meal-reminder-lunch"
    static let mealDinner = "meal-reminder-dinner"
    static let monthlyExpense = "monthly-expense-summary"
    static let weeklyExpense = "weekly-expense-summary"
    static let lastPurchase = "last-purchase-reminder"
}

class NotificationPreference: ObservableObject {
    @AppStorage("mealReminder") var mealReminder = false
    @AppStorage("monthlyExpenseSummary") var monthlyExpenseSummary = false
    @AppStorage("weeklyExpenseSummary") var weeklyExpenseSummary = false
    @AppStorage("lastPurchaseReminder") var lastPurchaseReminder = false
}

// MARK: - Meal reminder

@MainActor
func mealReminderNotification(context: ModelContext, preferences: NotificationPreference) async {
    let center = UNUserNotificationCenter.current()
    let mealIDs = [NotificationID.mealBreakfast, NotificationID.mealLunch, NotificationID.mealDinner]
    center.removePendingNotificationRequests(withIdentifiers: mealIDs)

    guard preferences.mealReminder else {
        logger.debug("Meal reminder preference disabled")
        return
    }

    do {
        let currentUser = try await supabase.auth.session.user
        guard let meals = mealToReminder(userId: currentUser.id.uuidString, context: context),
              !meals.isEmpty else {
            logger.debug("No meals found to schedule reminders")
            return
        }

        for meal in meals {
            let hour: Int
            let identifier: String

            switch meal.meal {
            case .breakfast:
                hour = 7
                identifier = NotificationID.mealBreakfast
            case .lunch:
                hour = 12
                identifier = NotificationID.mealLunch
            case .dinner:
                hour = 18
                identifier = NotificationID.mealDinner
            }

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            await requestNotification(
                identifier: identifier,
                title: meal.meal.rawValue.capitalized,
                body: meal.plate,
                dateComponents: dateComponents
            )
        }
    } catch {
        logger.error("Meal reminder notification failed: \(error)")
    }
}

// MARK: - Monthly expense summary

@MainActor
func monthlyExpenseSummaryNotification(context: ModelContext, preferences: NotificationPreference) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [NotificationID.monthlyExpense])

    guard preferences.monthlyExpenseSummary else {
        logger.debug("Monthly expense summary preference disabled")
        return
    }

    do {
        let currentUser = try await supabase.auth.session.user
        guard let expenses = lastMonthExpense(userId: currentUser.id.uuidString, context: context),
              !expenses.isEmpty else {
            logger.debug("No last month expenses found")
            return
        }

        let total = expenses.reduce(0) { $0 + $1.total }

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 9
        dateComponents.minute = 0

        await requestNotification(
            identifier: NotificationID.monthlyExpense,
            title: "Last month expense",
            body: "You spent \(String(format: "%.2f", total))€ last month",
            dateComponents: dateComponents
        )
    } catch {
        logger.error("Monthly expense summary notification failed: \(error)")
    }
}

// MARK: - Weekly expense summary

@MainActor
func weeklyExpenseSummaryNotification(context: ModelContext, preferences: NotificationPreference) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [NotificationID.weeklyExpense])

    guard preferences.weeklyExpenseSummary else {
        logger.debug("Weekly expense summary preference disabled")
        return
    }

    do {
        let currentUser = try await supabase.auth.session.user
        guard let expenses = lastWeekExpense(userId: currentUser.id.uuidString, context: context),
              !expenses.isEmpty else {
            logger.debug("No last week expenses found")
            return
        }

        let total = expenses.reduce(0) { $0 + $1.total }

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0

        await requestNotification(
            identifier: NotificationID.weeklyExpense,
            title: "Last week expense",
            body: "You spent \(String(format: "%.2f", total))€ last week",
            dateComponents: dateComponents
        )
    } catch {
        logger.error("Weekly expense summary notification failed: \(error)")
    }
}

// MARK: - Last purchase reminder

@MainActor
func lastPurchaseReminderNotification(context: ModelContext, preferences: NotificationPreference) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [NotificationID.lastPurchase])

    guard preferences.lastPurchaseReminder else {
        logger.debug("Last purchase reminder preference disabled")
        return
    }

    do {
        let currentUser = try await supabase.auth.session.user
        guard let purchase = lastPurchase(userId: currentUser.id.uuidString, context: context) else {
            logger.debug("No last purchase found for reminder")
            return
        }

        let calendar = Calendar.current
        let timeToRemind = calendar.date(byAdding: .day, value: 1, to: purchase.date) ?? purchase.date

        // Include year, month, and day so the trigger fires on the correct date
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: timeToRemind)
        dateComponents.hour = 9
        dateComponents.minute = 0

        await requestNotification(
            identifier: NotificationID.lastPurchase,
            title: "Your last purchase at \(purchase.store)",
            body: "You spent \(String(format: "%.2f", purchase.total))€ in your last purchase",
            dateComponents: dateComponents
        )
    } catch {
        logger.error("Last purchase reminder notification failed: \(error)")
    }
}

// MARK: - Helpers

private func requestNotification(identifier: String, title: String, body: String, dateComponents: DateComponents) async {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    try? await UNUserNotificationCenter.current().add(request)
}

private func mealToReminder(userId: String, context: ModelContext) -> [MealPlan]? {
    let today = Calendar.current.startOfDay(for: Date())

    let descriptor = FetchDescriptor<MealPlan>(
        predicate: #Predicate<MealPlan> { mealPlan in
            mealPlan.userId == userId && mealPlan.date == today
        }
    )

    do {
        return try context.fetch(descriptor)
    } catch {
        logger.error("Failed to fetch meal reminders: \(error)")
        return nil
    }
}

private func lastMonthExpense(userId: String, context: ModelContext) -> [Purchase]? {
    let calendar = Calendar.current
    let now = Date()

    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? now

    let descriptor = FetchDescriptor<Purchase>(
        predicate: #Predicate<Purchase> { purchase in
            purchase.userId == userId && purchase.date >= startOfLastMonth && purchase.date < startOfMonth
        }
    )

    do {
        return try context.fetch(descriptor)
    } catch {
        logger.error("Failed to fetch last month expenses: \(error)")
        return nil
    }
}

private func lastWeekExpense(userId: String, context: ModelContext) -> [Purchase]? {
    let calendar = Calendar.current
    let now = Date()

    let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
    let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek) ?? now

    let descriptor = FetchDescriptor<Purchase>(
        predicate: #Predicate<Purchase> { purchase in
            purchase.userId == userId && purchase.date >= startOfLastWeek && purchase.date < startOfWeek
        }
    )

    do {
        return try context.fetch(descriptor)
    } catch {
        logger.error("Failed to fetch last week expenses: \(error)")
        return nil
    }
}

private func lastPurchase(userId: String, context: ModelContext) -> Purchase? {
    let descriptor = FetchDescriptor<Purchase>(
        predicate: #Predicate<Purchase> { purchase in
            purchase.userId == userId
        }
    )

    do {
        return try context.fetch(descriptor).last
    } catch {
        logger.error("Failed to fetch last purchase: \(error)")
        return nil
    }
}
