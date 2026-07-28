import SwiftUI
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ShoppingCalculator", category: "AnalysisView")

struct AnalysisView: View {
    @Environment(\.modelContext) private var context
    
    // MARK: - Queries
    @Query(AnalysisView.lastReportDescriptor) private var lastReport: [Report]
    @Query(filter: Purchase.currentMonthPredicate()) private var currentMonthPurchases: [Purchase]
    @Query(filter: Purchase.currentWeekPredicate()) private var currentWeekPurchases: [Purchase]
    
    // MARK: - States
    @StateObject private var mealAnalyzer = MealAnalyzer()
    @State private var selectedMenu = "Monthly"
    @State private var isExpanded = false
    @State private var offset: CGFloat = 0
    @State private var isShowPremium = false
    @State private var userId = ""
//    @State private var tier: Profile.Tier?
    
    private var markdownText: AttributedString {
        do {
            var text = try AttributedString(markdown: lastReport.first?.analysisText ?? "", options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            
            // english
            if let range = text.range(of: "Nutritional Overview") {
                text[range].font = .title3
                text[range].backgroundColor = .orange
            }
            
            // spanish
            if let range = text.range(of: "Resumen de nutriciones") {
                text[range].font = .title3
                text[range].backgroundColor = .orange
            }
            // english
            if let range = text.range(of: "Recommendations") {
                text[range].font = .title3
                text[range].backgroundColor = .yellow
            }
            // spanish
            if let range = text.range(of: "Recomendaciones") {
                text[range].font = .title3
                text[range].backgroundColor = .yellow
            }
            // english
            if let range = text.range(of: "Areas for Improvement") {
                text[range].font = .title3
                text[range].backgroundColor = .mint
            }
            // spanish
            if let range = text.range(of: "Áreas de mejoras") {
                text[range].font = .title3
                text[range].backgroundColor = .mint
            }
                
            return text
        } catch {
            logger.error("Markdown parsing error: \(error)")
            return AttributedString(lastReport.first?.analysisText ?? "")
        }
    }
    
    // MARK: - Last Report Descriptor
    // Note: userId is excluded here because @Query predicates require static values.
    // Filtering by userId is done via currentReport computed property after fetching.
    static var lastReportDescriptor: FetchDescriptor<Report> {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        let year = components.year ?? 0
        let month = components.month ?? 0
        
        var descriptor = FetchDescriptor<Report>(
            predicate: #Predicate { report in
                report.year == year && report.month == month
            },
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return descriptor
    }
    
    // MARK: - Current User's Report
    private var currentReport: Report? {
        lastReport.first { $0.userId == userId }
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack {
                        ChartView(purchases: selectedMenu == "Monthly" ? currentMonthPurchases : currentWeekPurchases)
                            .padding(.bottom)
                        
                        if let report = currentReport {
                            if report.analysisText.isEmpty || mealAnalyzer.isProcessing {
                                ProgressView("Generating report…")
                            } else {
                                VStack {
                                    Rectangle()
                                        .frame(width: 40, height: 3)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    
                                    Button {
                                        withAnimation {
                                            isExpanded = true
                                        }
                                    } label: {
                                        Image(systemName: "chevron.up")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                    
                                    Text(markdownText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            // Only expand on upward swipe
                                            if value.translation.height < -50 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    isExpanded = true
                                                }
                                            }
                                        }
                                )
                            }
                        } else if !userId.isEmpty {
                            Text("No report available for this month.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
                .blur(radius: isExpanded ? 2 : 0)  // ✅ Blur background when expanded
                .disabled(isExpanded)
                
                Button("New Report"){
                    /*
                    if tier == .free {
                        isShowPremium = true
                    } else {
                        Task {
                            mealAnalyzer.generateSuggestion(purchases: currentMonthPurchases)
                            // then update report.analysisText
                        }
                    }
                     */
                    Task {
                        await mealAnalyzer.generateSuggestion(purchases: currentMonthPurchases)
                    }
                }
                .foregroundStyle(.bg)
                .padding()
                .background(currentMonthPurchases.isEmpty ? .line.opacity(0.2) : .line, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 5, x: 5, y: 5)
                .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.9)
                .disabled(currentMonthPurchases.isEmpty)
                
                if isExpanded {
                    if let report = currentReport {
                        VStack {
                            Rectangle()
                                .frame(width: 40, height: 3)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            Button {
                                withAnimation {
                                    isExpanded = false
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                            .padding(.bottom)
                            
                            ScrollView {
                                Text(markdownText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only allow downward swipe to dismiss
                                    if value.translation.height > 0 {
                                        offset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 {
                                        withAnimation(.spring(response: 0.3)) {
                                            isExpanded = false
                                            offset = 0
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3)) {
                                            offset = 0
                                        }
                                    }
                                }
                        )
                        .offset(y: offset)
                    }
                }
            }
            .padding()
            .task {
                mealAnalyzer.context = context
                await fetchUserId()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Report")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ToolbarItem {
                    Menu {
                        Button("Weekly") { selectedMenu = "Weekly" }
                        Button("Monthly") { selectedMenu = "Monthly" }
                    } label: {
                        HStack {
                            Text(selectedMenu)
                            Image(systemName: "chevron.down")
                                .resizable()
                                .frame(width: 10, height: 7)
                        }
                        .foregroundStyle(Color.line)
                    }
                }
            }
            .toolbarRole(.editor)
            .background(.bg)
            .fullScreenCover(isPresented: $isShowPremium){
                TierGatewayView()
            }
        }
    }
    
    func fetchUserId() async {
        do {
            let currentUser = try await supabase.auth.session.user
            userId = currentUser.id.uuidString
        } catch {
            logger.error("Failed to fetch userId: \(error)")
        }
    }
}
