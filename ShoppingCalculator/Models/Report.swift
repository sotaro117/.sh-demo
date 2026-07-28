import Foundation
import SwiftData

@Model
class Report: Identifiable {
    var id = UUID()
    var userId: String
    var month: Int
    var year: Int
    var analysisText: String
    var generatedAt: Date
    
    init(userId: String, month: Int, year: Int, analysisText: String) {
        self.id = UUID()
        self.userId = userId
        self.month = month
        self.year = year
        self.analysisText = analysisText
        self.generatedAt = Date()
    }
    
    /*
    static let sampleData = [
        Report(month: 1, year: 2024, analysisText: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."),
        Report(month: 2, year: 2021, analysisText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
    ]
     */
}
