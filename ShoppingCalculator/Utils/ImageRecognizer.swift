import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "ImageRecognizer")

@MainActor
class ImageRecognizer: ObservableObject {
    @Published var productName = ""
    @Published var price: Decimal = 0
    @Published var category: FoodCategory?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    func generate(image: UIImage) async {
        guard let openaiApiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") else {
            logger.error("OpenAI API key not found")
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses"),
              let base64Data = image.base64 else {
            isProcessing = false
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // {"productName": "<name>", "price": "<price>"}
        let prompt = """
        You are a shopping assistant that helps with extracting a product, its price and food category based on the product. \
        Here is the image of a price tag in English, Spanish or any language. Extract the exact price, product name and food category and return ONLY ONE valid JSON in the given structure:
        
        Do not add any extra text, comments, or formatting. When analyzing the price tag, you have to extract exactly in detail such as considering applied discounts, unit price or something like that. The output must be ONE VALID JSON with "productName",  "price" and "category without any more items. You cannot put other than numerical values that are the most possible price at <price> which excludes units as well. The category must be one of the following nutirtious categories "fruitVegetable", "grain", "protein", "dairy", "fat", and "other". You can set "other" only when you recognize a product which is totally irrelevant to foods. Also you can only classifies from the described categories. 
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params: [String: Any] = [
            "model": "gpt-5-mini",
            "input": [
                [
                    "role": "user",
                    "content": [
                        ["type": "input_text", "text": prompt],
                        ["type": "input_image", "image_url": "data:image/jpeg;base64,\(base64Data)"]
                    ]
                ]
            ],
            "max_output_tokens": 1000,
            "temperature": 1,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "price_tag_extraction",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "productName": ["type": "string"],
                            "price": ["type": "number"],
                            "category": ["type": "string"]
                        ],
                        "required": ["productName", "price", "category"],
                        "additionalProperties": false
                    ],
                    "strict": true
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.error("Image recognition API returned status \(statusCode)")
                isProcessing = false
                errorMessage = AppError.api("Service returned an error. Please try again.").userMessage
                return
            }
            
            logger.debug("Image recognition API status: \(httpResponse.statusCode)")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let outputs = json["output"] as? [[String: Any]] {
                for output in outputs {
                    if output["type"] as? String == "message",
                       let contentArray = output["content"] as? [[String: Any]] {
                        for contentItem in contentArray {
                            if contentItem["type"] as? String == "output_text",
                               let text = contentItem["text"] as? String {
                                logger.debug("Raw model output received")
                                let innerData = text.replacingOccurrences(of: "\\", with: "")
                                
                                if let innerData = innerData.data(using: .utf8),
                                   let dict = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any] {
                                    // Set product name
                                    if let name = dict["productName"] as? String {
                                        logger.debug("Product name: \(name, privacy: .public)")
                                        productName = name.lowercased()
                                    }
                                    // Set price
                                    if let p = dict["price"] as? Double {
                                        logger.debug("Price extracted")
                                        price = Decimal(p)
                                    }
                                    // Set food category
                                    if let cat = dict["category"] as? String {
                                        logger.debug("Category: \(cat, privacy: .public)")
                                        switch cat {
                                        case "fruitVegetable": category = .fruitVegetable
                                        case "grain": category = .grain
                                        case "protein": category = .protein
                                        case "dairy": category = .dairy
                                        case "fat": category = .fat
                                        case "other": category = .other
                                        default: category = nil
                                        }
                                    }
                                } else {
                                    logger.error("Failed to parse JSON response from image recognition")
                                    errorMessage = AppError.api("Failed to parse response").userMessage
                                }
                                break
                            }
                        }
                    }
                }
            }
            isProcessing = false
        } catch {
            logger.error("Image recognition request failed: \(error)")
            isProcessing = false
            errorMessage = AppError.network(error.localizedDescription).userMessage
        }
    }
}

extension UIImage {
    var base64: String? {
        // Change from compressionQuality: 1 to 0.75 and resize
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return resized.jpegData(compressionQuality: 0.75)?.base64EncodedString()
    }
}
