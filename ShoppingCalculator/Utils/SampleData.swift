import Foundation
import SwiftData

/*
// you’re declaring that all code in this class must run on the main actor
@MainActor
class SampleData {
    static let shared = SampleData()
    // The static keyword defines the shared property as belonging to the class itself, not each individual instance.
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var product: Product {
        Product.singleSampleData.first!
    }
    
    var purchase: Purchase {
        Purchase.sampleData.first!
    }
    
//    var user: User {
//        User.sampleData.first!
//    }
    
    private init(){
        // The schema of a model helps connect the classes
        // you define in your code to the data in the data store.
        let schema = Schema([
            Product.self,
//            User.self,
            Purchase.self,
            MealPlan.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            insertSampleData()
            
            try context.save()
        } catch {
            fatalError("Could not create modelContainer: \(error)")
        }
    }
    
    private func insertSampleData(){
        for product in Product.singleSampleData {
            context.insert(product)
        }
        
//        for user in User.sampleData {
//            context.insert(user)
//        }
        
        for purchase in Purchase.sampleData {
            context.insert(purchase)
        }
        
        for mealPlan in MealPlan.sampleData {
            context.insert(mealPlan)
        }
        
        /* many to many relation example
        Friend.sampleData[0].favouriteMovie = Movie.sampleData[1]
        Friend.sampleData[1].favouriteMovie = Movie.sampleData[0]
        Friend.sampleData[3].favouriteMovie = Movie.sampleData[4]
        Friend.sampleData[4].favouriteMovie = Movie.sampleData[0]
         */
    }
}
*/
