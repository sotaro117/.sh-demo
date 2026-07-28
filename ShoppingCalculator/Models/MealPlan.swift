import Foundation
import SwiftData

@Model
class MealPlan {
    var userId: String
    var meal: Meal
    var plate: String
    var ingredients: [String]
    var date: Date
    // var user: User
    
    init(userId: String, meal: Meal, plate: String, ingredients: [String], date: Date) {
        self.userId = userId
        self.meal = meal
        self.plate = plate
        self.ingredients = ingredients
        self.date = date
    }
}

enum Meal: String, Identifiable, CaseIterable, Codable{
    case breakfast
    case lunch
    case dinner
    
    var id: String {
        rawValue
    }
}

extension MealPlan {
    /*
    static let sampleData: [MealPlan] = {
        let calendar = Calendar.current
        let now = Date()
        
        // Example: start from today’s date
        let startOfDay = calendar.startOfDay(for: now)
        

        return [
            MealPlan(
                meal: .breakfast,
                plate: "Tortilla de patatas",
                ingredients: ["patata", "cebolla", "sal", "aceite", "pimiento", "oliva", "salsa de bravas", "huevos", "panceta"],
                date: startOfDay
            ),
            MealPlan(
                meal: .lunch,
                plate: "Bravas",
                ingredients: ["patata", "salsa brava", "sal", "aceite"],
                date: calendar.date(byAdding: .day, value: 0, to: startOfDay)!
            ),
            MealPlan(
                meal: .dinner,
                plate: "Sushi",
                ingredients: ["atun", "salmon", "arroz", "vinagre"],
                date: calendar.date(byAdding: .day, value: 0, to: startOfDay)!
            ),
            MealPlan(
                meal: .breakfast,
                plate: "Pasta Carbonara",
                ingredients: ["pasta", "huevo", "sal", "guanciale"],
                date: calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            ),
            MealPlan(
                meal: .lunch,
                plate: "Onigiri",
                ingredients: ["arroz", "salmon", "sal"],
                date: calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            ),
            MealPlan(
                meal: .dinner,
                plate: "Udon Noodles",
                ingredients: ["noodle", "huevo", "caldo", "sopa"],
                date: calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            )
        ]
         
    }()
     */
}

extension MealPlan {
    static func currentWeekPredicate() -> Predicate<MealPlan> {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let startOfNextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        
        return #Predicate<MealPlan> { mealPlan in
            mealPlan.date >= startOfWeek && mealPlan.date < startOfNextWeek
        }
    }
}
