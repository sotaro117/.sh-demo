import Foundation
import SwiftUI
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "MealAnalyzer")

class MealAnalyzer: ObservableObject {
    var context: ModelContext?

    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
//    private var activeContext: ModelContext? {
//        context ?? environmentContext // Use injected context if available
//    }
    
    func generateSuggestion(purchases: [Purchase]) async {
        guard let url = URL(string: "https://api.openai.com/v1/responses"),
              let openaiApiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") else {
            logger.error("Missing URL or OpenAI API key")
            return
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
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
        
        var productFormatted: String {
            var result = ""

            for purchase in purchases {
                let dateString = formatDate(date: purchase.date)
                result += "\n** \(dateString) ** at \(purchase.store)"
                for product in purchase.products {
                    
                    result += "\n- \(product.name), (price)\(product.price), (quantity)\(product.quantity), (category)\(product.category)"
                }
            }
            logger.debug("Products formatted for analysis")
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
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        // Consideration //
        // Need to improve: overview / trends(patterns) / improvements
        // Make gpt produce output in a certain format such as splitted arrays up to sections ex.) [[h1 -> overview], [plain text -> description]]
        
        // Analyze meal habits & suggest improvements like by detecting tendencies which get your habits more balanced, nutritious or you could buy more a certain type of ingredients etc.
        logger.debug("Output language: \(outputLang, privacy: .public)")
        let prompt = """
         You are a helpful assistant tasked with analyzing, making suggestions or advices to help me with improving my meal habits based on provided purchases. Produce the analysis in the following language: \(outputLang). You must produce either one of the languages "english" or "spanish". 
         Keep it casual, summarized and simple, dont say yo, help me make new connections i don't see, comfort, validate, challenge, all of it. Keep in mind you are limited to producing 3000 tokens for analysis. Format with markdown if needed. Use "** **" for highlighted phrases and DO NOT USE "## ##" (headings) which is not supported. Avoid using unicode escape. you need to process everything I say, make connections I don't see it, and deliver it all back to me as an analysis that makes me feel what you think i wanna feel. Also keep in mind user"s preference to personalize the analysis: \(userPreference). thats what the best analysists do. In case you need updated information make use of tools to look for them in web search.
            Include sections for:
            (in english)
                1. Nutritional Overview
                2. Recommendations
                3. Areas for Improvement
            (if set in spanish specifically)
                1. Resumen de nutriciones
                2. Recomendaciones
                3. Áreas de mejoras
         
            Purchases:
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
                "content": prompt + productFormatted
                ]
            ],
            "tools": [
                ["type": "web_search_preview"]
            ],
            "max_output_tokens": 3000,
            "temperature": 1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Analysis API status: \(httpResponse.statusCode)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = AppError.api("Analysis service returned an error. Please try again.").userMessage
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
                                logger.debug("Analysis text extracted")
                                await MainActor.run {
                                    let report = Report(userId: userId, month: month, year: year, analysisText: text)
                                    self.context?.insert(report)
                                    do {
                                        try self.context?.save()
                                    } catch {
                                        logger.error("Failed to save meal report: \(error)")
                                        self.errorMessage = AppError.database(error.localizedDescription).userMessage
                                    }
                                    self.isProcessing = false
                                }
                                break
                            }
                        }
                    }
                }
            }
        } catch {
            let errMsg = error.localizedDescription
            logger.error("Analysis request failed: \(error)")
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = AppError.network(errMsg).userMessage
            }
        }
    }
    
    private func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
