# Settings Redesign & Per-Template Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure the Settings screen, implement per-template DesignSettings persistence via a new SwiftData model, and fix two existing bugs (saveToPhotos ignored, clearHistory is a stub).

**Architecture:** A new `SavedTemplateSettings` SwiftData `@Model` (flat columns, one record per template type) lives in the Shared module alongside existing models. It is seeded in `ContentView.onAppear`, read in `TemplateEditorView`/`TemplateGalleryView`/`HomeView`, and written by `TemplateEditorView`. An "Apply to All" toolbar button copies the active template's settings to all six records at once.

**Tech Stack:** Swift 5.9+, SwiftData, SwiftUI, XCTest. Project root: `/Users/ronen/Desktop/dev/personal/projects/Schedulock`. Run tests with `xcodebuild test -project Schedulock.xcodeproj -scheme Schedulock -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.

---

## Task 1: Create `SavedTemplateSettings` SwiftData model

**Files:**
- Create: `Shared/Sources/Shared/Models/SavedTemplateSettings.swift`
- Create: `Tests/SchedulockTests/SavedTemplateSettingsTests.swift`

---

### Step 1: Write the failing tests

Create `Tests/SchedulockTests/SavedTemplateSettingsTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Shared

final class SavedTemplateSettingsTests: XCTestCase {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: SavedTemplateSettings.self, configurations: config)
    }

    // MARK: - Init

    func testInitSetsTemplateTypeRaw() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "minimal")
        container.mainContext.insert(record)
        XCTAssertEqual(record.templateTypeRaw, "minimal")
    }

    func testInitDefaultsMatchDesignSettingsDefault() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "glass")
        container.mainContext.insert(record)
        let d = DesignSettings.default
        XCTAssertEqual(record.textColor, d.textColor)
        XCTAssertEqual(record.accentColor, d.accentColor)
        XCTAssertEqual(record.secondaryColor, d.secondaryColor)
        XCTAssertEqual(record.cardBackground, d.cardBackground)
        XCTAssertEqual(record.overlayOpacity, d.overlayOpacity)
        XCTAssertEqual(record.glassBlur, d.glassBlur)
        XCTAssertEqual(record.backgroundBlur, d.backgroundBlur)
        XCTAssertEqual(record.brightness, d.brightness)
        XCTAssertEqual(record.textShadow, d.textShadow)
        XCTAssertEqual(record.fontFamilyRaw, d.fontFamily.rawValue)
        XCTAssertEqual(record.textAlignmentRaw, d.textAlignment.rawValue)
        XCTAssertEqual(record.useCalendarColors, d.useCalendarColors)
        XCTAssertEqual(record.splitRatio, d.splitRatio)
    }

    // MARK: - asDesignSettings

    func testAsDesignSettingsRoundTrip() throws {
        let container = try makeContainer()
        let custom = DesignSettings(
            textColor: "#FF0000",
            accentColor: "#00FF00",
            secondaryColor: "#0000FF",
            cardBackground: "#111111",
            overlayOpacity: 0.7,
            glassBlur: 15.0,
            backgroundBlur: 5.0,
            brightness: 0.2,
            textShadow: 4.0,
            fontFamily: .didot,
            textAlignment: .center,
            useCalendarColors: false,
            splitRatio: 0.4
        )
        let record = SavedTemplateSettings(templateTypeRaw: "neon")
        record.apply(custom)
        container.mainContext.insert(record)

        let result = record.asDesignSettings
        XCTAssertEqual(result.textColor, "#FF0000")
        XCTAssertEqual(result.accentColor, "#00FF00")
        XCTAssertEqual(result.secondaryColor, "#0000FF")
        XCTAssertEqual(result.cardBackground, "#111111")
        XCTAssertEqual(result.overlayOpacity, 0.7)
        XCTAssertEqual(result.glassBlur, 15.0)
        XCTAssertEqual(result.backgroundBlur, 5.0)
        XCTAssertEqual(result.brightness, 0.2)
        XCTAssertEqual(result.textShadow, 4.0)
        XCTAssertEqual(result.fontFamily, .didot)
        XCTAssertEqual(result.textAlignment, .center)
        XCTAssertFalse(result.useCalendarColors)
        XCTAssertEqual(result.splitRatio, 0.4)
    }

    func testAsDesignSettingsFallsBackToDefaultsForUnknownRawValues() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "minimal")
        record.fontFamilyRaw = "unknownFont"
        record.textAlignmentRaw = "unknownAlign"
        container.mainContext.insert(record)

        let result = record.asDesignSettings
        XCTAssertEqual(result.fontFamily, .sfPro)
        XCTAssertEqual(result.textAlignment, .left)
    }

    // MARK: - apply(_:)

    func testApplyUpdatesAllFields() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "split")
        container.mainContext.insert(record)

        let s = DesignSettings(
            textColor: "#AABBCC",
            accentColor: "#DDEEFF",
            secondaryColor: "#112233",
            cardBackground: "#445566",
            overlayOpacity: 0.3,
            glassBlur: 10.0,
            backgroundBlur: 2.0,
            brightness: -0.1,
            textShadow: 1.5,
            fontFamily: .futura,
            textAlignment: .right,
            useCalendarColors: false,
            splitRatio: 0.65
        )
        record.apply(s)

        XCTAssertEqual(record.textColor, "#AABBCC")
        XCTAssertEqual(record.accentColor, "#DDEEFF")
        XCTAssertEqual(record.secondaryColor, "#112233")
        XCTAssertEqual(record.cardBackground, "#445566")
        XCTAssertEqual(record.overlayOpacity, 0.3)
        XCTAssertEqual(record.glassBlur, 10.0)
        XCTAssertEqual(record.backgroundBlur, 2.0)
        XCTAssertEqual(record.brightness, -0.1)
        XCTAssertEqual(record.textShadow, 1.5)
        XCTAssertEqual(record.fontFamilyRaw, FontFamily.futura.rawValue)
        XCTAssertEqual(record.textAlignmentRaw, TextAlignment.right.rawValue)
        XCTAssertFalse(record.useCalendarColors)
        XCTAssertEqual(record.splitRatio, 0.65)
    }

    func testApplyThenAsDesignSettingsIsIdentity() throws {
        let container = try makeContainer()
        let record = SavedTemplateSettings(templateTypeRaw: "editorial")
        container.mainContext.insert(record)

        for fontFamily in FontFamily.allCases {
            let s = DesignSettings(fontFamily: fontFamily)
            record.apply(s)
            XCTAssertEqual(record.asDesignSettings.fontFamily, fontFamily)
        }
    }
}
```

### Step 2: Run tests to verify they fail

```bash
cd /Users/ronen/Desktop/dev/personal/projects/Schedulock
xcodebuild test \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SchedulockTests/SavedTemplateSettingsTests \
  2>&1 | grep -E "(error:|FAIL|PASS|SavedTemplateSettings)"
