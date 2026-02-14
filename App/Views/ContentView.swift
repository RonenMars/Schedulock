import SwiftUI
import Shared

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("onboardingCompleted", store: AppGroupManager.userDefaults)
    private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            mainTabView
        } else {
            NavigationStack {
                OnboardingView(onComplete: {
                    onboardingCompleted = true
                })
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TemplateGalleryView()
                .tabItem {
                    Label("Templates", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(DesignTokens.primary)
    }
}
