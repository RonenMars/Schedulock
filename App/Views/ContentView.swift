import SwiftUI
import SwiftData
import Shared

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("onboardingCompleted", store: AppGroupManager.userDefaults)
    private var onboardingCompleted = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if onboardingCompleted {
            mainTabView
        } else {
            NavigationStack {
                OnboardingView(onComplete: {
                    selectedTab = 0
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
        .onAppear { seedTemplateSettingsIfNeeded() }
    }

    private func seedTemplateSettingsIfNeeded() {
        let existing = (try? modelContext.fetch(FetchDescriptor<SavedTemplateSettings>()))
            .map { Set($0.map(\.templateTypeRaw)) } ?? []
        for type in TemplateType.allCases {
            guard !existing.contains(type.rawValue) else { continue }
            modelContext.insert(SavedTemplateSettings(templateTypeRaw: type.rawValue))
        }
        try? modelContext.save()
    }
}
