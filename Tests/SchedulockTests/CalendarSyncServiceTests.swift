import XCTest
@testable import Schedulock

/// Tests for CalendarSyncService: full/incremental sync orchestration, 410 recovery, freshness guard.
final class CalendarSyncServiceTests: XCTestCase {

    private var service: CalendarSyncService!
    private var store: CalendarSyncStore!
    private var fakeAuth: FakeAccessTokenProvider!
    private var api: GoogleCalendarAPI!
    private var session: URLSession!
    private var defaults: UserDefaults!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        let suiteName = "CalendarSyncServiceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        tempDir = FileManager.default.temporaryDirectory.appending(path: suiteName)
        store = CalendarSyncStore(defaults: defaults, eventsDirectory: tempDir)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        api = GoogleCalendarAPI(session: session)

        fakeAuth = FakeAccessTokenProvider()
        service = CalendarSyncService(store: store, api: api, auth: fakeAuth)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        service = nil
        store = nil
        fakeAuth = nil
        api = nil
        session = nil
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Full Sync (no existing token)

    func testFullSyncWhenNoToken() async throws {
        XCTAssertNil(store.syncToken, "Precondition: no sync token")

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "fresh_token",
            "items": [
                { "id": "e1", "status": "confirmed", "summary": "Event One",
                  "start": {"dateTime":"2024-03-15T10:00:00Z"},
                  "end": {"dateTime":"2024-03-15T11:00:00Z"} }
            ]
        }
        """)

        let count = try await service.sync()

        XCTAssertEqual(count, 1)
        XCTAssertEqual(store.syncToken, "fresh_token")
        XCTAssertNotNil(store.lastSyncDate)
        XCTAssertEqual(store.loadEvents().first?.summary, "Event One")
    }

    // MARK: - Incremental Sync (existing token)

    func testIncrementalSyncWhenTokenExists() async throws {
        // Seed store with an existing event and token
        store.replaceAllEvents([
            GoogleCalendarEvent(
                id: "existing", summary: "Existing", startDate: Date(), endDate: Date().addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
            )
        ])
        store.syncToken = "old_token"
        store.lastSyncDate = Date.distantPast // bypass freshness guard

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "new_token",
            "items": [
                { "id": "e2", "status": "confirmed", "summary": "New Event",
                  "start": {"dateTime":"2024-03-15T12:00:00Z"},
                  "end": {"dateTime":"2024-03-15T13:00:00Z"} }
            ]
        }
        """)

        let count = try await service.sync()

        XCTAssertEqual(count, 2, "Should have existing + new event")
        XCTAssertEqual(store.syncToken, "new_token")
    }

    // MARK: - 410 Gone Recovery

    func testHTTP410TriggersFullResync() async throws {
        store.syncToken = "expired_token"
        store.lastSyncDate = Date.distantPast
        store.replaceAllEvents([
            GoogleCalendarEvent(
                id: "stale", summary: "Stale", startDate: Date(), endDate: Date().addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
            )
        ])

        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                // First call: incremental sync returns 410
                let response = HTTPURLResponse(url: request.url!, statusCode: 410, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            } else {
                // Second call: full sync succeeds
                let json = """
                {
                    "kind": "calendar#events",
                    "nextSyncToken": "recovered_token",
                    "items": [
                        { "id": "fresh", "status": "confirmed", "summary": "Fresh",
                          "start": {"dateTime":"2024-03-15T10:00:00Z"},
                          "end": {"dateTime":"2024-03-15T11:00:00Z"} }
                    ]
                }
                """
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, json.data(using: .utf8)!)
            }
        }

        let count = try await service.sync()

        XCTAssertEqual(callCount, 2, "Should make incremental + full sync requests")
        XCTAssertEqual(count, 1, "Should only have the fresh event")
        XCTAssertEqual(store.syncToken, "recovered_token")
        XCTAssertFalse(store.loadEvents().contains { $0.id == "stale" }, "Stale events should be cleared")
    }

    // MARK: - Cancelled Event Handling in Incremental Sync

    func testIncrementalSyncRemovesCancelledEvents() async throws {
        store.replaceAllEvents([
            GoogleCalendarEvent(
                id: "to_cancel", summary: "Will Cancel", startDate: Date(), endDate: Date().addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
            ),
            GoogleCalendarEvent(
                id: "keep", summary: "Keep", startDate: Date(), endDate: Date().addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
            ),
        ])
        store.syncToken = "tok"
        store.lastSyncDate = Date.distantPast

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "tok2",
            "items": [
                { "id": "to_cancel", "status": "cancelled" }
            ]
        }
        """)

        let count = try await service.sync()

        XCTAssertEqual(count, 1)
        let events = store.loadEvents()
        XCTAssertFalse(events.contains { $0.id == "to_cancel" })
        XCTAssertTrue(events.contains { $0.id == "keep" })
    }

    // MARK: - Freshness Guard

    func testFreshnessGuardSkipsRecentSync() async throws {
        store.syncToken = "tok"
        store.lastSyncDate = Date() // just synced

        var apiCalled = false
        MockURLProtocol.requestHandler = { _ in
            apiCalled = true
            fatalError("Should not be called")
        }

        let count = try await service.sync()

        XCTAssertFalse(apiCalled, "API should not be called when recently synced")
        XCTAssertEqual(count, 0) // empty store
    }

    func testFreshnessGuardBypassedWhenRequested() async throws {
        store.syncToken = "tok"
        store.lastSyncDate = Date() // just synced

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "new_tok",
            "items": []
        }
        """)

        _ = try await service.sync(ignoresFreshnessGuard: true)

        // If we get here without crash, the API was called (mock responded)
        XCTAssertEqual(store.syncToken, "new_tok")
    }

    func testFreshnessGuardAllowsSyncAfterInterval() async throws {
        store.syncToken = "tok"
        store.lastSyncDate = Date(timeIntervalSinceNow: -400) // 400s ago, > 300s threshold

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "updated_tok",
            "items": []
        }
        """)

        _ = try await service.sync()

        XCTAssertEqual(store.syncToken, "updated_tok", "Should sync when interval has elapsed")
    }

    // MARK: - Auth Guard

    func testSyncThrowsWhenNotSignedIn() async {
        fakeAuth.signedIn = false

        do {
            _ = try await service.sync()
            XCTFail("Should throw notSignedIn")
        } catch CalendarSyncError.notSignedIn {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Force Full Sync

    func testForceFullSyncClearsAndResyncs() async throws {
        store.syncToken = "old"
        store.replaceAllEvents([
            GoogleCalendarEvent(
                id: "old", summary: "Old", startDate: Date(), endDate: Date().addingTimeInterval(3600),
                isAllDay: false, location: nil, calendarId: "primary", status: "confirmed"
            )
        ])

        stubResponse(json: """
        {
            "kind": "calendar#events",
            "nextSyncToken": "force_token",
            "items": [
                { "id": "new", "status": "confirmed", "summary": "New",
                  "start": {"dateTime":"2024-03-15T10:00:00Z"},
                  "end": {"dateTime":"2024-03-15T11:00:00Z"} }
            ]
        }
        """)

        let count = try await service.forceFullSync()

        XCTAssertEqual(count, 1)
        XCTAssertEqual(store.syncToken, "force_token")
        XCTAssertFalse(store.loadEvents().contains { $0.id == "old" })
    }

    // MARK: - Sync Token Stored From Final Page Only

    func testSyncTokenFromFinalPageOnly() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let json: String
            if callCount == 1 {
                json = """
                {
                    "kind": "calendar#events",
                    "nextPageToken": "page2",
                    "items": [{ "id": "e1", "status": "confirmed", "summary": "P1",
                               "start":{"dateTime":"2024-03-15T10:00:00Z"},
                               "end":{"dateTime":"2024-03-15T11:00:00Z"} }]
                }
                """
            } else {
                json = """
                {
                    "kind": "calendar#events",
                    "nextSyncToken": "final_page_token",
                    "items": [{ "id": "e2", "status": "confirmed", "summary": "P2",
                               "start":{"dateTime":"2024-03-15T12:00:00Z"},
                               "end":{"dateTime":"2024-03-15T13:00:00Z"} }]
                }
                """
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json.data(using: .utf8)!)
        }

        _ = try await service.sync()

        XCTAssertEqual(store.syncToken, "final_page_token")
        XCTAssertEqual(store.loadEvents().count, 2)
    }

    // MARK: - Error Propagation

    func testNetworkErrorPropagates() async {
        store.lastSyncDate = Date.distantPast

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await service.sync()
            XCTFail("Should propagate network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    // MARK: - Helpers

    private func stubResponse(json: String) {
        MockURLProtocol.requestHandler = { request in
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }
}

// MARK: - Fake Auth Provider

final class FakeAccessTokenProvider: AccessTokenProvider {
    var signedIn = true
    var token = "fake_access_token"
    var shouldThrow: Error?

    var isSignedIn: Bool { signedIn }

    func validAccessToken() async throws -> String {
        if let error = shouldThrow { throw error }
        return token
    }
}
