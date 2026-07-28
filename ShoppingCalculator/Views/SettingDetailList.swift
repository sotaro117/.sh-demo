import SwiftUI
import Supabase
import SwiftData
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "SettingDetailList")

// MARK: Control setting views
struct SettingDetailList: View {
    var menuItem: String
    
    var body: some View {
        switch menuItem {
        case "Account":
            AccountSetting()
        case "Membership":
            PaymentSetting()
        case "Notification":
            NotificationSetting()
        case "Appearance":
            AppearanceSetting()
            
        default:
            Text("Default")
        }
    }
}

// MARK: Appearance setting
struct AppearanceSetting: View {
    @AppStorage("appearance") private var selectedAppearance: Appearance = .system
        
    var colorScheme: ColorScheme? {
        switch selectedAppearance {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Colour scheme")
                    .font(.title2)
                
                Text("Choose light or dark mode.")
                    .foregroundStyle(.gray)
                
                HStack(spacing: 7) {
                    ForEach(Appearance.allCases){ mode in
                        Button {
                            selectedAppearance = mode
                        } label: {
                            VStack {
                                switch mode {
                                case .light:
                                    Image(systemName: "sun.max")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .padding()
                                case .dark:
                                    Image(systemName: "moon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .padding()
                                case .system:
                                    Image(systemName: "moonphase.first.quarter")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .padding()
                                }
                                
                                Text(mode.rawValue)
                                    .tag(mode)
                            }
                        }
                        .padding()
                        .foregroundStyle(.line)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.line, lineWidth: 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
            Spacer()
        }
        .preferredColorScheme(colorScheme)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String {
        self.rawValue
    }
}

// MARK: Notification setting
struct NotificationSetting: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var userService: UserService
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var notificationPreference = NotificationPreference()
    @State var isEnabledNotification = false
    @State private var mealReminder = false
    @State private var monthlyExpenseSummary = false
    @State private var weeklyExpenseSummary = false
    @State private var lastPurchaseReminder = false
    
    var body: some View {
        VStack{
            List {
                VStack(alignment: .leading) {
                    Text("Don't miss updates!")
                        .font(.title3)
                    
                    Text("Turn on push notification to keep up with updates.")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .padding(.vertical)
                    
                    Button("Enable Notification"){
                        Task{
                            await notificationManager.request()
                        }
                    }
                }
                .padding()
                
                Section(
                    header: Text("reminder / report").fontWeight(.semibold)
                ) {
                    Toggle(isOn: $notificationPreference.mealReminder) {
                        Text("Notify meal plan")
                    }
                    
                    Toggle(isOn: $notificationPreference.weeklyExpenseSummary) {
                        Text("Notify last week's expense")
                    }
                    
                    Toggle(isOn: $notificationPreference.monthlyExpenseSummary) {
                        Text("Notify last month's expense")
                    }
                    
                    Toggle(isOn: $notificationPreference.lastPurchaseReminder) {
                        Text("Notify last purchase's expense")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationManager.getAuthStatus()
        }
        .onChange(of: notificationPreference.mealReminder) { _, _ in
            Task {
                await mealReminderNotification(context: context, preferences: notificationPreference)
            }
        }
        .onChange(of: notificationPreference.weeklyExpenseSummary){
            Task {
                await weeklyExpenseSummaryNotification(context: context, preferences: notificationPreference)
            }
        }
        .onChange(of: notificationPreference.monthlyExpenseSummary){
            Task {
                await monthlyExpenseSummaryNotification(context: context, preferences: notificationPreference)
            }
        }
        .onChange(of: notificationPreference.lastPurchaseReminder){
            Task {
                await lastPurchaseReminderNotification(context: context, preferences: notificationPreference)
            }
        }
    }
    
    private func saveNotification() async {
        guard !userService.userId.isEmpty else { return }
        let newNotificationPreference = UserNotification(
            userId: userService.userId,
            mealReminder: mealReminder,
            monthlyExpenseSummary: monthlyExpenseSummary,
            weeklyExpenseSummary: weeklyExpenseSummary,
            lastPurchaseReminder: lastPurchaseReminder
        )
        context.insert(newNotificationPreference)
        do {
            try context.save()
        } catch {
            logger.error("Failed to save notification preferences: \(error)")
        }
    }
}

// MARK: Payment setting
struct PaymentSetting: View {
//    @State private var tier: Profile.Tier?
    @State private var expiresAt: Date?
    @State private var isCancelled: Bool?
    let price: Double = 6.99
    let freePlanBenefits: [String] = [
        "1 free account",
        "Scan price tag",
        "Manage shopping",
        "Basic shppping analysis",
    ]
    let premiumPlanBenefits: [String] = [
        "1 ext account",
        "Cancel anytime",
        "Scan price tag",
        "Keep track of shopping",
        "Give dietary feedback",
        "Manage your meal",
        "Meal AI assistant",
        "Customize weekly meal plans"
    ]
    
    let betaBenefits: [String] = [
        "Try ext plan features",
        "Scan price tag",
        "Keep track of shopping",
        "Give dietary feedback",
        "Manage your meal",
        "Meal AI assistant",
        "Customize weekly meal plans"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Your Plan")
                    .font(.caption)
                    .padding(7)
                    .background(Color.primary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(Color(.systemBackground))
                
                // Up to tier (conditional)
                /*
                if let tier = tier {
                    if tier == .premium {
                        Text("Ext")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.purple.opacity(0.5))
                            .padding(.vertical)
                        
                        Text("\(isCancelled ?? false ? "Your plan is valid until \(formatDate(expiresAt))" : "Your plan will automatically renew on \(formatDate(expiresAt)). You'll be charged \(price, format: .currency(code: Locale.current.currency?.identifier ?? "USD")) per month").")
                            .font(.caption)
                        
                    } else {
                        Text("free")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.vertical)
                    }
                }
                */
                Text("beta")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.line)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding()
            
            Text("List of your benefits")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            VStack(alignment: .leading) {
                // Up to tier (conditional)
                /*
                if let tier = tier {
                    if tier == .premium {
                        ForEach(premiumPlanBenefits, id: \.description) { benefit in
                            HStack {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(.green)
                                    .padding(5)
                                
                                Text(benefit)
                                    .font(.subheadline)
                            }
                        }
                    } else {
                        ForEach(freePlanBenefits, id: \.description) { benefit in
                            HStack {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(.green)
                                    .padding(5)
                                
                                Text(benefit)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                */
                
                ForEach(betaBenefits, id: \.description) { benefit in
                    HStack {
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .foregroundStyle(.green)
                            .padding(5)
                        
                        Text(benefit)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.line)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding()
            
            VStack {
                Spacer()
                
                /*
                Group {
                    if let tier = tier {
                        // show button to charge for premium plan
                        if tier == .free {
                            Button {
                                Task {
                                    await checkoutPayment()
                                }
                            } label: {
                                Text("See plan")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.line, in: RoundedRectangle(cornerRadius: 20))
                                    .foregroundStyle(.bg)
                                    .padding()
                            }
                        } else {
                            Button {
                                Task {
                                    await managePayment()
                                }
                            } label: {
                                Text("Manage plan")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.line, in: RoundedRectangle(cornerRadius: 20))
                                    .foregroundStyle(.bg)
                                    .padding()
                            }
                        }
                    }
                }
                 */
            }
        }
        .background(.bg)
        .navigationTitle("Membership")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /*
    func checkoutPayment() async {
        do {
            print("Getting response...")
            let response: [String: String] = try await supabase.functions
                .invoke(
                    "stripe-checkout"
                )
            print("Response - checkout for subscription: ", response)
            
            guard let checkoutUrl = response["url"] else {
                throw NSError(domain: "No URL", code: 500)
            }
            
            if let url = URL(string: checkoutUrl) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        } catch FunctionsError.httpError(let code, let data) {
            print("Function returned code \(code) with response \(String(data: data, encoding: .utf8) ?? "")")
          } catch FunctionsError.relayError {
            print("Relay error")
          } catch {
            print("Other error: \(error.localizedDescription)")
          }
    }
    
    func managePayment() async {
        do {
            print("Proceed to manaage plan...")
            let response: [String: String] = try await supabase.functions
                .invoke("cancel-subscription")
            print("Response - manage subscriptioin: ", response)
            
            guard let billingPortalUrl = response["url"] else {
                throw NSError(domain: "No URL", code: 500)
            }
            
            if let url = URL(string: billingPortalUrl) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        } catch FunctionsError.httpError(let code, let data) {
            print("Function returned code \(code) with response \(String(data: data, encoding: .utf8) ?? "")")
          } catch FunctionsError.relayError {
            print("Relay error")
          } catch {
            print("Other error: \(error.localizedDescription)")
          }
    }
     */
    
    private func formatDate(_ date: Date?) -> String {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: date)
        }
        
        return ""
    }
}
    
// MARK: Account setting
struct AccountSetting: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var context
    @State private var selectedOption: AccountInfo? = nil
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var showDeleteAlert = false
    @State private var signinMethod: SigninScreen?
    @State private var showDetailModal = false
    
    var body: some View {
        List {
            Section(
                header: Text("basic info").fontWeight(.semibold)
            ) {
                Button {
                    signinMethod = .email
                    showDetailModal = true
                } label: {
                    HStack {
                        Text("Email")
                        
                        Spacer()
                        
                        Text(email.isEmpty ? "" : "\(email.prefix(15))...")
                            .foregroundStyle(.line.opacity(0.3))
                        
                        Image(systemName: "pencil")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10, height: 10)
                            .padding(5)
                    }
                }
                
                Button {
                    signinMethod = .phone
                    showDetailModal = true
                } label: {
                    HStack {
                        Text("Phone Number")
                        
                        Spacer()
                        
                        Text(phoneNumber.isEmpty ? "" : "\(phoneNumber.prefix(15))...")
                            .foregroundStyle(.primary.opacity(0.3))
                        
                        Image(systemName: "pencil")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10, height: 10)
                            .padding(5)
                    }
                }
            }
            
            Button("Delete Account"){
                showDeleteAlert = true
            }
            .foregroundStyle(.red)
            .alert("Delete account", isPresented: $showDeleteAlert){
                Button(role: .destructive){
                    Task {
                        await authService.deleteUser(modelContext: context)
                    }
                } label: {
                    Text("Delete")
                }
                
                Button("Cancel", role: .cancel){}
            } message: {
                VStack {
                    Text("Are you sure you want to delete your account?")
                    Text("This action cannot be undone.")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $signinMethod){ method in
            SigninDetailModal(
                signinMethod: method,
                isInitialSignin: false
            )
            .presentationDragIndicator(.visible)
        }
        .task {
            await getUserData()
        }
    }
    
    func getUserData() async {
        do {
            let currentUser = try await supabase.auth.user()
            
            self.email = currentUser.email ?? ""
            self.phoneNumber = currentUser.phone ?? ""
        } catch {
            logger.error("Failed to fetch user account data: \(error)")
        }
    }
}

enum AccountInfo: Identifiable {
    case email
    case phoneNumber
    
    var id: Self {
        self
    }
}
