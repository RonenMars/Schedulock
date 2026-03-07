import SwiftUI
import SwiftData
import Shared
import GoogleSignIn

@main
struct SchedulockApp: App {
    init() {
        AppGroupManager.ensureDirectoriesExist()
        configureAppearance()

        // Register and schedule background wallpaper generation
        BackgroundTaskManager.shared.registerTask()
        BackgroundTaskManager.shared.scheduleNextGeneration()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GoogleAuthService.shared.handle(url)
                }
                .task {
                    await GoogleAuthService.shared.restorePreviousSignIn()
                }
        }
        .modelContainer(for: [
            WallpaperTemplate.self,
            CalendarSource.self,
            GenerationHistory.self,
            SavedTemplateSettings.self
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
