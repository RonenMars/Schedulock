import SwiftUI
import Shared

extension Notification.Name {
    static let googleCalendarSyncDidComplete = Notification.Name("googleCalendarSyncDidComplete")
}

/// ViewModel for Google Calendar sign-in state and synced events.
/// Follows the project's @Observable pattern (CalendarViewModel, WallpaperViewModel).
@Observable
final class GoogleCalendarViewModel {

    private let auth = GoogleAuthService.shared
    private let syncService = CalendarSyncService.shared

    // MARK: - State

    var isSignedIn = false
    var isSyncing = false
    var userEmail: String?
    var cachedEventCount: Int = 0
    var lastSyncDate: Date?
    var errorMessage: String?

    /// Today's Google Calendar events, ready for rendering.
    var todayEvents: [CalendarEvent] = []

    /// All calendars in the user's Google account.
    var availableCalendars: [GCalCalendarListEntry] = []

    /// Calendar IDs the user has enabled for display.
    var enabledGoogleCalendarIDs: Set<String> = []

    private static let enabledCalendarIDsKey = "enabledGoogleCalendarIDs"

    // MARK: - Initialization

    /// Restores previous sign-in and loads cached events.
    /// Call once when the view appears.
    func restoreAndLoad() async {
        let restored = await auth.restorePreviousSignIn()
        await MainActor.run {
            updateAuthState()
        }

        // Load cached events immediately (even before syncing)
        await MainActor.run {
            todayEvents = syncService.store.todayEvents()
            cachedEventCount = syncService.store.loadEvents().count
            lastSyncDate = syncService.store.lastSyncDate
        }

        // If signed in, fetch calendar list and trigger a sync
        if restored {
            await fetchCalendarList()
            await performSync()
        }
    }

    // MARK: - Sign In / Out

    func signIn() async {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            await MainActor.run { errorMessage = "Unable to present sign-in." }
            return
        }

        do {
            try await auth.signIn(presenting: rootVC)
            await MainActor.run { updateAuthState() }
            await fetchCalendarList()
            await performSync()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                updateAuthState()
            }
        }
    }

    func signOut() {
        auth.signOut()
        syncService.store.clearAll()
        updateAuthState()
        todayEvents = []
        cachedEventCount = 0
        lastSyncDate = nil
        errorMessage = nil
    }

    // MARK: - Sync

    /// Triggers a sync (incremental or full as appropriate).
    /// - Parameter ignoresFreshnessGuard: When true, syncs even if a recent sync exists (e.g. manual refresh).
    func performSync(ignoresFreshnessGuard: Bool = false) async {
        guard auth.isSignedIn else { return }

        await MainActor.run {
            isSyncing = true
            errorMessage = nil
        }

        do {
            let calendarIds = enabledGoogleCalendarIDs.isEmpty ? nil : Array(enabledGoogleCalendarIDs)
            let count = try await syncService.sync(calendarIds: calendarIds, ignoresFreshnessGuard: ignoresFreshnessGuard)
            await MainActor.run {
                cachedEventCount = count
                todayEvents = syncService.store.todayEvents()
                lastSyncDate = syncService.store.lastSyncDate
                isSyncing = false
                NotificationCenter.default.post(name: .googleCalendarSyncDidComplete, object: nil)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSyncing = false
            }
        }
    }

    /// Forces a full re-sync, clearing all cached data.
    func forceFullSync() async {
        await MainActor.run {
            isSyncing = true
            errorMessage = nil
        }

        do {
            let calendarIds = enabledGoogleCalendarIDs.isEmpty ? nil : Array(enabledGoogleCalendarIDs)
            let count = try await syncService.forceFullSync(calendarIds: calendarIds)
            await MainActor.run {
                cachedEventCount = count
                todayEvents = syncService.store.todayEvents()
                lastSyncDate = syncService.store.lastSyncDate
                isSyncing = false
                NotificationCenter.default.post(name: .googleCalendarSyncDidComplete, object: nil)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSyncing = false
            }
        }
    }

    // MARK: - Calendar List

    /// Fetches the list of calendars from the Google account.
    func fetchCalendarList() async {
        guard auth.isSignedIn else { return }
        do {
            let accessToken = try await auth.validAccessToken()
            let api = GoogleCalendarAPI()
            let calendars = try await api.fetchCalendarList(accessToken: accessToken)
            await MainActor.run {
                availableCalendars = calendars
                // If no previous selection, enable all by default
                let saved = loadEnabledCalendarIDs()
                if saved.isEmpty {
                    enabledGoogleCalendarIDs = Set(calendars.map { $0.id })
                } else {
                    enabledGoogleCalendarIDs = saved
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Persists the user's calendar selection to UserDefaults.
    func saveEnabledCalendarIDs() {
        let idsArray = Array(enabledGoogleCalendarIDs)
        AppGroupManager.userDefaults.set(idsArray, forKey: Self.enabledCalendarIDsKey)
    }

    /// Loads previously saved calendar selection from UserDefaults.
    private func loadEnabledCalendarIDs() -> Set<String> {
        guard let ids = AppGroupManager.userDefaults.stringArray(forKey: Self.enabledCalendarIDsKey) else {
            return []
        }
        return Set(ids)
    }

    // MARK: - Private

    private func updateAuthState() {
        isSignedIn = auth.isSignedIn
        userEmail = auth.currentUser?.profile?.email
    }
}
