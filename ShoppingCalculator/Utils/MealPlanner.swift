import Foundation
import SwiftData
import SwiftUI
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "MealPlanner")

// MARK: - Response Models
struct MealPlanResponse: Codable {
    let status: String?
    let interrupt: InterruptData?
    let state: StateData?
    let mealPlan: MealPlanSets?
    let mealProvidedInfo: MealInfo?
    let missingData: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case interrupt
        case state
        case mealPlan = "meal_plan"
        case mealProvidedInfo = "meal_provided_info"
        case missingData = "missing_data"
    }
}

struct InterruptData: Codable {
    let question: String
    let proposal: String?
}

struct StateData: Codable {
    let mealProvidedInfo: MealInfo?
    let missingData: String?
    let mealPlanProposal: String?
    let humanFeedback: String?
    
    enum CodingKeys: String, CodingKey {
        case mealProvidedInfo = "meal_provided_info"
        case missingData = "missing_data"
        case mealPlanProposal = "meal_plan_proposal"
        case humanFeedback = "human_feedback"
    }
}

struct MealInfo: Codable {
    let hasAllDetails: Bool
    let mealGoal: String
    let ingredients: String
    let preferences: String
    
    enum CodingKeys: String, CodingKey {
        case hasAllDetails = "has_all_details"
        case mealGoal = "meal_goal"
        case ingredients
        case preferences
    }
}

struct MealPlanSets: Codable {
    let plans: [MealPlanSet]
}

struct MealPlanSet: Codable {
    let meal: String
    let plate: String
    let ingredients: [String]
}

class MealPlanner: ObservableObject {
    var context: ModelContext?
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // Track conversation state
    private var awaitingResponse = false
    private var currentInterrupt: InterruptData?
    

    
    func generatePlan(purchases: [Purchase]) async {
        guard let openaiApiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") else {
            logger.error("OpenAI API key not found")
            return
        }
        
