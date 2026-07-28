import SwiftUI
import SwiftData
import FirebaseCore
import UIKit
import FirebaseMessaging
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "App")

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      application.registerForRemoteNotifications()
      FirebaseApp.configure()
      Messaging.messaging().delegate = self
      UNUserNotificationCenter.current().delegate = self
      
      return true
  }
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Messaging.messaging().apnsToken = deviceToken
//    }
    
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        if let fcm = Messaging.messaging().fcmToken {
//            print("fcm: ", fcm)
//            Task {
//                do {
//                    let currentUser = try await supabase.auth.user()
//                    
//                    try await supabase
//                        .from("profiles")
//                        .update(["fcm_token": fcm])
//                        .eq("id", value: currentUser.id)
//                        .execute()
//                } catch {
//                    print(error)
//                }
//            }
//         }
//    }
}

@main
struct ShoppingCalculatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authService = AuthService() // env obj
    @StateObject var userService = UserService()
    @State var returnDeepLink = false
    @StateObject var launchScreenState = LaunchScreenManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                ZStack {
                    if (returnDeepLink){
                        ContentView()
                    } else {
                        StartView()
                            .task {
                                try? await Task.sleep(for: Duration.seconds(1))
                                self.launchScreenState.dismiss()
                            }
                        
                        if launchScreenState.state != .finished {
                            LaunchScreenView()
                        }
                    }
                }
            }
            .font(.system(.body ,design: .rounded))
            .environmentObject(authService)
            .environmentObject(userService)
            .environmentObject(launchScreenState)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .modelContainer(for: [Report.self, Product.self, UserNotification.self, Purchase.self, MealPlan.self])
        // .modelContainer(SampleData.shared.modelContainer)
    }
    
    private func handleDeepLink(_ url: URL){
        guard url.scheme == "shoppingcalculator" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            logger.error("Invalid URL in deep link")
            return
        }
        
        if components.host == "payment-success" || components.host == "home" {
            logger.info("Deep link URL received")
            returnDeepLink = true
        }
    }
}


