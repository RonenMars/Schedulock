import SwiftUI
import SwiftData
import Shared

@main
struct SchedulockApp: App {
    init() {
        AppGroupManager.ensureDirectoriesExist()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            WallpaperTemplate.self,
            CalendarSource.self,
            GenerationHistory.self
        ])
    }

    private func configureAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 10/255, green: 11/255, blue: 15/255, alpha: 1)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