        logger.info("Generating meal plans")
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            await MainActor.run { self.isProcessing = false }
            return
        }
        let calendar = Calendar.current
        let userId: String
        let userPreference: String
        
        do {
            let currentUser = try await supabase.auth.session.user
            
            let profile: Profile =
            try await supabase
              .from("profiles")
              .select()
              .eq("id", value: currentUser.id)
              .single()
              .execute()
              .value
            
            userId = currentUser.id.uuidString
            userPreference = profile.preference ?? ""
        } catch {
            await MainActor.run { self.isProcessing = false }
            return
        }
        
        // prompt
        var productFormatted: String {
            var result = ""

            for purchase in purchases {
                let dateString = formatDate(purchase.date)
                result += "\n** \(dateString) **\n"
                for product in purchase.products {
                    result += "\(product.name), "
                }
            }
            logger.debug("Products formatted for meal planning")
            return result
        }
        
        var outputLang: String {
            let lang = Locale.current.language.languageCode?.identifier
            if lang == "es" {
                return "es"
            } else {
                return "en"
            }
        }
        
        // prompt
        var currentWeek: String {
            let now = Date()
            let year = calendar.component(.year, from: now)
            let month = calendar.component(.month, from: now)
            let week = calendar.component(.weekOfMonth, from: now)
            
            logger.debug("Target week: \(week)-\(month)-\(year)")
            
            return "\(week) - \(month) - \(year)"
        }
        
        logger.debug("Generating plan for user")
        
        let prompt = """
        You are a helpful assistant tasked with making healthy meal plan for breakfast, lunch and dinner to help users with creating their ideal routines. Produce plans in the following language \(outputLang)
        
        Please follow these instructions:
        1. **Make meal plans for a week(7days) based on the recent purchases and review the users preferencies carefully** to ensure some user do not suffer from allergies, food orientation(vegan, vegetarian) or cultural restrictions. Keep in mind that the user might have routine for certain purposes such as being on diet, muscle building, food preferencies or plates the user is good at. It is crucial not to skip any of these consideration or steps.
        2. **Organize the instructions into a logical, step-by-step order**, using the specified format.
        3. **Use the following format**:
           - **Return valid JSON in the given structure which is made of 21 items (3 meals a day * 7 days) that contain meal("breakfast", "lunch", "dinner" in order), plate, an array of all of its ingredients. Keep in mind the provided dates to plan a whole weekly meals. The output MUST be in the following ordder: breakfast -> lunch -> dinner and after that loop the same way like breakfast -> lunch -> dinner...
        - Plan meals for the week \(currentWeek). The date format is in order "week - month - year".
        4. **Review preferences & restrictions** not to provide harmful meals.
            - purchases: \(productFormatted)
            - preference: \(userPreference)
        
        **Important**: If at any point you are uncertain, respond with "I don't know."

        Please produce the ideal meal plan for me.
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params: [String: Any] = [
            "model": "o4-mini",
            "reasoning": ["effort": "medium"],
            "input": [
                [
                "role": "user",
                "content": prompt
                ]
            ],
            "max_output_tokens": 4000,
            "temperature": 1,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "meal_plan_generate",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "plans": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "meal": ["type": "string"],
                                        "plate": ["type": "string"],
                                        "ingredients": [
                                            "type": "array",
                                            "items": [
                                                "type": "string"
                                            ]
                                        ],
                                    ],
                                    "required": ["meal", "plate", "ingredients"],
                                    "additionalProperties": false
                                ]
                            ]
                        ],
                        "required": ["plans"],
                        "additionalProperties": false
                    ],
                    "strict": true
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Meal plan API status: \(httpResponse.statusCode)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = AppError.api("Meal plan service returned an error. Please try again.").userMessage
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let outputs = json["output"] as? [[String: Any]] {
                for output in outputs {
                    if output["type"] as? String == "message",
                       let contentArray = output["content"] as? [[String: Any]] {
                        for contentItem in contentArray {
                            if contentItem["type"] as? String == "output_text",
                               let text = contentItem["text"] as? String {
                                logger.debug("Meal plan text extracted")

                                guard let jsonData = text.data(using: .utf8) else { continue }

                                do {
                                    guard let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                          let rawPlans = parsed["plans"] as? [[String: Any]] else {
                                        continue
                                    }

                                    // Normalize: force exactly 7 days * 3 meals in order
                                    let expectedOrder: [Meal] = [.breakfast, .lunch, .dinner]

                                    // Convert raw to typed tuples; ignore invalid entries
                                    var remaining: [(meal: Meal, plate: String, ingredients: [String])] = rawPlans.compactMap { dict in
                                        guard let mealStr = dict["meal"] as? String,
                                              let plate = dict["plate"] as? String,
                                              let ingredients = dict["ingredients"] as? [String] else { return nil }
                                        let meal = Meal.allCases.first { $0.rawValue.lowercased() == mealStr.lowercased() }
                                        if let meal = meal {
                                            return (meal, plate, ingredients)
                                        }
                                        return nil
                                    }

                                    // Build normalized 21 plans in strict meal order
                                    var normalized: [(meal: Meal, plate: String, ingredients: [String])] = []
                                    for _ in 0..<7 {
                                        for expected in expectedOrder {
                                            if let matchIndex = remaining.firstIndex(where: { $0.meal == expected }) {
                                                normalized.append(remaining.remove(at: matchIndex))
                                            } else if !remaining.isEmpty {
                                                // Fallback: take next and coerce meal to expected
                                                var next = remaining.removeFirst()
                                                next.meal = expected
                                                normalized.append(next)
                                            } else {
                                                // If model returned fewer than 21, create a placeholder minimal entry
                                                normalized.append((expected, "", []))
                                            }
                                        }
                                    }

                                    // Dates: start from start of current week to align with UI
                                    let now = Date()
                                    let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? calendar.startOfDay(for: now)
                                    let dayDates: [Date] = (0..<7).compactMap { offset in
                                        calendar.date(byAdding: .day, value: offset, to: startOfWeek)
                                    }

                                    // Capture as let to avoid Swift 6 concurrency warning
                                    let normalizedPlans = normalized
                                    await MainActor.run {
                                        guard let context = self.context else {
                                            self.isProcessing = false
                                            return
                                        }

                                        // Overwrite: delete existing plans for each target day first
                                        for dayDate in dayDates {
                                            let startOfDay = calendar.startOfDay(for: dayDate)
                                            let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                                            let predicate = #Predicate<MealPlan> { plan in
                                                plan.date >= startOfDay && plan.date < startOfNextDay
                                            }
                                            var fetch = FetchDescriptor<MealPlan>(predicate: predicate)
                                            fetch.fetchLimit = 1000
                                            if let existing = try? context.fetch(fetch) {
                                                for plan in existing {
                                                    context.delete(plan)
                                                }
                                            }
                                        }

                                        // Insert normalized plans, 3 per day in order
                                        var insertCount = 0
                                        for dayIndex in 0..<7 {
                                            let dateForDay = dayDates[dayIndex]
                                            for mealIndex in 0..<3 {
                                                let idx = dayIndex * 3 + mealIndex
                                                let item = normalizedPlans[idx]
                                                // Skip empty placeholders
                                                if item.plate.isEmpty { continue }
                                                let newPlan = MealPlan(userId: userId, meal: item.meal, plate: item.plate, ingredients: item.ingredients, date: dateForDay)
                                                context.insert(newPlan)
                                                insertCount += 1
                                            }
                                        }

                                        do {
                                            try context.save()
                                            logger.info("Saved \(insertCount) normalized meal plans")
                                        } catch {
                                            logger.error("Failed to save meal plans: \(error)")
                                        }

                                        self.isProcessing = false
                                    }
                                } catch {
                                    logger.error("Meal plan JSON parse error: \(error)")
                                    await MainActor.run {
                                        self.isProcessing = false
                                        self.errorMessage = AppError.api("Failed to parse meal plan response").userMessage
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            logger.error("Meal plan generation failed: \(error)")
            await MainActor.run { self.isProcessing = false }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func chatAgent(prompt: String, userId: String, isResume: Bool = false, completion: @escaping (Result<MealPlanResponse, Error>) -> Void) async {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        // let url = URL(string: "https://sh-agent.onrender.com/chat-agent")!
        let testUrl = URL(string: "http://127.0.0.1:5000/chat-agent-test")!
        var request = URLRequest(url: testUrl)
          request.httpMethod = "POST"
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "input": prompt,
            "userid": userId
        ]
        
        if isResume {
            body["resume_input"] = prompt
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let error = NSError(domain: "AgentError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Agent returned status \(statusCode)"])
                await MainActor.run {
                    completion(.failure(error))
                    self.isProcessing = false
                }
                return
            }
            
            logger.debug("Agent API status: \(httpResponse.statusCode)")
            
            do {
                let mealPlanResponse = try JSONDecoder().decode(MealPlanResponse.self, from: data)
                logger.debug("Decoded agent response - status: \(mealPlanResponse.status ?? "nil", privacy: .public)")
                await MainActor.run {
                    completion(.success(mealPlanResponse))
                    self.isProcessing = false
                }
            } catch {
                logger.error("Agent response decode error: \(error)")
                await MainActor.run {
                    completion(.failure(error))
                    self.isProcessing = false
                }
            }
        } catch {
            logger.error("Agent request failed: \(error)")
            await MainActor.run {
                completion(.failure(error))
                self.isProcessing = false
            }
        }
    }
    
    func saveMealPlan(
        mealPlanSets: MealPlanSets,
        userId: String,
        completion: @escaping (String) -> Void
    ) {
        guard let context = context else {
            completion("Missing database context")
            return
        }
        
        let calendar = Calendar.current
        var savedCount = 0
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        
        // Overwrite: delete existing plans for today first
        let predicate = #Predicate<MealPlan> { plan in
            plan.date >= startOfDay && plan.date < startOfNextDay
        }
        var fetch = FetchDescriptor<MealPlan>(predicate: predicate)
        fetch.fetchLimit = 1000
        if let existing = try? context.fetch(fetch) {
            for plan in existing {
                context.delete(plan)
            }
        }
        
        // Insert all returned plans as today's entries
        for plan in mealPlanSets.plans {
            logger.debug("Storing meal plan into database")
            let meal = Meal.allCases.first(where: { $0.rawValue.lowercased() == plan.meal.lowercased() })
            
            guard let meal = meal else {
                logger.error("Invalid meal value in plan")
                continue
            }
            
            let mealPlan = MealPlan(
                userId: userId,
                meal: meal,
                plate: plan.plate,
                ingredients: plan.ingredients,
                date: startOfDay
            )
            logger.debug("Meal plan created")
            
            context.insert(mealPlan)
            savedCount += 1
        }
        
        logger.info("Finished creating meal plans")
        // Save to SwiftData
        do {
            try context.save()
            logger.info("Saved \(savedCount) meal plans for today")
            completion("Successfully saved meal plans!")
        } catch {
            logger.error("Failed to save meal plans: \(error)")
            completion("Failed to save meal plans: \(error)")
        }
    }
}