```

Expected: compile error — `SavedTemplateSettings` does not exist.

### Step 3: Create the model

Create `Shared/Sources/Shared/Models/SavedTemplateSettings.swift`:

```swift
import Foundation
import SwiftData

/// Persisted per-template styling preferences.
/// One record exists per TemplateType, seeded at first launch.
@Model
public final class SavedTemplateSettings {
    public var templateTypeRaw: String

    // Typography
    public var fontFamilyRaw: String
    public var textShadow: Double

    // Colors
    public var textColor: String
    public var accentColor: String
    public var secondaryColor: String
    public var cardBackground: String
    public var useCalendarColors: Bool

    // Effects
    public var overlayOpacity: Double
    public var glassBlur: Double
    public var backgroundBlur: Double
    public var brightness: Double

    // Layout
    public var textAlignmentRaw: String
    public var splitRatio: Double

    public init(templateTypeRaw: String, defaults: DesignSettings = .default) {
        self.templateTypeRaw = templateTypeRaw
        self.fontFamilyRaw = defaults.fontFamily.rawValue
        self.textShadow = defaults.textShadow
        self.textColor = defaults.textColor
        self.accentColor = defaults.accentColor
        self.secondaryColor = defaults.secondaryColor
        self.cardBackground = defaults.cardBackground
        self.useCalendarColors = defaults.useCalendarColors
        self.overlayOpacity = defaults.overlayOpacity
        self.glassBlur = defaults.glassBlur
        self.backgroundBlur = defaults.backgroundBlur
        self.brightness = defaults.brightness
        self.textAlignmentRaw = defaults.textAlignment.rawValue
        self.splitRatio = defaults.splitRatio
    }

