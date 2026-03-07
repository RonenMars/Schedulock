import XCTest
@testable import Schedulock

/// Tests for GoogleCalendarAPI: request construction, pagination, error mapping, decoding.
/// Uses URLProtocol stubs to intercept network calls.
final class GoogleCalendarAPITests: XCTestCase {

    private var api: GoogleCalendarAPI!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        api = GoogleCalendarAPI(session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        api = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Fetch Events Request Construction

    func testFetchEventsUsesCorrectEndpoint() async throws {
        var capturedURL: URL?

        stubSinglePageResponse(events: []) { request in
            capturedURL = request.url
        }

        _ = try await api.fetchEvents(accessToken: "test_token")

        let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: false)!
        XCTAssertTrue(components.path.hasSuffix("/calendars/primary/events"))
    }

    func testFetchEventsIncludesSingleEvents() async throws {
        var capturedURL: URL?

        stubSinglePageResponse(events: []) { request in
            capturedURL = request.url
        }

        _ = try await api.fetchEvents(accessToken: "test_token")

        let query = queryItems(from: capturedURL!)
        XCTAssertEqual(query["singleEvents"], "true")
    }

    func testFetchEventsIncludesShowDeleted() async throws {
        var capturedURL: URL?

        stubSinglePageResponse(events: []) { request in
            capturedURL = request.url
        }

        _ = try await api.fetchEvents(accessToken: "test_token")

        let query = queryItems(from: capturedURL!)
        XCTAssertEqual(query["showDeleted"], "true")
    }

    func testFetchEventsIncludesTimeMin() async throws {
        var capturedURL: URL?

        stubSinglePageResponse(events: []) { request in
            capturedURL = request.url
        }

        _ = try await api.fetchEvents(accessToken: "test_token")

        let query = queryItems(from: capturedURL!)
        XCTAssertNotNil(query["timeMin"], "Should include timeMin")
    }

    func testFetchEventsReturnsDecodedEvents() async throws {
        let eventsJSON = """
        [
            {
                "id": "e1",
                "status": "confirmed",
                "summary": "Meeting",
                "start": { "dateTime": "2024-03-15T10:00:00Z" },
                "end": { "dateTime": "2024-03-15T11:00:00Z" }
            }
        ]
        """
        stubSinglePageResponse(itemsJSON: eventsJSON)

        let events = try await api.fetchEvents(accessToken: "test_token")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.id, "e1")
        XCTAssertEqual(events.first?.summary, "Meeting")
    }

    // MARK: - Pagination

    func testFetchEventsPaginates() async throws {
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let json: String
            if callCount == 1 {
                json = """
                {
                    "kind": "calendar#events",
                    "nextPageToken": "page2",
                    "items": [{ "id": "e1", "status": "confirmed", "summary": "First",
                               "start": {"dateTime":"2024-03-15T10:00:00Z"},
                               "end": {"dateTime":"2024-03-15T11:00:00Z"} }]
                }
                """
            } else {
                json = """
                {
                    "kind": "calendar#events",
                    "items": [{ "id": "e2", "status": "confirmed", "summary": "Second",
                               "start": {"dateTime":"2024-03-15T12:00:00Z"},
                               "end": {"dateTime":"2024-03-15T13:00:00Z"} }]
                }
                """
            }
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let events = try await api.fetchEvents(accessToken: "test_token")

        XCTAssertEqual(callCount, 2, "Should make 2 requests for 2 pages")
        XCTAssertEqual(events.count, 2)
    }

    // MARK: - Bearer Token

    func testBearerTokenAttached() async throws {
        var capturedAuth: String?

        stubSinglePageResponse(events: []) { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
        }

        _ = try await api.fetchEvents(accessToken: "my_access_token_123")

        XCTAssertEqual(capturedAuth, "Bearer my_access_token_123")
    }

    // MARK: - Error Handling

    func testHTTP401ThrowsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await api.fetchEvents(accessToken: "bad_token")
            XCTFail("Should throw unauthorized")
        } catch GoogleCalendarAPIError.unauthorized {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testHTTP500ThrowsHttpError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, "Internal Server Error".data(using: .utf8)!)
        }

        do {
            _ = try await api.fetchEvents(accessToken: "tok")
            XCTFail("Should throw httpError")
        } catch GoogleCalendarAPIError.httpError(let code, let body) {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(body, "Internal Server Error")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Helpers

    private func queryItems(from url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }

    private func stubSinglePageResponse(
        events: [Any] = [],
        itemsJSON: String? = nil,
        inspector: ((URLRequest) -> Void)? = nil
    ) {
        let items = itemsJSON ?? "[]"
        MockURLProtocol.requestHandler = { request in
            inspector?(request)
            let json = """
            {
                "kind": "calendar#events",
                "items": \(items)
            }
            """
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }
}

// MARK: - MockURLProtocol

/// Intercepts all URL requests in tests and returns canned responses.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
