import SwiftUI
import EventKit
import Shared

struct CalendarPickerView: View {
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                Group {
                    switch viewModel.authorizationStatus {
                    case .fullAccess:
                        calendarList
                    case .notDetermined:
                        requestAccessView
                    default:
                        deniedAccessView
                    }
                }
            }
            .navigationTitle("Calendars")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.todayEventCount > 0 {
                        Text("\(viewModel.todayEventCount) events today")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                }
            }
            .onAppear {
                if viewModel.authorizationStatus == .fullAccess {
                    viewModel.loadCalendars()
                }
            }
        }
    }

    // MARK: - Calendar List

    private var calendarList: some View {
        List {
            ForEach(viewModel.calendarGroups, id: \.source) { group in
                Section(group.source) {
                    ForEach(group.calendars, id: \.calendarIdentifier) { calendar in
                        CalendarRow(
                            calendar: calendar,
                            isEnabled: viewModel.isCalendarEnabled(calendar.calendarIdentifier),
                            onToggle: { viewModel.toggleCalendar(calendar.calendarIdentifier) }
                        )
                    }
                }
                .listRowBackground(DesignTokens.surface)
            }

            if viewModel.hasThirdPartyCalendars {
                Section {
                } footer: {
                    Label(
                        "Events from third-party accounts (e.g. Google) are synced by Apple Calendar. Open the Calendar app to force a refresh.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                }
            }

            if !viewModel.todayEvents.isEmpty {
                Section("Today's Events") {
                    ForEach(viewModel.todayEvents) { event in
                        EventRow(event: event)
                    }

                    let total = viewModel.todayEventCount
                    let showing = viewModel.todayEvents.count
                    if total > showing {
                        Text("+\(total - showing) more")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                }
                .listRowBackground(DesignTokens.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.loadCalendars()
        }
    }

    // MARK: - Access Views

    private var requestAccessView: some View {
        VStack(spacing: DesignTokens.spacingLG) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(DesignTokens.primary)

            Text("Calendar Access Needed")
                .font(.title2.bold())
                .foregroundStyle(DesignTokens.textPrimary)

            Text("Schedulock reads your calendar to display today's agenda on your wallpaper. No data leaves your device.")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.spacingXL)

            Button {
                Task { await viewModel.requestAccess() }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
            }
            .padding(.horizontal, DesignTokens.spacingXL)
        }
    }

    private var deniedAccessView: some View {
        VStack(spacing: DesignTokens.spacingLG) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(DesignTokens.danger)

            Text("Calendar Access Denied")
                .font(.title2.bold())
                .foregroundStyle(DesignTokens.textPrimary)

            Text("Open Settings to grant Schedulock calendar access.")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textMuted)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.headline)
            .foregroundStyle(DesignTokens.primary)
        }
    }
}

// MARK: - Row Views

private struct CalendarRow: View {
    let calendar: EKCalendar
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.spacingSM) {
            Circle()
                .fill(Color(UIColor(cgColor: calendar.cgColor)))
                .frame(width: 12, height: 12)

            Text(calendar.title)
                .foregroundStyle(DesignTokens.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .tint(DesignTokens.primary)
        }
    }
}

private struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: DesignTokens.spacingSM) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(event.calendarColor))
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.truncatedTitle)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textPrimary)

                if event.isAllDay {
                    Text("All Day")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textMuted)
                } else {
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textMuted)
                }
            }

            Spacer()
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startTime)) – \(formatter.string(from: event.endTime))"
    }
}
