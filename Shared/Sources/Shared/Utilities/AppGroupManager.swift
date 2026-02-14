import Foundation

/// Centralized access to the App Group shared container.
/// All targets (App, Widget, Intent) use this to read/write shared data.
public struct AppGroupManager {
    public static let groupID = "group.com.ronenmars.Schedulock"

    public static var containerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupID
        ) else {
            // Fallback to temporary directory for testing/development
            print("⚠️ App Group '\(groupID)' not configured. Using temporary directory.")
            return FileManager.default.temporaryDirectory.appendingPathComponent("SchedulockTest")
        }
        return url
    }

    public static var wallpaperDirectory: URL {
        containerURL.appending(path: "Wallpapers")
    }

    public static var imagesDirectory: URL {
        containerURL.appending(path: "Images")
    }

    public static var historyDirectory: URL {
        wallpaperDirectory.appending(path: "history")
    }

    public static var userDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: groupID) else {
            // Fallback to standard UserDefaults for testing/development
            print("⚠️ Cannot create UserDefaults for suite '\(groupID)'. Using standard UserDefaults.")
            return UserDefaults.standard
        }
        return defaults
    }

    /// Ensures all shared directories exist. Call on app launch.
    public static func ensureDirectoriesExist() {
        let dirs = [wallpaperDirectory, imagesDirectory, historyDirectory]
        for dir in dirs {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
    }
}
