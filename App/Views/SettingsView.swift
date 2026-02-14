import SwiftUI
import Shared

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                List {
                    Section("General") {
                        Label("Auto-Generate Schedule", systemImage: "clock")
                        Label("Target Device", systemImage: "iphone")
                        Label("Notifications", systemImage: "bell")
                    }
                    .listRowBackground(DesignTokens.surface)

                    Section("Calendar") {
                        Label("Select Calendars", systemImage: "calendar")
                        Label("Max Events", systemImage: "list.number")
                    }
                    .listRowBackground(DesignTokens.surface)

                    Section("Appearance") {
                        Label("Default Template", systemImage: "paintbrush")
                        Label("Clock Format", systemImage: "clock.fill")
                    }
                    .listRowBackground(DesignTokens.surface)

                    Section("Data & Privacy") {
                        Label("Clear History", systemImage: "trash")
                            .foregroundStyle(DesignTokens.danger)
                        Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(DesignTokens.danger)
                    }
                    .listRowBackground(DesignTokens.surface)
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(DesignTokens.textPrimary)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
