import SwiftUI
import AVFoundation
import Vision
import SwiftData

struct ScannerView: View {
    @State private var recognizedText = ""
    @State private var observations: [VNRecognizedTextObservation] = []
    @State private var price: Decimal = 0
    @State private var productName = ""
    @Environment(\.modelContext) private var context
    @Query private var product: [Product]
    @State private var quantity = 1
    @State private var isProcessing = false
    @Binding var image: UIImage?
    @StateObject private var imageRecognizer = ImageRecognizer()
    @Binding var productsList: [Product]
    @Binding var showScanModal: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if imageRecognizer.isProcessing {
                ProgressView("Reading...")
                    .zIndex(1)
            } else {
                VStack {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(imageRecognizer.productName)
                        .font(.title)
                        .padding(.vertical)
                    HStack(spacing: 80) {
                        
                        Text((imageRecognizer.price * Decimal(quantity)), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.title2)
                        
                        VStack {
                            StepperControl(value: $quantity, minValue: 1, maxValue: 50)
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Button {
                        productsList.append(Product(name: imageRecognizer.productName, price: imageRecognizer.price, quantity: quantity, category: imageRecognizer.category ?? .other))
                        showScanModal = false
                    } label: {
                        Text("Add")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(.white)
                            .padding(.vertical)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .padding()
        .ignoresSafeArea()
        .onChange(of: image) { oldImage, newImage in
            guard let newImage else { return }
            Task { await imageRecognizer.generate(image: newImage) }
        }
    }
}
