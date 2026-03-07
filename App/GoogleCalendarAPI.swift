import Foundation

/// Pure URLSession client for the Google Calendar v3 REST API.
/// Handles full sync, incremental sync, and pagination.
final class GoogleCalendarAPI {

    private let session: URLSession
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Calendar List

    /// Fetches all calendars visible to the authenticated user.
    func fetchCalendarList(accessToken: String) async throws -> [GCalCalendarListEntry] {
        let url = URL(string: "\(baseURL)/users/me/calendarList")!
        let response: GCalCalendarList = try await performRequest(url: url, accessToken: accessToken)
        return response.items ?? []
    }

    // MARK: - Full Sync

    /// Performs a full sync of events from the primary calendar.
    /// Fetches all future events (from start of today) with recurring events expanded.
    /// Paginates automatically and returns the final syncToken.
    func fullSync(
        accessToken: String,
        calendarId: String = "primary"
    ) async throws -> (events: [GCalEvent], syncToken: String) {
        var allEvents: [GCalEvent] = []
        var pageToken: String? = nil
        var syncToken: String? = nil

        let timeMin = Calendar.current.startOfDay(for: Date())
        let timeMinString = ISO8601DateFormatter.withoutFractional.string(from: timeMin)

        repeat {
            var components = URLComponents(string: "\(baseURL)/calendars/\(calendarId)/events")!
            var queryItems = [
                URLQueryItem(name: "singleEvents", value: "true"),
                URLQueryItem(name: "showDeleted", value: "true"),
                URLQueryItem(name: "orderBy", value: "startTime"),
                URLQueryItem(name: "timeMin", value: timeMinString),
                URLQueryItem(name: "maxResults", value: "250"),
            ]
            if let pageToken {
                queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            components.queryItems = queryItems

            let response: GCalEventList = try await performRequest(
                url: components.url!,
                accessToken: accessToken
            )

            allEvents.append(contentsOf: response.items ?? [])
            pageToken = response.nextPageToken
            // nextSyncToken is only present on the final page
            if response.nextSyncToken != nil {
                syncToken = response.nextSyncToken
            }
        } while pageToken != nil

        guard let syncToken else {
            throw GoogleCalendarAPIError.missingSyncToken
        }

        return (events: allEvents, syncToken: syncToken)
    }

    // MARK: - Incremental Sync

    /// Performs an incremental sync using a previously stored syncToken.
    /// Returns changed events (including cancelled ones) and a new syncToken.
    ///
    /// - Throws: `GoogleCalendarAPIError.syncTokenExpired` on 410 Gone,
    ///           signaling the caller to wipe local cache and re-full-sync.
    func incrementalSync(
        accessToken: String,
        syncToken: String,
        calendarId: String = "primary"
    ) async throws -> (events: [GCalEvent], syncToken: String) {
        var allEvents: [GCalEvent] = []
        var pageToken: String? = nil
        var newSyncToken: String? = nil

        repeat {
            var components = URLComponents(string: "\(baseURL)/calendars/\(calendarId)/events")!
            // IMPORTANT: Do NOT add singleEvents, timeMin, timeMax, or other filters
            // with syncToken — Google API requires syncToken to be used alone.
            var queryItems = [
                URLQueryItem(name: "syncToken", value: syncToken),
                URLQueryItem(name: "maxResults", value: "250"),
            ]
            if let pageToken {
                queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            components.queryItems = queryItems

            let response: GCalEventList = try await performRequest(
                url: components.url!,
                accessToken: accessToken
            )

            allEvents.append(contentsOf: response.items ?? [])
            pageToken = response.nextPageToken
            if response.nextSyncToken != nil {
                newSyncToken = response.nextSyncToken
            }
        } while pageToken != nil

        guard let newSyncToken else {
            throw GoogleCalendarAPIError.missingSyncToken
        }

        return (events: allEvents, syncToken: newSyncToken)
    }

    // MARK: - HTTP

    private func performRequest<T: Decodable>(url: URL, accessToken: String) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw GoogleCalendarAPIError.unauthorized
        case 410:
            throw GoogleCalendarAPIError.syncTokenExpired
        default:
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw GoogleCalendarAPIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
    }
}

// MARK: - Errors

enum GoogleCalendarAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case syncTokenExpired
    case missingSyncToken
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Google Calendar API."
        case .unauthorized:
            return "Access token is invalid or expired."
        case .syncTokenExpired:
            return "Sync token expired (410 Gone). A full re-sync is required."
        case .missingSyncToken:
            return "Google Calendar API did not return a sync token."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}
