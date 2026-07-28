import SwiftUI

struct HistoryDetail: View {
    @Environment(\.dismiss) private var dismiss
    let purchase: Purchase
    @Binding var showDetail: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd/MM/yyyy"
        return formatter.string(from: purchase.date)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .resizable()
                    .frame(width: 15, height: 10)
                    .foregroundStyle(.line)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 8)
            }
            
            Text(purchase.store)
                .font(.title)
                .padding(.vertical, 10)
            
            Text("- \(purchase.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(formattedDate)
                .foregroundStyle(.gray)
            
            Grid {
                ForEach(purchase.products) { product in
                    GridRow {
                        HStack {
                            Text("\(product.name) x \(product.quantity)")
                                .font(.headline)
                            Spacer()
                        }

                        Text("- \(product.price * Decimal(product.quantity), format: .number.precision(.fractionLength(2)))€")
                            .font(.headline)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
            
            
}
