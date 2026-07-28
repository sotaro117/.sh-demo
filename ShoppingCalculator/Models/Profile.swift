import Foundation
import SwiftData

/*
struct Profile: Codable {
    var id: UUID?
    var username: String?
    var tier: Tier
    var premiumStart: Date?
    var premiumEnd: Date?
    var premiumIsCancelled: Bool?
    var preference: String?
    var avatarUrl: String?
    var status: Status?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case tier
        case premiumStart = "premium_start"
        case premiumEnd = "premium_end"
        case premiumIsCancelled = "premium_is_cancelled"
        case preference
        case avatarUrl = "avatar_url"
        case status
    }
    
    enum Tier: String, Codable {
        case free
        case premium
    }
    
    enum Status: String, Codable {
        case active
        case deleted
    }
}
*/

struct Profile: Codable {
    var id: UUID?
    var username: String?
    var preference: String?
    var avatarUrl: String?
    var status: Status?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case preference
        case avatarUrl = "avatar_url"
        case status
    }
    
    enum Status: String, Codable {
        case active
        case deleted
    }
}
