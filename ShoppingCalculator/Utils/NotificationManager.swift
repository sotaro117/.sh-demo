import Foundation
import UserNotifications
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "NotificationManager")

@MainActor /// These methods should be called from the main UI thread to ensure thread safety
class NotificationManager: ObservableObject {
    @Published var hasPermission = false
    
    init() {
        Task {
            /// Check the notification permission status
            await getAuthStatus()
        }
    }
    
    /// Request notification status
    func request() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await getAuthStatus()
        } catch {
            logger.error("Notification authorization request failed: \(error)")
        }
    }
    
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        default:
            hasPermission = false
        }
    }
}
