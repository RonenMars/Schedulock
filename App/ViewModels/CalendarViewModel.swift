import SwiftUI
import EventKit
import SwiftData
import Shared

@Observable
final class CalendarViewModel {
    private let provider = CalendarDataProvider()

    var authorizationStatus: EKAuthorizationStatus = CalendarDataProvider.authorizationStatus
    var calendarGroups: [(source: String, calendars: [EKCalendar])] = []
    var todayEventCount: Int = 0
    var todayEvents: [CalendarEvent] = []
    var isLoading = false

    /// Calendar IDs that are enabled by the user, persisted in App Group.
    var enabledCalendarIDs: Set<String> {
        get {
            Set(AppGroupManager.userDefaults.stringArray(forKey: "enabledCalendarIDs") ?? [])
        }
        set {
            AppGroupManager.userDefaults.set(Array(newValue), forKey: "enabledCalendarIDs")
            refreshEventCount()
        }
    }

    // MARK: - Access

    func requestAccess() async {
        do {
            let granted = try await provider.requestAccess()
            await MainActor.run {
                authorizationStatus = CalendarDataProvider.authorizationStatus
                if granted {
                    loadCalendars()
                }
            }
        } catch {
            await MainActor.run {
                authorizationStatus = CalendarDataProvider.authorizationStatus
            }
        }
    }

    // MARK: - Loading

    func loadCalendars() {
        isLoading = true
        calendarGroups = provider.fetchCalendarsGroupedBySource()

        // If no calendars are enabled yet, enable all by default
        if enabledCalendarIDs.isEmpty {
            let allIDs = calendarGroups.flatMap { $0.calendars.map(\.calendarIdentifier) }
            enabledCalendarIDs = Set(allIDs)
        }

        refreshEventCount()
        isLoading = false
    }

    func refreshEventCount() {
        let ids = Array(enabledCalendarIDs)
        todayEventCount = provider.countTodayEvents(from: ids)
        todayEvents = provider.fetchTodayEvents(from: ids)
    }

    func toggleCalendar(_ id: String) {
        if enabledCalendarIDs.contains(id) {
            enabledCalendarIDs.remove(id)
        } else {
            enabledCalendarIDs.insert(id)
        }
    }

    func isCalendarEnabled(_ id: String) -> Bool {
        enabledCalendarIDs.contains(id)
    }

    // MARK: - Sync to SwiftData

    func syncToSwiftData(modelContext: ModelContext) {
        for group in calendarGroups {
            for cal in group.calendars {
                let source = CalendarSource(
                    id: cal.calendarIdentifier,
                    name: cal.title,
                    colorHex: cal.colorHex,
                    isEnabled: isCalendarEnabled(cal.calendarIdentifier)
                )
                modelContext.insert(source)
            }
        }
        try? modelContext.save()
    }
}
