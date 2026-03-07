import SwiftUI
import SwiftData
import Shared

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var galleryViewModel = WallpaperViewModel()
    @State private var googleCalendarVM = GoogleCalendarViewModel()
    @AppStorage("onboardingCompleted", store: AppGroupManager.userDefaults)
    private var onboardingCompleted = false
    @AppStorage("calendarSource", store: AppGroupManager.userDefaults)
    private var calendarSourceRaw: String = CalendarSourceType.apple.rawValue
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

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
            HomeView(selectedTab: $selectedTab)
                .tag(0)

            TemplateGalleryView(selectedTab: $selectedTab, viewModel: galleryViewModel)
                .tag(1)

            HistoryView()
                .tag(2)

            SettingsView()
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .tint(DesignTokens.primary)
        .onAppear { seedTemplateSettingsIfNeeded() }
        .task {
            // Load background image off the main thread
            if let imagePath = AppGroupManager.userDefaults.string(forKey: "selectedBackgroundImagePath"),
               let image = await Task.detached(priority: .userInitiated, operation: { () -> UIImage? in
                   guard let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else { return nil }
                   return UIImage(data: data)
               }).value {
                galleryViewModel.setBackgroundImage(image)
            }
            // Fetch saved settings and pre-generate all previews before the user can swipe
            let allSettings = (try? modelContext.fetch(FetchDescriptor<SavedTemplateSettings>())) ?? []
            let settingsMap = Dictionary(uniqueKeysWithValues: allSettings.compactMap { saved -> (TemplateType, DesignSettings)? in
                guard let type = TemplateType(rawValue: saved.templateTypeRaw) else { return nil }
                return (type, saved.asDesignSettings)
            })
            await galleryViewModel.warmPreviews(settingsMap: settingsMap)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active,
               CalendarSourceType(rawValue: calendarSourceRaw) == .google {
                Task { await googleCalendarVM.performSync() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabButton(icon: "house.fill",               title: "Home",      tag: 0, selectedTab: $selectedTab)
            TabButton(icon: "rectangle.grid.2x2.fill", title: "Templates", tag: 1, selectedTab: $selectedTab)
            TabButton(icon: "clock.fill",              title: "History",   tag: 2, selectedTab: $selectedTab)
            TabButton(icon: "gearshape.fill",          title: "Settings",  tag: 3, selectedTab: $selectedTab)
        }
        .padding(.top, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
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

private struct TabButton: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    @State private var bounceID = 0

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 21))
                    .symbolEffect(.bounce, value: bounceID)
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selectedTab == tag ? DesignTokens.primary : Color(uiColor: .systemGray))
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == tag {
                bounceID += 1
            }
        }
    }
}
