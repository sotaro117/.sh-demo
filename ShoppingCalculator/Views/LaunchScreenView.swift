import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject private var launchScreenState: LaunchScreenManager // Mark 1

    @State private var firstAnimation = false  // Mark 2
    @State private var secondAnimation = false // Mark 2
    @State private var startFadeoutAnimation = false // Mark 2
    
    private let animationTimer = Timer // Mark 5
        .publish(every: 0.5, on: .current, in: .common)
        .autoconnect()
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ZStack {
                // Logo
                if !secondAnimation {
                    Image(.sh)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                
                // Circle positioned at bottom-leading corner
                Circle()
                    .fill(.purple.opacity(0.8))
                    .frame(width: 13, height: 13)
                    .scaleEffect(secondAnimation ? 200 : 1)
                    .offset(x: -20, y: -10)
                    .frame(width: 60, height: 60, alignment: .bottomLeading)
            }
        }
        .onReceive(animationTimer) { timerValue in
            updateAnimation()  // Mark 5
        }
    }
    
    private func updateAnimation() {
        switch launchScreenState.state {
         case .firstStep:
             withAnimation(.easeInOut(duration: 0.9)) {
                 firstAnimation.toggle()
             }
         case .secondStep:
             if secondAnimation == false {
                 withAnimation(.linear(duration: 1)) {
                     self.secondAnimation = true
                 }
             }
         case .finished:
             break
         }
    }
}
