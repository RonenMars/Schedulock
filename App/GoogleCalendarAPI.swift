import Foundation

/// Pure URLSession client for the Google Calendar v3 REST API.
/// Handles event fetching with pagination.
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

    // MARK: - Fetch Events

    /// Fetches all future events from the given calendar.
    /// Uses `singleEvents=true` so recurring events are expanded into individual instances.
    /// Paginates automatically.
    func fetchEvents(
        accessToken: String,
        calendarId: String = "primary"
    ) async throws -> [GCalEvent] {
        var allEvents: [GCalEvent] = []
        var pageToken: String? = nil

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
        } while pageToken != nil

        return allEvents
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
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Google Calendar API."
        case .unauthorized:
            return "Access token is invalid or expired."
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}
