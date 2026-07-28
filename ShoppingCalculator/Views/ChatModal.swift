import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "ChatModal")

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    var isLoading: Bool = false
    var proposal: String? = nil
    var mealPlan: MealPlanSets? = nil
    var showQuickActions: Bool = false
}

struct ChatModal: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var userService: UserService
    @StateObject private var mealPlanner = MealPlanner()
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var awaitingResponse = false
    @State private var showQuickAction = false

    var body: some View {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("AI Meal Planner")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if awaitingResponse {
                        Text("Waiting for your response...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, onQuickAction: { action in
                                    handleQuickAction(action)
                                })
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input
                HStack(spacing: 12) {
                    TextField(
                        awaitingResponse ? "Type your response..." : "Describe your meal preferences...",
                        text: $inputText,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    
                    Button {
                        Task {
                            await sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(inputText.isEmpty ? .gray : .purple)
                    }
                    .disabled(inputText.isEmpty || mealPlanner.isProcessing)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .onAppear {
                mealPlanner.context = context
                
                let welcomeMessage = ChatMessage(
                    content: "👋 Welcome! Tell me what you'd like to eat, and I'll create a personalized meal plan for you.",
                    isUser: false
                )
                messages.append(welcomeMessage)
            }
            .task {
                await userService.load()
            }
        }
        
        // MARK: - Send Message
        private func sendMessage() async {
            let userInput = inputText
            guard !userInput.isEmpty else { return }
            
            // Add user message
            let userMessage = ChatMessage(content: userInput, isUser: true)
            await MainActor.run {
                messages.append(userMessage)
                inputText = ""
            }
            
            // Add loading indicator
            let loadingMessage = ChatMessage(content: "", isUser: false, isLoading: true)
            await MainActor.run {
                messages.append(loadingMessage)
            }
            
            // Call API
            await mealPlanner.chatAgent(
                prompt: userInput,
                userId: userService.userId.isEmpty ? "default_user" : userService.userId,
                isResume: awaitingResponse
            ) { result in
                // Remove loading message
                if let loadingIndex = messages.firstIndex(where: { $0.isLoading }) {
                    messages.remove(at: loadingIndex)
                }
                
                switch result {
                case .success(let response):
                    handleResponse(response)
                    
                case .failure(let error):
                    let errorMessage = ChatMessage(
                        content: "❌ Error: \(error.localizedDescription)",
                        isUser: false
                    )
                    messages.append(errorMessage)
                }
            }
        }
        
        // MARK: - Handle Response
    private func handleResponse(_ response: MealPlanResponse) {
            logger.debug("Handling response - Status: \(response.status ?? "nil", privacy: .public)")
            
            switch response.status {
            case "interrupted":
                // Workflow paused, waiting for user input
                handleInterrupted(response)
                
            case "completed":
                // Workflow completed with final meal plan
                handleCompleted(response)
                
            default:
                // Handle missing data or other states
                if let missingData = response.missingData {
                    let message = ChatMessage(
                        content: missingData,
                        isUser: false
                    )
                    messages.append(message)
                    awaitingResponse = true
                }
            }
        }
        
        private func handleInterrupted(_ response: MealPlanResponse) {
            guard let interrupt = response.interrupt else { return }
            
            awaitingResponse = true
            
            var message = ChatMessage(
                content: interrupt.question,
                isUser: false
            )
            
            // If there's a proposal, add it to the message
            if let proposal = interrupt.proposal {
                message.proposal = proposal
                message.showQuickActions = true
            }
            
            messages.append(message)
        }
        
        private func handleCompleted(_ response: MealPlanResponse) {
            awaitingResponse = false
            
            guard let mealPlan = response.mealPlan else {
                let message = ChatMessage(
                    content: "✅ Meal plan completed!",
                    isUser: false
                )
                messages.append(message)
                return
            }
            
            // Show completion message with meal plan
            let message = ChatMessage(
                content: "🎉 Great! Here's your personalized meal plan:",
                isUser: false,
                mealPlan: mealPlan
            )
            messages.append(message)
            
            // Save to database
            if !userService.userId.isEmpty {
                mealPlanner.saveMealPlan(
                    mealPlanSets: mealPlan,
                    userId: userService.userId
                ) { result in
                    let resultMessage = ChatMessage(
                        content: result,
                        isUser: false
                    )
                    messages.append(resultMessage)
                }
            }
        }
        
        // MARK: - Quick Actions
        private func handleQuickAction(_ action: String) {
            inputText = action
            Task {
                await sendMessage()
            }
        }
        
}

// MARK: - Message Bubble View
struct MessageBubble: View {
    let message: ChatMessage
    let onQuickAction: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .frame(maxWidth: 280, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if message.isLoading {
                        ThreeDots()
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(18)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            // Main content
                            if !message.content.isEmpty {
                                Text(message.content)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(18)
                            }
                            
                            // Proposal
                            if let proposal = message.proposal {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Proposed Meal Plan:")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(proposal)
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Meal plan
                            if let mealPlan = message.mealPlan {
                                MealPlanView(mealPlan: mealPlan)
                            }
                            
                            // Quick action buttons
                            if message.showQuickActions {
                                HStack(spacing: 8) {
                                    Button {
                                        onQuickAction("Yes, looks perfect!")
                                    } label: {
                                        Label("Approve", systemImage: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(20)
                                    }
                                    
                                    Button {
                                        onQuickAction("I'd like to make some changes")
                                    } label: {
                                        Label("Change", systemImage: "pencil.circle.fill")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.orange)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 280, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

// MARK: - Meal Plan View
struct MealPlanView: View {
    let mealPlan: MealPlanSets
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(mealPlan.plans, id: \.meal) { plan in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(plan.meal.capitalized)
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    
                    Text(plan.plate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(plan.ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Flow Layout (for ingredient tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
