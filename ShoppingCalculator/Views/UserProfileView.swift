import SwiftUI
import SwiftData
import PhotosUI
import Storage
import Supabase

struct UserProfileView: View {
    @EnvironmentObject private var userService: UserService
    @State private var isShowingEditModal = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let avatarImage = userService.avatarImage {
                    avatarImage.image.resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                
                Text(userService.username ?? "")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Button {
                    isShowingEditModal = true
                } label: {
                    Text("Edit")
                        .font(.headline)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .foregroundStyle(.primary)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.primary, lineWidth: 0.5)
                        }
                }
                
                VStack(alignment: .leading) {
                    Text("Preference")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(userService.preference ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Spacer()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isShowingEditModal) {
                NavigationStack {
                    UserEditModal()
                        .presentationDetents([.large])
                        .interactiveDismissDisabled()
                }
            }
            .background(Color.bg)
            .task {
                await userService.load()
            }
        }
    }
}
