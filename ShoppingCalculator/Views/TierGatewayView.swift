import SwiftUI
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "TierGatewayView")

struct TierGatewayView: View {
    @Environment(\.dismiss) private var dismiss
    let premiumPlanBenefits: [String] = [
        "1 ext account",
        "Cancel anytime",
        "Scan price tag",
        "Keep track of shopping",
        "Give dietary feedback",
        "Manage your meal",
        "Meal AI assistant",
        "Customize weekly meal plans"
    ]
    let price = 6.99
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .padding()
                }
            }
            
            Text("Ext")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Image(.initialLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding()
                .overlay {
                    Circle()
                        .stroke(.line.opacity(0.2), lineWidth: 1)
                }
                .padding(10)
            
            Text("Don't waste your time on planning what you cook or get.")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("\(price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))/month" )
            
            Text("Cancel anytime.")
                .font(.caption)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(premiumPlanBenefits, id: \.description) { benefit in
                    HStack {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .foregroundStyle(.green)
                            .padding(5)
                        
                        Text(benefit)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.line)
            .padding()
            .cornerRadius(10)
            .background(.line.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                Task {
                    await checkoutPayment()
                }
            } label: {
                Text("See Plan")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.line, in: RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.bg)
                    .padding()
            }
        }
        .padding()
    }
    
    func checkoutPayment() async {
        do {
            logger.debug("Initiating checkout request")
            let response: [String: String] = try await supabase.functions
                .invoke(
                    "stripe-checkout"
                )
            logger.debug("Checkout response received")
            
            guard let checkoutUrl = response["url"] else {
                throw NSError(domain: "No URL", code: 500)
            }
            
            if let url = URL(string: checkoutUrl) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        } catch FunctionsError.httpError(let code, _) {
            logger.error("Checkout function returned HTTP error code: \(code)")
          } catch FunctionsError.relayError {
            logger.error("Checkout relay error")
          } catch {
            logger.error("Checkout failed: \(error.localizedDescription)")
          }
    }
}
