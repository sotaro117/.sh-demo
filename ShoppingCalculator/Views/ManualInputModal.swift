import SwiftUI

struct ManualInputModal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var productsList: [Product]
    @State private var productName = ""
    @State private var price: Decimal = 0
    @State private var quantity = 1
    @State private var category: FoodCategory = .fruitVegetable
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Enter product info")
                    .font(.title2)
                Text("You can enter product details manually!")
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.top)
            .padding(.bottom, 3)
            .padding(.horizontal)
            
            TextField("Enter Product", text: $productName)
                .font(.title3)
                .padding()
                .background(Color(.systemFill))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding()
            
            HStack(spacing: 5) {
                Text("Category: ")
                                
                Picker("Select Category", selection: $category) {
                    ForEach(FoodCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
                .pickerStyle(.automatic)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                TextField("Enter Price", value: $price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title2)
                    .padding()
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .keyboardType(.decimalPad)
                    .padding()
                
                VStack {
                    StepperControl(value: $quantity, minValue: 1, maxValue: 50)
                }
                .padding()
            }
            
            Spacer()
            
            Button {
                productsList.append(Product(name: productName, price: price, quantity: quantity, category: category))
                dismiss()
            } label: {
                Text("Add")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(productName.isEmpty || price <= 0 || category.rawValue.isEmpty ? .line.opacity(0.1) : .line, in: RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.bg)
                    .padding(.vertical)
            }
            .disabled(productName.isEmpty || price <= 0 || category.rawValue.isEmpty)
        }
        .padding()
    }
}
