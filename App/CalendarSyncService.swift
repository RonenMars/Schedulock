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
    /// - Returns: The number of events in the local cache after sync.
    /// - Throws: Auth or network errors.
    @discardableResult
    func sync(ignoresFreshnessGuard: Bool = false) async throws -> Int {
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

        if let syncToken = store.syncToken {
            return try await performIncrementalSync(accessToken: accessToken, syncToken: syncToken)
        } else {
            return try await performFullSync(accessToken: accessToken)
        }
    }

    /// Forces a full re-sync, clearing all cached data first.
    @discardableResult
    func forceFullSync() async throws -> Int {
        guard auth.isSignedIn else {
            throw CalendarSyncError.notSignedIn
        }

        isSyncing = true
        defer { isSyncing = false }

        store.clearAll()
        let accessToken = try await auth.validAccessToken()
        return try await performFullSync(accessToken: accessToken)
    }

    // MARK: - Private

    private func performFullSync(accessToken: String) async throws -> Int {
        print("[CalendarSync] Starting full sync...")

        let result = try await api.fullSync(accessToken: accessToken)

        let localEvents = result.events.compactMap { $0.toLocalEvent(calendarId: "primary") }
            .filter { !$0.isCancelled }

        store.replaceAllEvents(localEvents)
        store.syncToken = result.syncToken
        store.lastSyncDate = Date()

        print("[CalendarSync] Full sync complete: \(localEvents.count) events cached")
        return localEvents.count
    }

    private func performIncrementalSync(accessToken: String, syncToken: String) async throws -> Int {
        print("[CalendarSync] Starting incremental sync...")

        do {
            let result = try await api.incrementalSync(
                accessToken: accessToken,
                syncToken: syncToken
            )

            let changedEvents = result.events.compactMap { $0.toLocalEvent(calendarId: "primary") }

            if !changedEvents.isEmpty {
                store.applyIncrementalChanges(changedEvents)
                print("[CalendarSync] Applied \(changedEvents.count) changes")
            } else {
                print("[CalendarSync] No changes since last sync")
            }

            store.syncToken = result.syncToken
            store.lastSyncDate = Date()

            let totalEvents = store.loadEvents().count
            return totalEvents

        } catch GoogleCalendarAPIError.syncTokenExpired {
            // 410 Gone — token expired. Wipe cache and re-full-sync.
            print("[CalendarSync] Sync token expired (410 Gone). Re-running full sync...")
            store.clearAll()
            return try await performFullSync(accessToken: accessToken)
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
