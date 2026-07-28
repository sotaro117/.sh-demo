import SwiftUI
import PhotosUI
import Storage
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "UserEditModal")

struct UserEditModal: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userService: UserService
    @State private var isChanged = false
    @State private var username = ""
    @State private var preference = ""
    @State private var showAlert = false
    @State private var alert = ""
    
    @State var imageSelection: PhotosPickerItem?
    @State var avatarImage: AvatarImage?
    
    var body: some View {
        VStack {
            Group {
                if let avatarImage {
                  avatarImage.image.resizable()
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
              }
              .scaledToFit()
              .frame(width: 120, height: 120)
              .overlay {
                  PhotosPicker(selection: $imageSelection, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                      .symbolRenderingMode(.multicolor)
                      .font(.system(size: 30))
                      .foregroundColor(.bg)
                      .frame(alignment: .trailing)
                      .offset(x: 30, y: 30)
                  }
              }
            
            HStack(spacing: 70) {
                Text("Name")
                TextField("username", text: $username)
                    .font(.title2)
            }
            .padding(3)
            .overlay (
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray),
                alignment: .bottom
            )
            .padding()
            
            Text("Preference")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 10)
            TextField("ex.) I like meat but i'm allergy to peanut...", text: $preference, axis: .vertical)
                .multilineTextAlignment(.leading)
                .padding()
                .background(colorScheme == .light ? .black.opacity(0.05) : .black.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // update username
                    updateProfile()
                } label: {
                    Text("save")
                }
                .alert("Error", isPresented: $showAlert){
                    Button("OK", role: .cancel){}
                } message: {
                    Text(alert.isEmpty ? "An unexpected error occurred." : alert)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("cancel")
                }
            }
        }
        .onChange(of: imageSelection) { _, newValue in
          guard let newValue else { return }
          loadTransferable(from: newValue)
        }
        .task {
            username = userService.username ?? ""
            preference = userService.preference ?? ""
            avatarImage = userService.avatarImage
        }
    }
    
    func updateProfile() {
        Task {
            do {
                let imageUrl = try await uploadImage()
                
                let currentUser = try await supabase.auth.session.user
                
                let updatedUser = Profile(
                    username: username,
                    preference: preference,
                    avatarUrl: imageUrl
                )
                
                try await supabase
                    .from("profiles")
                    .update(updatedUser)
                    .eq("id", value: currentUser.id)
                    .execute()
                
                await userService.refresh()
                dismiss()
            } catch {
                logger.error("Failed to update profile: \(error)")
                showAlert = true
                alert = error.localizedDescription
                return
            }
        }
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
      Task {
        do {
          avatarImage = try await imageSelection.loadTransferable(type: AvatarImage.self)
        } catch {
          logger.error("Failed to load avatar image: \(error)")
        }
      }
    }
    
    private func uploadImage() async throws -> String? {
      guard let data = avatarImage?.data else { return nil }
      let filePath = "\(UUID().uuidString).jpeg"
      try await supabase.storage
        .from("avatars")
        .upload(
          filePath,
          data: data,
          options: FileOptions(contentType: "image/jpeg")
        )
      return filePath
    }
}
