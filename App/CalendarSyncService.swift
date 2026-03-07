import Foundation

/// Orchestrates Google Calendar sync: coordinates auth -> API -> store.
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

    /// Performs a full sync of all selected calendars.
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
            try await performFullSync(accessToken: accessToken, calendarId: calendarId)
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

        let events = try await api.fetchEvents(accessToken: accessToken, calendarId: calendarId)

        let localEvents = events.compactMap { $0.toLocalEvent(calendarId: calendarId) }
            .filter { !$0.isCancelled }

        // Merge with existing events from other calendars
        let existingEvents = store.loadEvents().filter { $0.calendarId != calendarId }
        store.replaceAllEvents(existingEvents + localEvents)

        print("[CalendarSync] Full sync complete for \(calendarId): \(localEvents.count) events")
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
