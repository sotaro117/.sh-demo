import SwiftUI
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "StartView")

struct StartView: View {
    @State var isSignedIn = false
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if isSignedIn {
                withAnimation {
                    ContentView()
                }
            } else {
                withAnimation {
                    SigninView()
                }
            }
        }
        .task {
            for await (event, session) in supabase.auth.authStateChanges {
              logger.debug("Auth event: \(event.rawValue, privacy: .public)")
                if [.initialSession, .signedIn, .userUpdated, .tokenRefreshed].contains(event) {
                    logger.info("Auth state: signed in")
                    isSignedIn = session != nil
                } else {
                    logger.info("Auth state: signed out")
                    isSignedIn = false
                }
            }
        }
        .onChange(of: authService.signedIn) { _, newVal in
            isSignedIn = newVal
        }
    }
}
