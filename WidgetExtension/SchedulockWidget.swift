import WidgetKit
import SwiftUI

struct SchedulockWidgetEntry: TimelineEntry {
    let date: Date
    let nextEventTitle: String?
    let eventCount: Int
}

struct SchedulockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SchedulockWidgetEntry {
        SchedulockWidgetEntry(date: Date(), nextEventTitle: "Team Standup", eventCount: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (SchedulockWidgetEntry) -> Void) {
        completion(SchedulockWidgetEntry(date: Date(), nextEventTitle: "Team Standup", eventCount: 5))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SchedulockWidgetEntry>) -> Void) {
        let entry = SchedulockWidgetEntry(date: Date(), nextEventTitle: nil, eventCount: 0)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SchedulockWidgetInlineView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        if let title = entry.nextEventTitle {
            Text("\(title) — Soon")
        } else {
            Text("No upcoming events")
        }
    }
}

struct SchedulockWidgetCircularView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("\(entry.eventCount)")
                .font(.title2)
                .widgetAccentable()
        }
    }
}

struct SchedulockWidgetRectangularView: View {
    let entry: SchedulockWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Today's Agenda")
                .font(.caption2)
                .widgetAccentable()
            if let title = entry.nextEventTitle {
                Text(title)
                    .font(.caption)
                    .privacySensitive()
            } else {
                Text("No events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@main
struct SchedulockWidget: Widget {
    let kind = "SchedulockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SchedulockTimelineProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                SchedulockWidgetRectangularView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SchedulockWidgetRectangularView(entry: entry)
            }
        }
        .configurationDisplayName("Schedulock")
        .description("See your agenda at a glance.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
