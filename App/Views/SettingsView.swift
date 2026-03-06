import SwiftUI
import SwiftData
import Shared

struct SettingsView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext

    // MARK: - AppStorage Properties
    @AppStorage("targetDevice", store: AppGroupManager.userDefaults)
    private var targetDeviceName: String = DeviceResolution.iPhone16Pro.name

    @AppStorage("notificationsEnabled", store: AppGroupManager.userDefaults)
    private var notificationsEnabled: Bool = false

    @AppStorage("saveToPhotos", store: AppGroupManager.userDefaults)
    private var saveToPhotos: Bool = false

    @AppStorage("maxEvents", store: AppGroupManager.userDefaults)
    private var maxEvents: Int = 6

    @AppStorage("showDeclined", store: AppGroupManager.userDefaults)
    private var showDeclined: Bool = false

    @AppStorage("showAllDay", store: AppGroupManager.userDefaults)
    private var showAllDay: Bool = true

    @AppStorage("defaultTemplateType", store: AppGroupManager.userDefaults)
    private var defaultTemplateTypeRawValue: String = TemplateType.minimal.rawValue

    @AppStorage("randomizeDaily", store: AppGroupManager.userDefaults)
    private var randomizeDaily: Bool = false

    // MARK: - State Properties
    @State private var showClearHistoryAlert = false
    @State private var showClearCacheAlert = false
    @State private var showResetDefaultsAlert = false
    @State private var isResetting = false

    // MARK: - Computed Bindings
    private var targetDeviceBinding: Binding<DeviceResolution> {
        Binding(
            get: { DeviceResolution.all.first { $0.name == self.targetDeviceName } ?? DeviceResolution.iPhone16Pro },
            set: { self.targetDeviceName = $0.name }
        )
    }

    private var defaultTemplateTypeBinding: Binding<TemplateType> {
        Binding(
            get: { TemplateType(rawValue: self.defaultTemplateTypeRawValue) ?? .minimal },
            set: { self.defaultTemplateTypeRawValue = $0.rawValue }
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                List {

                    // MARK: General Section
                    Section("General") {
                        Toggle("Notifications", isOn: $notificationsEnabled)
                            .foregroundStyle(DesignTokens.textPrimary)

                        Toggle("Save to Photos", isOn: $saveToPhotos)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                    .listRowBackground(DesignTokens.surface)

                    // MARK: Calendar Section
                    Section("Calendar") {
                        NavigationLink {
                            CalendarPickerView()
                        } label: {
                            Label("Select Calendars", systemImage: "calendar")
                        }
                        .foregroundStyle(DesignTokens.textPrimary)

                        Stepper(
                            "Max Events: \(maxEvents)",
                            value: $maxEvents,
                            in: 1...8
                        )
                        .foregroundStyle(DesignTokens.textPrimary)

                        Toggle("Show Declined Events", isOn: $showDeclined)
                            .foregroundStyle(DesignTokens.textPrimary)

                        Toggle("Show All-Day Events", isOn: $showAllDay)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                    .listRowBackground(DesignTokens.surface)

                    // MARK: Appearance Section
                    Section("Appearance") {
                        Picker("Default Template", selection: defaultTemplateTypeBinding) {
                            ForEach(TemplateType.allCases, id: \.self) { template in
                                Text(template.displayName).tag(template)
                            }
                        }
                        .foregroundStyle(DesignTokens.textPrimary)

                        Toggle("Randomize Template Daily", isOn: $randomizeDaily)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                    .listRowBackground(DesignTokens.surface)

                    // MARK: Advanced Section
                    Section("Advanced") {
                        Picker("Target Device", selection: targetDeviceBinding) {
                            ForEach(DeviceResolution.all, id: \.name) { device in
                                Text(device.name).tag(device)
                            }
                        }
                        .foregroundStyle(DesignTokens.textPrimary)
                    }
                    .listRowBackground(DesignTokens.surface)

                    // MARK: About Section
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        }
                        .foregroundStyle(DesignTokens.textPrimary)

                        NavigationLink {
                            ShortcutsGuideView()
                        } label: {
                            Label("Shortcuts Guide", systemImage: "link")
                        }
                        .foregroundStyle(DesignTokens.textPrimary)

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open System Settings", systemImage: "gear")
                        }
                        .foregroundStyle(DesignTokens.textPrimary)
                    }
                    .listRowBackground(DesignTokens.surface)

                    // MARK: Data & Privacy Section
                    Section("Data & Privacy") {
                        Button(action: {
                            showClearHistoryAlert = true
                        }) {
                            Label("Clear History", systemImage: "trash")
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        Button(action: {
                            showClearCacheAlert = true
                        }) {
                            Label("Clear Cache", systemImage: "arrow.clockwise")
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        Button(action: {
                            showResetDefaultsAlert = true
                        }) {
                            Label("Reset Defaults", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(DesignTokens.danger)
                        }
                    }
                    .listRowBackground(DesignTokens.surface)
                }
                .scrollContentBackground(.hidden)

                if isResetting {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("This will permanently delete all history. This action cannot be undone.")
            }
            .alert("Clear Cache", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will clear all cached data. The app may take longer to load temporarily.")
            }
            .alert("Reset Defaults", isPresented: $showResetDefaultsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    isResetting = true
                    Task { @MainActor in
                        resetDefaults()
                    }
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions
    private func clearHistory() {
        try? modelContext.delete(model: GenerationHistory.self)
        try? modelContext.save()
    }

    private func clearCache() {
        // Implementation for clearing cache
        // This would typically clear URLCache and other cached data
        URLCache.shared.removeAllCachedResponses()
        print("Cache cleared")
    }

    private func resetDefaults() {
        // Reset all settings to default values
        targetDeviceName = DeviceResolution.iPhone16Pro.name
        notificationsEnabled = false
        saveToPhotos = false
        maxEvents = 6
        showDeclined = false
        showAllDay = true
        defaultTemplateTypeRawValue = TemplateType.minimal.rawValue
        randomizeDaily = false
        // Reset onboarding so the setup flow runs again
        AppGroupManager.userDefaults.set(false, forKey: "onboardingCompleted")
    }
}

// MARK: - Extensions
extension DeviceResolution: Equatable, Hashable {
    public static func == (lhs: DeviceResolution, rhs: DeviceResolution) -> Bool {
        lhs.name == rhs.name && lhs.width == rhs.width && lhs.height == rhs.height
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(width)
        hasher.combine(height)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
