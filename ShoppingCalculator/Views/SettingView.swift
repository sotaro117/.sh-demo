import SwiftUI

struct SettingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject private var userService: UserService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    NavigationLink {
                        UserProfileView()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if let avatarImage = userService.avatarImage {
                                    avatarImage.image.resizable()
                                        .clipShape(Circle())
                                        .frame(width: 60, height: 60)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundStyle(.primary)
                                }
                                VStack(alignment: .leading) {
                                    Text(userService.username ?? "")
                                        .font(.title2).bold()
                                        .foregroundStyle(.line)
                                    HStack {
                                        Text("Edit Profile")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 10, height: 10)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    SettingSection(fields: [SettingField(iconName: .account, label: "Account", navigationIcon: "chevron.right"), SettingField(iconName: .membership, label: "Membership", navigationIcon: "chevron.right")])
                    
                    SettingSection(title: "Preference", fields: [SettingField(iconName: .notification, label: "Notification", navigationIcon: "chevron.right"), SettingField(iconName: .theme, label: "Appearance", navigationIcon: "chevron.right")])
                    
                    SettingSection(title: "Resources", fields: [SettingField(iconName: .contact, label: "Contact", navigationIcon: ""), SettingField(iconName: .rate, label: "Rate", navigationIcon: "line.diagonal.arrow"), SettingField(iconName: .follow, label: "Follow on X", navigationIcon: "line.diagonal.arrow")])
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await authService.signOut()
                            }
                    } label: {
                        Text("Sign out")
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color(white: 0.9), in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .fontWeight(.bold)
                }
            }
            .toolbarRole(.editor)
            .task {
                await userService.load()
            }
        }
    }
}

struct SettingField: View {
    @Environment(\.openURL) private var openUrl
    let iconName: ImageResource
    let label: String
    let navigationIcon: String
    let navigationDest = ""
    @State private var showAlert = false
    @State private var alert = ""
    
    // @ViewBuilder let content: Content
    // Annotate the content variable with @ViewBuilder. View builders let you provide parameters as closures. Then, update the preview to use the SwiftUI closure style instead of an explicit parameter.
    
    var body: some View {
        Group {
            if label == "Contact" {
                Button {
                    sendEmail()
                } label: {
                    HStack {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                            .foregroundStyle(.line)
                        Text(label)
                            .foregroundStyle(.line)
                        Spacer()
                        Image(systemName: navigationIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(.trailing, 8)
                            .foregroundStyle(Color(white: 0.7))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                }
                .alert("Email", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alert)
                }
                
            } else if label == "Rate" || label == "Follow on X" {
                Button {
                    if label == "Rate" {
                        exitToApplestore()
                    } else if label == "Follow on X" {
                        exitToX()
                    }
                } label: {
                    HStack {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                            .foregroundStyle(.line)
                        Text(label)
                            .foregroundStyle(.line)
                        Spacer()
                        Image(systemName: navigationIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(.trailing, 8)
                            .foregroundStyle(Color(white: 0.7))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                }
            } else {
                NavigationLink {
                    SettingDetailList(menuItem: label)
                } label: {
                    HStack {
                        Image(iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                            .foregroundStyle(.line)
                        Text(label)
                            .foregroundStyle(.line)
                        Spacer()
                        Image(systemName: navigationIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .padding(.trailing, 8)
                            .foregroundStyle(Color(white: 0.7))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                }
            }
        }
    }
    
    private func sendEmail() {
        let emailString = "mailto:s.takahata.business@gmail.com"
        guard let url = URL(string: emailString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                UIPasteboard.general.string = emailString
                alert = "No email app found. Email address copied to clipboard: \(emailString)"
                showAlert = true
            }
        }
    }
    
    private func exitToX() {
        let urlString = "https://x.com/IAmSotaBuild"
        guard let url = URL(string: urlString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                alert = "No url found."
                showAlert = true
            }
        }
    }
    
    private func exitToApplestore() {
        let urlString = "https://www.apple.com/app-store/" // set the correct url later
        guard let url = URL(string: urlString) else { return }
        
        openUrl(url) { accepted in
            if !accepted {
                alert = "No url found."
                showAlert = true
            }
        }
    }
}

struct SettingSection: View {
    var title: String = ""
    var fields: [SettingField]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.secondary)
            VStack(spacing: 0) {
                ForEach(0..<fields.count, id: \.self) { i in
                    fields[i]
                }
            }
        }
        .padding()
    }
}
