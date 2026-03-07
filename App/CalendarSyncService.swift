import Foundation

/// Orchestrates Google Calendar sync: decides full vs. incremental,
/// handles 410 Gone recovery, and coordinates auth -> API -> store.
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    let store: CalendarSyncStore
    private let api: GoogleCalendarAPI
    private let auth: AccessTokenProvider

    /// Prevents concurrent syncs from racing.
    private var isSyncing = false

    private init() {
        self.store = CalendarSyncStore()
        self.api = GoogleCalendarAPI()
        self.auth = GoogleAuthService.shared
    }

    /// Internal init for dependency injection in tests.
    init(store: CalendarSyncStore, api: GoogleCalendarAPI, auth: AccessTokenProvider) {
        self.store = store
        self.api = api
        self.auth = auth
    }

    // MARK: - Public

    /// Minimum interval between automatic syncs (5 minutes).
    private static let minSyncInterval: TimeInterval = 300

    /// Performs a sync — incremental if a sync token exists, full otherwise.
    /// Safe to call from multiple sites (foreground, manual refresh, etc.);
    /// concurrent calls are coalesced. Skips if a sync completed recently
    /// (within `minSyncInterval`); use `forceFullSync()` or pass
    /// `ignoresFreshnessGuard: true` to bypass.
    ///
    /// - Parameter calendarIds: Google Calendar IDs to sync. Pass `nil` to sync only the primary calendar.
    /// - Returns: The number of events in the local cache after sync.
    /// - Throws: Auth or network errors.
    @discardableResult
    func sync(calendarIds: [String]? = nil, ignoresFreshnessGuard: Bool = false) async throws -> Int {
        guard auth.isSignedIn else {
            throw CalendarSyncError.notSignedIn
        }
        guard !isSyncing else {
            print("[CalendarSync] Sync already in progress, skipping")
            return store.loadEvents().count
        }

        if !ignoresFreshnessGuard,
           let lastSync = store.lastSyncDate,
           Date().timeIntervalSince(lastSync) < Self.minSyncInterval {
            print("[CalendarSync] Skipping — synced \(Int(Date().timeIntervalSince(lastSync)))s ago")
            return store.loadEvents().count
        }

        isSyncing = true
        defer { isSyncing = false }

        let accessToken = try await auth.validAccessToken()
        let ids = calendarIds ?? ["primary"]

        // Sync each calendar individually
        for calendarId in ids {
            if let syncToken = store.syncToken(for: calendarId) {
                try await performIncrementalSync(accessToken: accessToken, syncToken: syncToken, calendarId: calendarId)
            } else {
                try await performFullSync(accessToken: accessToken, calendarId: calendarId)
            }
        }

        // Remove events from calendars no longer selected
        let selectedSet = Set(ids)
        let allEvents = store.loadEvents()
        let filtered = allEvents.filter { selectedSet.contains($0.calendarId) }
        if filtered.count != allEvents.count {
            store.replaceAllEvents(filtered)
        }

        store.lastSyncDate = Date()
        let totalEvents = store.loadEvents().count
        print("[CalendarSync] Multi-calendar sync complete: \(totalEvents) events cached")
        return totalEvents
    }

    /// Forces a full re-sync, clearing all cached data first.
    @discardableResult
    func forceFullSync(calendarIds: [String]? = nil) async throws -> Int {
        guard auth.isSignedIn else {
            throw CalendarSyncError.notSignedIn
        }

        isSyncing = true
        defer { isSyncing = false }

        store.clearAll()
        let accessToken = try await auth.validAccessToken()
        let ids = calendarIds ?? ["primary"]

        for calendarId in ids {
            try await performFullSync(accessToken: accessToken, calendarId: calendarId)
        }

        let totalEvents = store.loadEvents().count
        return totalEvents
    }

    // MARK: - Private

    private func performFullSync(accessToken: String, calendarId: String = "primary") async throws {
        print("[CalendarSync] Starting full sync for calendar: \(calendarId)...")

        let result = try await api.fullSync(accessToken: accessToken, calendarId: calendarId)

        let localEvents = result.events.compactMap { $0.toLocalEvent(calendarId: calendarId) }
            .filter { !$0.isCancelled }

        // Merge with existing events from other calendars
        let existingEvents = store.loadEvents().filter { $0.calendarId != calendarId }
        store.replaceAllEvents(existingEvents + localEvents)
        store.setSyncToken(result.syncToken, for: calendarId)

        print("[CalendarSync] Full sync complete for \(calendarId): \(localEvents.count) events")
    }

    private func performIncrementalSync(accessToken: String, syncToken: String, calendarId: String = "primary") async throws {
        print("[CalendarSync] Starting incremental sync for calendar: \(calendarId)...")

        do {
            let result = try await api.incrementalSync(
                accessToken: accessToken,
                syncToken: syncToken,
                calendarId: calendarId
            )

            let changedEvents = result.events.compactMap { $0.toLocalEvent(calendarId: calendarId) }

            if !changedEvents.isEmpty {
                store.applyIncrementalChanges(changedEvents)
                print("[CalendarSync] Applied \(changedEvents.count) changes for \(calendarId)")
            } else {
                print("[CalendarSync] No changes since last sync for \(calendarId)")
            }

            store.setSyncToken(result.syncToken, for: calendarId)

        } catch GoogleCalendarAPIError.syncTokenExpired {
            // 410 Gone — token expired. Wipe this calendar's events and re-full-sync.
            print("[CalendarSync] Sync token expired for \(calendarId). Re-running full sync...")
            store.setSyncToken(nil, for: calendarId)
            let existingEvents = store.loadEvents().filter { $0.calendarId != calendarId }
            store.replaceAllEvents(existingEvents)
            try await performFullSync(accessToken: accessToken, calendarId: calendarId)
        }
    }
}

// MARK: - Errors

enum CalendarSyncError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Sign in with Google to sync your calendar."
        }
    }
}