    /// Convert this record to a DesignSettings value.
    public var asDesignSettings: DesignSettings {
        DesignSettings(
            textColor: textColor,
            accentColor: accentColor,
            secondaryColor: secondaryColor,
            cardBackground: cardBackground,
            overlayOpacity: overlayOpacity,
            glassBlur: glassBlur,
            backgroundBlur: backgroundBlur,
            brightness: brightness,
            textShadow: textShadow,
            fontFamily: FontFamily(rawValue: fontFamilyRaw) ?? .sfPro,
            textAlignment: TextAlignment(rawValue: textAlignmentRaw) ?? .left,
            useCalendarColors: useCalendarColors,
            splitRatio: splitRatio
        )
    }

    /// Overwrite all fields from a DesignSettings value.
    public func apply(_ s: DesignSettings) {
        textColor = s.textColor
        accentColor = s.accentColor
        secondaryColor = s.secondaryColor
        cardBackground = s.cardBackground
        overlayOpacity = s.overlayOpacity
        glassBlur = s.glassBlur
        backgroundBlur = s.backgroundBlur
        brightness = s.brightness
        textShadow = s.textShadow
        fontFamilyRaw = s.fontFamily.rawValue
        textAlignmentRaw = s.textAlignment.rawValue
        useCalendarColors = s.useCalendarColors
        splitRatio = s.splitRatio
    }
}
```

### Step 4: Run tests to verify they pass

```bash
xcodebuild test \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SchedulockTests/SavedTemplateSettingsTests \
  2>&1 | grep -E "(error:|FAIL|PASS|SavedTemplateSettings)"
```

Expected: all tests PASS.

### Step 5: Commit

```bash
git add Shared/Sources/Shared/Models/SavedTemplateSettings.swift \
        Tests/SchedulockTests/SavedTemplateSettingsTests.swift
