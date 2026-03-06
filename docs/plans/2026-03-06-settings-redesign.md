# Settings Redesign & Per-Template Persistence

**Date:** 2026-03-06
**Status:** Approved

---

## Overview

Restructure the Settings screen for clarity, implement per-template `DesignSettings` persistence via SwiftData, surface the template editor's existing styling controls, and fix two existing bugs (`saveToPhotos` ignored, `clearHistory` is a stub).

---

## 1. Settings Screen Restructure

Remove noise, regroup into logical sections.

### Sections (final structure)

| Section | Items |
|---|---|
| **General** | Notifications toggle, Save to Photos toggle |
| **Calendar** | Select Calendars (nav), Max Events stepper, Show Declined toggle, Show All-Day toggle |
| **Appearance** | Default Template picker, Randomize Daily toggle |
| **Advanced** | Target Device picker |
| **About** | App Version (read from Bundle), Shortcuts Guide (nav to existing `ShortcutsGuideView`), Open System Settings (opens `UIApplication.openSettingsURLString`) |
| **Data & Privacy** | Clear History (wired to SwiftData), Clear Cache, Reset Defaults |

### Removals
- **Auto-Generate Time** — redundant with Shortcuts automation, removed entirely
- **Clock Format** — removed from Appearance (the renderers do not use it; it was a placeholder)

### Moves
- **Target Device** — moved from General → Advanced

---

## 2. Per-Template DesignSettings — SwiftData Model

### New model: `SavedTemplateSettings`

```swift
@Model
final class SavedTemplateSettings {
    var templateTypeRaw: String   // unique; matches TemplateType.rawValue

    // Typography
    var fontFamilyRaw: String
    var textShadow: Double

    // Colors
    var textColor: String
    var accentColor: String
    var secondaryColor: String
    var cardBackground: String
    var useCalendarColors: Bool

    // Effects
    var overlayOpacity: Double
    var glassBlur: Double
    var backgroundBlur: Double
    var brightness: Double

    // Layout
    var textAlignmentRaw: String
    var splitRatio: Double
}
```

- One record per `TemplateType` (6 total), seeded at first launch from `DesignSettings.default`
- Helper computed properties: `var asDesignSettings: DesignSettings` and `func apply(_ settings: DesignSettings)`
- Stored in the existing SwiftData `ModelContainer` (same as `GenerationHistory`)

### Seeding

On app launch (in `ContentView` or `App` entry), if no records exist for a template type, insert defaults for all 6 types.

---

## 3. TemplateEditorView — Load & Save

- On `.onAppear`: fetch `SavedTemplateSettings` where `templateTypeRaw == templateType.rawValue`; populate `@State var settings`
- On `approveTemplate()`: call `record.apply(settings)` then `try? modelContext.save()`
- New **"Apply to All"** toolbar button: iterates all 6 `SavedTemplateSettings` records, calls `record.apply(settings)` on each, then saves

---

## 4. TemplateGalleryView — Live Previews

- Add `@Query var allSavedSettings: [SavedTemplateSettings]`
- Helper: `func savedSettings(for type: TemplateType) -> DesignSettings`
- Pass per-template `DesignSettings` (instead of `.default`) into each `TemplateCard` preview

---

## 5. HomeView — Bug Fixes

### Fix A: `saveToPhotos` respected
```swift
// Before (line 241):
UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)

// After:
if saveToPhotos {
    UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)
}
```

### Fix B: Use saved DesignSettings for generation
In `generateWallpaper()`, fetch `SavedTemplateSettings` for `defaultTemplateTypeRawValue` from SwiftData and pass as `viewModel.designSettings` before calling `generateFullResolution`.

### Fix C: `clearHistory()` actually deletes
Replace the `print("Clearing history...")` stub with a `@Query`-backed delete of all `GenerationHistory` records.

---

## Files Touched

| File | Change |
|---|---|
| `Shared/Sources/Shared/Models/SavedTemplateSettings.swift` | **New** — SwiftData model |
| `App/Views/SettingsView.swift` | Restructure sections, wire clearHistory |
| `App/Views/TemplateEditorView.swift` | Load/save per-template settings, "Apply to All" |
| `App/Views/TemplateGalleryView.swift` | Use saved settings for previews |
| `App/Views/HomeView.swift` | Fix saveToPhotos + use saved DesignSettings |
| `App/SchedulockApp.swift` or `ContentView.swift` | Seed SavedTemplateSettings on first launch |
