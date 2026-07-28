import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "UserService")

@MainActor
class UserService: ObservableObject {
    @Published var userId: String = ""
    @Published var username: String?
    @Published var preference: String?
    @Published var avatarImage: AvatarImage?

    func load() async {
        guard userId.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        do {
            let currentUser = try await supabase.auth.session.user
            userId = currentUser.id.uuidString
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            username = profile.username
            preference = profile.preference
            if let avatarUrl = profile.avatarUrl, !avatarUrl.isEmpty {
                let data = try await supabase.storage.from("avatars").download(path: avatarUrl)
                avatarImage = AvatarImage(data: data)
            }
        } catch {
            logger.error("Failed to load user profile: \(error)")
        }
    }
}