git commit -m "feat: add SavedTemplateSettings SwiftData model with asDesignSettings + apply()"
```

---

## Task 2: Register model in container and seed on first launch

**Files:**
- Modify: `App/SchedulockApp.swift` — add `SavedTemplateSettings.self` to modelContainer
- Modify: `App/Views/ContentView.swift` — seed records on `.onAppear`

---

### Step 1: Add `SavedTemplateSettings` to the model container

In `App/SchedulockApp.swift`, find the `.modelContainer(for: [...])` call and add `SavedTemplateSettings.self`:

```swift
.modelContainer(for: [
    WallpaperTemplate.self,
    CalendarSource.self,
    GenerationHistory.self,
    SavedTemplateSettings.self   // ← add this
])
```

### Step 2: Add seeding logic to ContentView

In `App/Views/ContentView.swift`, add:

1. At the top of the struct (with other properties):
```swift
@Environment(\.modelContext) private var modelContext
```

2. On the `mainTabView` computed property's outermost view, add `.onAppear`:
```swift
private var mainTabView: some View {
    TabView(selection: $selectedTab) {
        // ... existing tabs unchanged ...
    }
    .tint(DesignTokens.primary)
    .onAppear { seedTemplateSettingsIfNeeded() }
}
```

3. Add the seeding function to ContentView:
```swift
private func seedTemplateSettingsIfNeeded() {
    let existing = (try? modelContext.fetch(FetchDescriptor<SavedTemplateSettings>()))
        .map { Set($0.map(\.templateTypeRaw)) } ?? []
    for type in TemplateType.allCases {
        guard !existing.contains(type.rawValue) else { continue }
        modelContext.insert(SavedTemplateSettings(templateTypeRaw: type.rawValue))
    }
    try? modelContext.save()
}
```

### Step 3: Build and verify no compile errors

```bash
xcodebuild build \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`.

### Step 4: Commit

```bash
git add App/SchedulockApp.swift App/Views/ContentView.swift
git commit -m "feat: register SavedTemplateSettings in model container and seed on launch"
```

---

## Task 3: Wire TemplateEditorView to load and save per-template settings

**Files:**
- Modify: `App/Views/TemplateEditorView.swift`

---

### Step 1: Add modelContext and stored settings state

At the top of `TemplateEditorView`, add alongside the existing properties:

```swift
@Environment(\.modelContext) private var modelContext
@State private var savedRecord: SavedTemplateSettings?
```

### Step 2: Load saved settings on appear

Add `.onAppear` to the outermost `ZStack` in `TemplateEditorView.body`:

```swift
.onAppear { loadSavedSettings() }
```

Add the helper function:

```swift
private func loadSavedSettings() {
    let raw = templateType.rawValue
    let descriptor = FetchDescriptor<SavedTemplateSettings>(
        predicate: #Predicate { $0.templateTypeRaw == raw }
    )
    if let record = try? modelContext.fetch(descriptor).first {
        savedRecord = record
        settings = record.asDesignSettings
    }
}
```

### Step 3: Save settings in approveTemplate()

In the existing `approveTemplate()` function, add saving the record **before** the existing lines:

```swift
private func approveTemplate() {
    // Persist design settings
    savedRecord?.apply(settings)
    try? modelContext.save()

    // existing lines below — do not change them:
    defaultTemplateTypeRawValue = templateType.rawValue
    viewModel.selectedTemplateType = templateType
    viewModel.designSettings = settings
    // ... rest of existing approveTemplate() ...
}
```

### Step 4: Add "Apply to All" toolbar button

In the `.toolbar` modifier of `TemplateEditorView.body`, add a second `ToolbarItem`:

```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button("Apply to All") {
        applySettingsToAllTemplates()
    }
    .font(.subheadline)
    .foregroundStyle(DesignTokens.textMuted)
}
```

Add the helper:

```swift
private func applySettingsToAllTemplates() {
    let all = (try? modelContext.fetch(FetchDescriptor<SavedTemplateSettings>())) ?? []
    for record in all {
        record.apply(settings)
    }
    try? modelContext.save()
}
```

### Step 5: Build to verify

```bash
xcodebuild build \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`.

### Step 6: Commit

```bash
git add App/Views/TemplateEditorView.swift
git commit -m "feat: wire TemplateEditorView to load/save SavedTemplateSettings + Apply to All"
```

---

## Task 4: Wire TemplateGalleryView to show saved-settings previews

**Files:**
- Modify: `App/Views/TemplateGalleryView.swift`

---

### Step 1: Add @Query for saved settings

At the top of `TemplateGalleryView` (with other properties):

```swift
@Query private var allSavedSettings: [SavedTemplateSettings]
```

### Step 2: Add helper to look up settings per type

```swift
private func savedDesignSettings(for type: TemplateType) -> DesignSettings {
    allSavedSettings.first { $0.templateTypeRaw == type.rawValue }?.asDesignSettings ?? .default
}
```

### Step 3: Pass saved settings to each preview

In the `ForEach` inside `TemplateGalleryView.body`, change:

```swift
// Before:
preview: viewModel.generatePreview(
    templateType: template,
    settings: .default
),

// After:
preview: viewModel.generatePreview(
    templateType: template,
    settings: savedDesignSettings(for: template)
),
```

### Step 4: Build to verify

```bash
xcodebuild build \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`.

### Step 5: Commit

```bash
git add App/Views/TemplateGalleryView.swift
git commit -m "feat: TemplateGalleryView previews now use saved per-template DesignSettings"
```

---

## Task 5: Fix HomeView — respect saveToPhotos and use saved DesignSettings

**Files:**
- Modify: `App/Views/HomeView.swift`

---

### Step 1: Add @Query for saved settings

At the top of `HomeView` (with other `@AppStorage` properties):

```swift
@Query private var allSavedSettings: [SavedTemplateSettings]
```

### Step 2: Fix the unconditional photo save

In `generateWallpaper()`, find step 6:

```swift
// Before (always saves regardless of setting):
UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)

