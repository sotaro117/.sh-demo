import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showScanner = false /// trigger camera (scanner) view
    @State private var showUserModal = false /// trigger user modal view

    var body: some View {
            ZStack {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeView(showUserModal: $showUserModal)
                    }
                    .tabItem {
                        Image(selectedTab == 0 ? .homeFilled : .home)
                    }
                    .tag(0)
                    
                    Color.clear
                        .tabItem {
                            Image(.shoppingBasket)
                        }
                        .tag(1)
                        .onAppear {
                            showScanner = true
                            selectedTab = 0
                        }
                        .fullScreenCover(isPresented: $showScanner){
                            CameraView(showScanner: $showScanner)
                        }
                    
                    NavigationStack {
                        AnalysisView()
                    }
                    .tabItem {
                        Image(selectedTab == 2 ? .reportFilled : .report)
                    }
                    .tag(2)
                    
                    NavigationStack {
                        CalendarView()
                    }
                    .tabItem {
                        Image(selectedTab == 3 ? .calendarFilled : .calendar)
                    }
                    .tag(3)
                }
                
                if showUserModal {
                    UserModalView(showModal: $showUserModal)
                        .transition(.move(edge: .leading))
                        .zIndex(2.0)
                }
            }
            .tint(.accent)
            .toolbarRole(.editor)
    }
}
