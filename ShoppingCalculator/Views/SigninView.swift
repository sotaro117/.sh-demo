import SwiftUI

struct SigninView: View {
    @State private var isShowingModal = false
    @State private var text = "Shop smarter, eat better with .sh"
    
    var body: some View {
        VStack {
            Spacer()
            Image(.initialLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .padding()
            AnimatedText($text)
                .font(.system(.headline ,design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button {
                isShowingModal.toggle()
            } label: {
                Text("Get started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.2), in: RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.white)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingModal){
            SigninModal(showModal: $isShowingModal)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

