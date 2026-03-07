import BackgroundTasks
import UIKit
import SwiftData
import Shared
import UserNotifications

/// Manages BGProcessingTask lifecycle for overnight wallpaper generation.
/// Schedules daily 4 AM wallpaper refreshes and handles task execution.
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    static let taskIdentifier = "com.ronenmars.Schedulock.wallpaper-generation"

    private let engine = WallpaperEngine.withAllRenderers([
        MinimalRenderer(),
        GlassRenderer(),
        GradientBandRenderer(),
        EditorialRenderer(),
        NeonRenderer(),
        SplitViewRenderer()
    ])

    private init() {}

    // MARK: - Registration

    /// Registers the background task handler with the system.
    /// Call this once during app initialization.
    func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleWallpaperGeneration(task: task as! BGProcessingTask)
        }
    }

    /// Schedules the next wallpaper generation for 4 AM the next day.
    func scheduleNextGeneration() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Schedule for 4 AM next day
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 4
        components.minute = 0

        if let today4AM = calendar.date(from: components),
           let tomorrow4AM = calendar.date(byAdding: .day, value: 1, to: today4AM) {
            request.earliestBeginDate = tomorrow4AM
        }

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled next wallpaper generation for 4 AM")
        } catch {
            print("⚠️ Failed to schedule background task: \(error)")
        }
    }

    // MARK: - Task Execution

    private func handleWallpaperGeneration(task: BGProcessingTask) {
        print("🌅 Starting background wallpaper generation...")

        // Set expiration handler
        task.expirationHandler = {
            print("⏰ Background task expired before completion")
            task.setTaskCompleted(success: false)
        }

        // 1. Load settings from App Group
        let defaults = AppGroupManager.userDefaults
        let templateTypeRaw = defaults.string(forKey: "defaultTemplateType") ?? "minimal"
        let templateType = TemplateType(rawValue: templateTypeRaw) ?? .minimal

        // 2. Fetch events based on calendar source
        let events: [CalendarEvent]
        let sourceRaw = defaults.string(forKey: "calendarSource") ?? CalendarSourceType.apple.rawValue
        let source = CalendarSourceType(rawValue: sourceRaw) ?? .apple

        switch source {
        case .apple:
            let provider = CalendarDataProvider()
            let calendarIDs = defaults.stringArray(forKey: "enabledCalendarIDs") ?? []
            events = provider.fetchTodayEvents(from: calendarIDs)
        case .google:
            events = CalendarSyncService.shared.store.todayEvents()
        }

        print("📅 Fetched \(events.count) events via \(source.displayName)")

        // 3. Load background image (or nil for gradient fallback)
        let imagePath = AppGroupManager.imagesDirectory.appending(path: "background-processed.jpg")
        let backgroundImage = UIImage(contentsOfFile: imagePath.path())

        if backgroundImage == nil {
            print("ℹ️ No background image found, will use gradient fallback")
        }

        // 4. Render wallpaper
        let template = WallpaperTemplate(name: templateType.displayName, templateType: templateType)
        let resolution = DeviceResolution.iPhone15Pro // TODO: Could auto-detect from device model

        guard let wallpaper = engine.generateWallpaper(
            template: template,
            image: backgroundImage,
            events: events,
            resolution: resolution
        ) else {
            print("❌ Failed to generate wallpaper")
            scheduleRetry()
            task.setTaskCompleted(success: false)
            return
        }

        // 5. Save to App Group
        AppGroupManager.ensureDirectoriesExist()
        let outputPath = AppGroupManager.wallpaperDirectory.appending(path: "current.png")

        if let data = wallpaper.pngData() {
            do {
                try data.write(to: outputPath)
                print("✅ Saved wallpaper to: \(outputPath.path())")
            } catch {
                print("❌ Failed to save wallpaper: \(error)")
                scheduleRetry()
                task.setTaskCompleted(success: false)
                return
            }
        } else {
            print("❌ Failed to encode wallpaper as PNG")
            scheduleRetry()
            task.setTaskCompleted(success: false)
            return
        }

        // 6. Post notification
        postNotification()

        // 7. Re-schedule for tomorrow
        scheduleNextGeneration()

        print("✅ Background wallpaper generation completed successfully")
        task.setTaskCompleted(success: true)
    }

    // MARK: - Helpers

    private func scheduleRetry() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Retry in 30 minutes
        request.earliestBeginDate = Date().addingTimeInterval(30 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("🔄 Scheduled retry in 30 minutes")
        } catch {
            print("⚠️ Failed to schedule retry: \(error)")
        }
    }

    private func postNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Wallpaper Ready"
        content.body = "Your daily wallpaper has been generated with today's events."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "wallpaper-generated",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to post notification: \(error)")
            } else {
                print("📬 Posted wallpaper ready notification")
            }
        }
    }
}
