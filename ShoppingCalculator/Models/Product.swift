import Foundation
import SwiftData

@Model
class Product {
    var id: UUID
    var name: String
    var price: Decimal
    var quantity: Int
    var category: FoodCategory
    
    init(id: UUID = UUID(), name: String, price: Decimal, quantity: Int, category: FoodCategory) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.category = category
    }
    
    static let singleSampleData = [
        Product(name: "Jamon", price: 5.10, quantity: 2, category: .protein),
    ]
    
    static let sampleData: [[Product]] = [
        [
            Product(name: "Vegetable", price: 1.55, quantity: 1, category: .fruitVegetable),
            Product(name: "Fruit", price: 2.22, quantity: 1, category: .fruitVegetable),
            Product(name: "Meat", price: 5.60, quantity: 2, category: .protein),
        ],
        [
            Product(name: "Bread", price: 1.10, quantity: 1, category: .grain),
            Product(name: "Shrimp", price: 5.19, quantity: 1, category: .protein),
        ],
        [
            Product(name: "Jamon", price: 5.10, quantity: 2, category: .protein),
            Product(name: "huevos", price: 3.39, quantity: 1, category: .protein),
        ]
    ]
}

enum FoodCategory: String, CaseIterable, Identifiable, Codable {
    case fruitVegetable = "Fruit & Vegetable"
    case grain = "Grain"
    case protein = "Protein"
    case dairy = "Dairy"
    case fat = "Fat"
    case other = "Other"
    
    var id: String {
        self.rawValue
    }
}

