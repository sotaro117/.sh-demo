import SwiftUI

struct CameraView: View {
    @Binding var showScanner: Bool
    @ObservedObject var viewModel = CameraViewModel()
    @State private var isFocused = false
    @State private var focusLocation: CGPoint = .zero
    @State private var isScaled = false /// To  scale the view
    @State private var showScanModal = false
    @State private var showReviewModal = false
    @State private var showManualModal = false
    @State private var productsList: [Product] = []
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack {
                        Rectangle()
                            .frame(width: 30, height: 3)
                            .cornerRadius(20)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack(alignment: .center) {
                        Button {
                            withAnimation {
                                showScanner = false
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .resizable()
                                .frame(width: 18, height: 12)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Button {
                                withAnimation {
                                    showManualModal = true
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal)
                            
                            Button {
                                withAnimation {
                                    showReviewModal = true
                                }
                            } label: {
                                Image(.shoppingCart)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.white)
                                    .overlay {
                                        Text("\(productsList.count)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .offset(y: -17)
                                    }
                            }
                            .symbolEffect(.bounce.down, value: productsList.count)
                        }
                    }
                    .padding()
                    
                    CameraPreview(session: viewModel.session) { tapPoint in
                        isFocused = true
                        focusLocation = tapPoint
                        viewModel.setFocus(point: tapPoint)
                        
                        /// Provide haptic feedback to enhance the user experience
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    
                    CaptureButton(action: {viewModel.captureImage()}, showScanModal: $showScanModal)
                        .padding()
                }
                
                if isFocused {
                    FocusView(position: $focusLocation)
                        .scaleEffect(isScaled ? 0.8 : 1)
                        .onAppear {
                            /// Add a springy animation effect for visual appeal
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)){
                                self.isScaled = true
                                /// Return to the default state after 0.6 seconds for an elegant user experience
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    self.isFocused = false
                                    self.isScaled = false
                                }
                            }
                        }
                }
            }
            .alert(isPresented: $viewModel.showAlertError) {
                Alert(title: Text(viewModel.alertError.title), message: Text(viewModel.alertError.message), dismissButton: .default( Text(viewModel.alertError.primaryButtonTitle), action: { viewModel.alertError.primaryAction?()
                }))
            }
            .alert(isPresented: $viewModel.showSettingAlert) {
                Alert(title: Text("Warning"), message: Text("Application does not have all permissions to use camera and microphone, please check out privacy settings."), dismissButton: .default(Text("Go to settings"), action: {
                    self.openSettings()
                }))
            }
            .onAppear {
                viewModel.setupBindings()
                viewModel.checkForDevicePermission()
            }
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
                                showScanner = false
                            }
                        } else {
                            // Swipe wasn't far enough, snap back to original position
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
            .sheet(isPresented: $showScanModal) {
                ScannerView(image: $viewModel.capturedImage, productsList: $productsList, showScanModal: $showScanModal)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showManualModal) {
                ManualInputModal(productsList: $productsList)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showReviewModal){
                SumListView(showScanner: $showScanner, productsList: $productsList)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    /// Use to open app's setting
    func openSettings() {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

//#Preview {
//    @Previewable @State var showScanner = true
//    CameraView(showScanner: $showScanner)
//}

struct CaptureButton: View {
    var action: () -> Void
    @Binding var showScanModal: Bool
    
    var body: some View {
        Button {
            action()
            showScanModal = true
        } label: {
            Circle()
                .foregroundStyle(.white)
                .frame(width: 70, height: 70, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 59, height: 59, alignment: .center)
                )
        }
    }
}

struct FocusView: View {
    @Binding var position: CGPoint
    
    var body: some View {
        Circle()
            .frame(width: 70, height: 70)
            .foregroundColor(.clear)
            .border(Color.yellow, width: 1.5)
            .position(x: position.x, y: position.y)
    }
}

//MARK: REFERENCE
/*
if let image = viewModel.capturedImage {
    Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
} else {
    Rectangle()
        .frame(width: 50, height: 50, alignment: .center)
        .foregroundColor(.black)
}
 */
