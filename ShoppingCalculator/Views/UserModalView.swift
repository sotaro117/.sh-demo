import SwiftUI

struct UserModalView: View {
    @Binding var showModal: Bool
    @EnvironmentObject private var userService: UserService
    @State private var offset: CGFloat = 0
        
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background overlay that can be tapped to dismiss
                    Color.black.opacity(0.01)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showModal = false
                            }
                        }
                    
                    // Modal content
                    VStack(alignment: .leading) {
                        
                        HStack(spacing: 10) {
                            if let avatarImage = userService.avatarImage {
                                avatarImage.image.resizable()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 70, height: 70)
                            }
                            
                            Text(userService.username ?? "username")
                                .font(.title)
                                .padding(.horizontal)
                        }
                        .padding(.top, 70)
                        .padding(.horizontal)
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Plan")
                                    .font(.headline)
                                
                                Spacer()
                                                     
                                Text("beta")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal)
                                    .background(Color.purple.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .foregroundStyle(.primary)
                                    .padding(.trailing)
                            }
                            .padding(.vertical, 2)

                            Text("Preference")
                                .font(.headline)
                                .padding(.vertical, 5)
                            
                            Text(userService.preference ?? "")
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .frame(width: geo.size.width * 0.9)
                    .frame(maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .cornerRadius(12)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Allow dragging in both directions but only apply negative offset for left swipe
                                if value.translation.width < 0 {
                                    offset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = -100 // Minimum distance to trigger dismiss
                                
                                if value.translation.width < threshold {
                                    // Swipe was far enough to the left, dismiss the modal
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = -geo.size.width // Animate off screen
                                        showModal = false
                                    }
                                } else {
                                    // Swipe wasn't far enough, snap back to original position
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                }
                            }
                    )
                    .ignoresSafeArea()
                }
            }
        }
}
