import WidgetKit
import SwiftUI
import Shared

// MARK: - Timeline Entry

struct SchedulockWidgetEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
    let totalEventCount: Int

    var nextEvent: WidgetEvent? {
        events.first { !$0.isAllDay && $0.startTime > date }
    }

    var currentEvent: WidgetEvent? {
        events.first { !$0.isAllDay && $0.startTime <= date && $0.endTime > date }
    }
}

struct WidgetEvent: Identifiable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let isAllDay: Bool

    var truncatedTitle: String {
        title.count > 28 ? String(title.prefix(28)) + "…" : title
    }

    var formattedTime: String {
        if isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }
}

// MARK: - Timeline Provider

struct SchedulockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SchedulockWidgetEntry {
        SchedulockWidgetEntry(
            date: Date(),
            events: [
                WidgetEvent(id: "1", title: "Team Standup", startTime: Date(), endTime: Date().addingTimeInterval(1800), isAllDay: false),
                WidgetEvent(id: "2", title: "Design Review", startTime: Date().addingTimeInterval(3600), endTime: Date().addingTimeInterval(7200), isAllDay: false),
                WidgetEvent(id: "3", title: "Lunch", startTime: Date().addingTimeInterval(10800), endTime: Date().addingTimeInterval(14400), isAllDay: false),
            ],
            totalEventCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SchedulockWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SchedulockWidgetEntry>) -> Void) {
        let provider = CalendarDataProvider()
        let calendarIDs = AppGroupManager.userDefaults.stringArray(forKey: "enabledCalendarIDs") ?? []
        let calendarEvents = provider.fetchTodayEvents(from: calendarIDs, maxEvents: 8)
        let totalCount = provider.countTodayEvents(from: calendarIDs)

        let widgetEvents = calendarEvents.map { event in
            WidgetEvent(
                id: event.id,
                title: event.title,
                startTime: event.startTime,
                endTime: event.endTime,
                isAllDay: event.isAllDay
            )
        }

        // Create entries at each event transition point
        var entries: [SchedulockWidgetEntry] = []
        let now = Date()

        // Entry for right now
        entries.append(SchedulockWidgetEntry(date: now, events: widgetEvents, totalEventCount: totalCount))

        // Entry at each event start/end time (future only)
        let transitionTimes = Set(
            calendarEvents.flatMap { [$0.startTime, $0.endTime] }
                .filter { $0 > now }
        ).sorted()

        for time in transitionTimes.prefix(10) {
            entries.append(SchedulockWidgetEntry(date: time, events: widgetEvents, totalEventCount: totalCount))
        }

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let policy: TimelineReloadPolicy = .after(tomorrow)

        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - Inline Widget (single line above clock)

struct SchedulockInlineView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        if let next = entry.nextEvent ?? entry.currentEvent {
            Text("\(next.formattedTime) \(next.truncatedTitle)")
                .privacySensitive()
        } else if entry.totalEventCount > 0 {
            Text("\(entry.totalEventCount) events today")
        } else {
            Text("No events today")
        }
    }
}

// MARK: - Circular Widget (small circle)

struct SchedulockCircularView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if let next = entry.nextEvent {
                VStack(spacing: 0) {
                    Text(next.formattedTime)
                        .font(.system(.caption, design: .monospaced))
                        .widgetAccentable()
                        .privacySensitive()
                }
            } else {
                VStack(spacing: 0) {
                    Text("\(entry.totalEventCount)")
                        .font(.title2.bold())
                        .widgetAccentable()
                    Text("events")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Rectangular Widget (2-3 events below clock)

struct SchedulockRectangularView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("AGENDA")
                .font(.system(size: 10, weight: .semibold))
                .widgetAccentable()

            if entry.events.isEmpty {
                Text("No events today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let displayEvents = Array(entry.events.prefix(3))
                ForEach(displayEvents) { event in
                    HStack(spacing: 4) {
                        Text(event.formattedTime)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .leading)

                        Text(event.truncatedTitle)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .privacySensitive()
                }

                if entry.totalEventCount > 3 {
                    Text("+\(entry.totalEventCount - 3) more")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Widget Definition

@main
struct SchedulockWidgetBundle: WidgetBundle {
    var body: some Widget {
        SchedulockInlineWidget()
        SchedulockCircularWidget()
        SchedulockRectangularWidget()
    }
}

struct SchedulockInlineWidget: Widget {
    let kind = "SchedulockInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SchedulockTimelineProvider()) { entry in
            SchedulockInlineView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Event")
        .description("Shows your next event above the clock.")
        .supportedFamilies([.accessoryInline])
    }
}

struct SchedulockCircularWidget: Widget {
    let kind = "SchedulockCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SchedulockTimelineProvider()) { entry in
            SchedulockCircularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Event Count")
        .description("Shows event count or next event time.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct SchedulockRectangularWidget: Widget {
    let kind = "SchedulockRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SchedulockTimelineProvider()) { entry in
            SchedulockRectangularView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Agenda")
        .description("Shows your next 2-3 events.")
        .supportedFamilies([.accessoryRectangular])
    }
}