// After:
if saveToPhotos {
    UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)
}
```

### Step 3: Use saved DesignSettings before generating

In `generateWallpaper()`, find the comment `// 3. Configure template and device resolution from settings`.
After `viewModel.selectedTemplateType = ...`, add:

```swift
// Load per-template design settings
let savedSettings = allSavedSettings.first { $0.templateTypeRaw == defaultTemplateTypeRawValue }
viewModel.designSettings = savedSettings?.asDesignSettings ?? .default
```

### Step 4: Build to verify

```bash
xcodebuild build \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`.

### Step 5: Commit

```bash
git add App/Views/HomeView.swift
git commit -m "fix: respect saveToPhotos setting and apply saved DesignSettings on generation"
```

---

## Task 6: Restructure SettingsView

**Files:**
- Modify: `App/Views/SettingsView.swift`

Remove `autoGenerateTime` and `clockFormat` AppStorage properties and their UI rows.
Move `targetDeviceName` to an Advanced section.
Add About section.
Wire `clearHistory()` to actually delete `GenerationHistory` records.

---

### Step 1: Remove obsolete AppStorage properties

Remove these two `@AppStorage` declarations from `SettingsView`:

```swift
// DELETE:
@AppStorage("autoGenerateTime", store: AppGroupManager.userDefaults)
private var autoGenerateTime: TimeInterval = 18000

@AppStorage("clockFormat", store: AppGroupManager.userDefaults)
private var clockFormat: String = "24h"
```

Also remove the `autoGenerateDateBinding` computed property.

### Step 2: Add modelContext for clearHistory

At the top of `SettingsView` (with other properties):

```swift
@Environment(\.modelContext) private var modelContext
```

### Step 3: Replace the full List body

Replace the entire `List { ... }` block with the restructured version:

```swift
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
                .foregroundStyle(DesignTokens.textPrimary)
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                .foregroundStyle(DesignTokens.textMuted)
        }

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
                .foregroundStyle(DesignTokens.textPrimary)
        }
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
```

### Step 4: Fix clearHistory() to actually delete records

Replace the existing stub:

```swift
// Before:
private func clearHistory() {
    print("Clearing history...")
}

// After:
private func clearHistory() {
    try? modelContext.delete(model: GenerationHistory.self)
    try? modelContext.save()
}
```

### Step 5: Update resetDefaults() — remove obsolete keys

In `resetDefaults()`, remove the two lines for `autoGenerateTime` and `clockFormat`:

```swift
private func resetDefaults() {
    // Keep only these resets:
    targetDeviceName = DeviceResolution.iPhone16Pro.name
    notificationsEnabled = false
    saveToPhotos = false
    maxEvents = 6
    showDeclined = false
    showAllDay = true
    defaultTemplateTypeRawValue = TemplateType.minimal.rawValue
    randomizeDaily = false
    AppGroupManager.userDefaults.set(false, forKey: "onboardingCompleted")
}
```

### Step 6: Build to verify

```bash
xcodebuild build \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`.

### Step 7: Run all tests

```bash
xcodebuild test \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  2>&1 | grep -E "(error:|FAIL|PASS|Test Suite)"
```

Expected: all tests PASS.

### Step 8: Commit

```bash
git add App/Views/SettingsView.swift
git commit -m "feat: restructure SettingsView — remove clock/time, add Advanced + About sections, fix clearHistory"
```

---

## Summary of all commits

| Commit | What |
|--------|------|
| `feat: add SavedTemplateSettings SwiftData model` | Task 1 — model + tests |
| `feat: register SavedTemplateSettings and seed on launch` | Task 2 — container + seeding |
| `feat: TemplateEditorView loads/saves per-template settings + Apply to All` | Task 3 |
| `feat: TemplateGalleryView previews use saved per-template settings` | Task 4 |
| `fix: respect saveToPhotos and apply saved DesignSettings on generation` | Task 5 |
| `feat: restructure SettingsView` | Task 6 |
