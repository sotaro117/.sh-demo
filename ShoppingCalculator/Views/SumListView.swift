import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "SumListView")

struct SumListView: View {
    // @Query private var products: [Product]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Binding var showScanner: Bool
    @State private var productQuantity = 1
    @Binding var productsList: [Product]
    @State private var offset: CGFloat = 0
    @State private var store = ""
    @EnvironmentObject private var userService: UserService
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var total: Decimal {
        productsList.reduce(Decimal(0)) { result, product in
            result + product.price * Decimal(product.quantity)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                VStack {
                    Rectangle()
                        .frame(width: 30, height: 3)
                        .cornerRadius(30)
                        .foregroundStyle(.gray)
                    
                    Text("Summary")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Text("Total")
                        .font(.title)
                        .padding()
                    Spacer()
                    Text(total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title)
                        .padding(.horizontal, 20)
                }
                
                Divider()
                
                TextField("Store Name", text: $store)
                    .padding()
                    .background(Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(3)
                
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Products")
                            .font(.title3)
                    }
                    .padding(.vertical, 3)
                    ForEach(productsList) { product in
                        GridRow {
                            HStack {
                                Text("\(product.name) x \(product.quantity)")
                                    .padding(.vertical, 2)
                                
                                Spacer()
                                
                                Text(product.price * Decimal(product.quantity), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                
                                    .padding(.horizontal)
                            }
                            
                            Button {
                                withAnimation {
                                    productsList.removeAll { $0.id == product.id }
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                            .accessibilityLabel("Remove \(product.name)")
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button {
                    // Check if userId is set
                    guard !userService.userId.isEmpty else {
                        logger.error("UserId is empty, cannot save purchase")
                        return
                    }
                    
                    isLoading = true
                    
                    let purchase = Purchase(userId: userService.userId, date: Date(), products: productsList, store: store)

                    context.insert(purchase)
                    
                    do {
                        try context.save()
                        logger.info("Purchase saved successfully")
                        isLoading = false
                        
                        // Clear the products list AFTER successful save
                        productsList = []
                        
                        // Dismiss AFTER successful save
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss()
                            showScanner = false
                        }
                    } catch {
                        isLoading = false
                        logger.error("Error saving purchase: \(error)")
                        alertMessage = AppError.database(error.localizedDescription).userMessage
                        showAlert = true
                    }
                    
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Finish")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.bg)
                            .padding()
                            .background(productsList.count == 0 || store.isEmpty ? .line.opacity(0.1) : .line)
                            .cornerRadius(25)
                    }
                }
                .disabled(productsList.count == 0 || store.isEmpty)
            }
            .padding()
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Allow dragging in both directions but only apply negative offset for left swipe
                        if value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100 // Minimum distance to trigger dismiss
                        
                        if value.translation.height > threshold {
                            // Swipe was far enough to the left, dismiss the modal
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = geometry.size.height // Animate off screen
                                dismiss()
                            }
                        } else {
                            // Swipe wasn't far enough, snap back to original position
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
            .task {
                await userService.load()
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}
