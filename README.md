# Schedulock

**Daily wallpaper with your agenda.** Schedulock is a native iOS app that generates personalized lock screen wallpapers by compositing user-selected photos with calendar agenda data. Wake up to a fresh wallpaper every morning showing your day at a glance.

## Features

- **6 Design Templates** — Minimal, Frosted Glass, Gradient Band, Editorial, Neon Glow, and Split View
- **Calendar Integration** — Select which calendars to display via EventKit; supports all-day events, multiple calendars, and color-coded entries
- **Live Template Editor** — Customize typography, colors, effects (blur, brightness, overlay), and layout with real-time preview
- **Automatic Generation** — Background task generates a new wallpaper daily at 4 AM via `BGProcessingTask`
- **Shortcuts Automation** — iOS Shortcuts integration via `AppIntents` for on-demand wallpaper generation
- **Lock Screen Widgets** — Three WidgetKit families: inline (above clock), circular (event count), rectangular (3-event agenda)
- **7-Screen Onboarding** — Guided setup for calendar permission, photo selection, calendar picking, template choice, and automation
- **Fully Offline** — All processing happens on-device. No data leaves your phone.

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9**
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for project regeneration)

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd Schedulock
```

### 2. Install xcodegen (if needed)

```bash
brew install xcodegen
```

### 3. Generate the Xcode project

The Xcode project is generated from `project.yml`. If you need to regenerate it after making changes:

```bash
xcodegen generate
```

### 4. Open and run

```bash
open Schedulock.xcodeproj
```

Select the **Schedulock** scheme, choose an iPhone simulator (iPhone 15 Pro or later recommended), and hit **Cmd+R**.

> **Note:** Calendar access requires the simulator or a real device. The app gracefully handles denied permissions with a prompt to grant access in Settings.

### 5. Run tests

```bash
xcodebuild test \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO
```

Or run tests from Xcode via **Cmd+U**.

## Architecture

Schedulock is built with a **SwiftUI + UIKit hybrid** approach — SwiftUI for the app chrome, Core Graphics for pixel-perfect wallpaper rendering at exact device resolutions.

### Targets

```
Schedulock.xcodeproj
├── Schedulock              (Main App — SwiftUI)
├── SchedulockWidgetExtension   (WidgetKit — Lock Screen Widgets)
├── SchedulockIntentExtension   (AppIntents — Shortcuts)
├── SchedulockTests             (Unit & Integration Tests)
└── Shared                      (Local Swift Package — shared across all targets)
```

All targets communicate through an **App Group** (`group.com.ronenmars.Schedulock`) for shared images, settings, and wallpaper output.

### Project Structure

```
Schedulock/
├── App/
│   ├── SchedulockApp.swift             # @main entry point
│   ├── BackgroundTaskManager.swift     # BGProcessingTask for daily generation
│   ├── Info.plist                      # App configuration
│   ├── PrivacyInfo.xcprivacy           # Apple privacy manifest
│   ├── Schedulock.entitlements         # App Group entitlement
│   ├── ViewModels/
│   │   ├── CalendarViewModel.swift     # Calendar state management
│   │   └── WallpaperViewModel.swift    # Rendering orchestration
│   ├── Views/
│   │   ├── ContentView.swift           # Root view with onboarding gate
│   │   ├── HomeView.swift              # Wallpaper preview + generate button
│   │   ├── TemplateGalleryView.swift   # Template grid with live previews
│   │   ├── TemplateEditorView.swift    # Design customization editor
│   │   ├── CalendarPickerView.swift    # Calendar selection with toggles
│   │   ├── HistoryView.swift           # Generation history log
│   │   ├── SettingsView.swift          # App settings (4 sections)
│   │   ├── OnboardingView.swift        # 7-screen first-launch flow
│   │   └── ShortcutsGuideView.swift    # Shortcuts setup walkthrough
│   └── Resources/
│       └── Assets.xcassets/            # App icon, accent color
│
├── Shared/                             # Local Swift Package
│   ├── Package.swift
│   └── Sources/Shared/
│       ├── Models/
│       │   ├── CalendarEvent.swift     # Event data with title truncation
│       │   ├── CalendarSource.swift    # SwiftData — saved calendar selection
│       │   ├── DesignSettings.swift    # Codable struct — all design parameters
│       │   ├── FontFamily.swift        # 6 font options (SF Pro, Avenir, etc.)
│       │   ├── GenerationHistory.swift # SwiftData — generation log
│       │   ├── TemplateType.swift      # 6 template types enum
│       │   ├── TextAlignment.swift     # Left, center, right
│       │   └── WallpaperTemplate.swift # SwiftData — template with settings
│       ├── Engine/
│       │   ├── WallpaperRenderer.swift # Protocol + DeviceResolution registry
│       │   ├── WallpaperEngine.swift   # Orchestrator — CGContext creation + delegation
│       │   ├── CalendarDataProvider.swift # EventKit integration
│       │   └── TemplateRenderers/
│       │       ├── MinimalRenderer.swift
│       │       ├── GlassRenderer.swift
│       │       ├── GradientBandRenderer.swift
│       │       ├── EditorialRenderer.swift
│       │       ├── NeonRenderer.swift
│       │       └── SplitViewRenderer.swift
│       └── Utilities/
│           ├── AppGroupManager.swift   # Shared container paths + UserDefaults
│           ├── ColorUtils.swift        # Hex parsing, gradients, blending
│           ├── DesignTokens.swift      # Color palette, spacing, radii
│           ├── ImageProcessor.swift    # CIImage blur, crop, brightness
│           └── TextRenderer.swift      # Core Text drawing + measurement
│
├── WidgetExtension/
│   └── SchedulockWidget.swift          # 3 widget families + timeline provider
│
├── IntentExtension/
│   └── GenerateWallpaperIntent.swift   # AppIntent for Shortcuts
│
├── Tests/SchedulockTests/
│   ├── SchedulockTests.swift           # Core model unit tests
│   ├── RenderingTests.swift            # Rendering pipeline tests
│   ├── SnapshotTests.swift             # All templates x fonts x resolutions
│   ├── EdgeCaseTests.swift             # Boundary conditions + stress tests
│   ├── CalendarProviderTests.swift     # Calendar data provider tests
│   └── UtilityTests.swift              # ImageProcessor, TextRenderer, ColorUtils
│
├── project.yml                         # xcodegen project spec
└── docs/
    └── AppStoreMetadata.md             # App Store submission metadata
```

### Rendering Pipeline

The wallpaper generation pipeline follows a **protocol-first** design:

1. **WallpaperRenderer** — Protocol that all template renderers conform to. Each receives a `CGContext`, target size, optional background image, calendar events, design settings, and current date.
2. **WallpaperEngine** — Orchestrator that creates a `CGContext` at the target device resolution, delegates to the appropriate renderer, and extracts a `UIImage`.
3. **Template Renderers** — 6 implementations, each producing a distinct visual style using Core Graphics drawing primitives.
4. **Supporting Utilities** — `ImageProcessor` (CIImage blur/crop/brightness), `TextRenderer` (Core Text drawing), `ColorUtils` (hex parsing, gradients).

```
User taps "Generate"
       │
       ▼
WallpaperViewModel.generatePreview()
       │
       ▼
WallpaperEngine.generateWallpaper()
       │
       ├── Creates CGContext at DeviceResolution
       ├── Looks up renderer for TemplateType
       ├── Calls renderer.render(context:size:...)
       │       │
       │       ├── Draws background (image or gradient)
       │       ├── Applies effects (blur, overlay, brightness)
       │       ├── Renders event list with TextRenderer
       │       └── Applies template-specific styling
       │
       └── Extracts UIImage from CGContext
```

### Device Resolution Support

Wallpapers are rendered at pixel-perfect resolution for each iPhone model:

| Device | Resolution | Scale |
|--------|-----------|-------|
| iPhone SE 3 | 750 x 1334 | 2x |
| iPhone 14/15 | 1170 x 2532 | 3x |
| iPhone 15 Pro | 1179 x 2556 | 3x |
| iPhone 15 Pro Max | 1290 x 2796 | 3x |
| iPhone 16 Pro | 1206 x 2622 | 3x |
| iPhone 16 Pro Max | 1320 x 2868 | 3x |

### Data Flow

```
┌─────────────────────────────────────────────┐
│              App Group Container            │
│  group.com.ronenmars.Schedulock             │
│                                             │
│  ├── Wallpapers/current.png                 │
│  ├── Images/background-processed.jpg        │
│  └── UserDefaults (settings, calendar IDs)  │
└──────┬──────────────┬──────────────┬────────┘
       │              │              │
  Main App      Widget Ext     Intent Ext
  (generate)    (read events)  (Shortcuts)
```

### Design System

The app uses a **dark-first** design language defined in `DesignTokens.swift`:

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#0A0B0F` | Main app background |
| `surface` | `#0F1014` | Cards, panels |
| `primary` | `#6C63FF` | Actions, accents |
| `primaryGlow` | `#E040FB` | Gradient end, premium feel |
| `textPrimary` | `#E8E8ED` | Primary text |
| `textMuted` | `#555555` | Secondary text |
| `success` | `#34C759` | Success states |
| `danger` | `#FF3B30` | Destructive actions |

Spacing follows an **8pt grid**: 4, 8, 16, 24, 32pt. Corner radii: 12pt (cards), 20pt (glass), 32pt (phone frame).

## Templates

| Template | Style | Description |
|----------|-------|-------------|
| **Minimal** | Clean, dark | Dark background with clean typography and subtle event cards |
| **Frosted Glass** | Translucent | Glass-morphism cards over blurred background image |
| **Gradient Band** | Colorful | Gradient color band behind event text |
| **Editorial** | Magazine-like | Large serif typography with editorial layout |
| **Neon Glow** | Vibrant | Neon-colored text with glow effects |
| **Split View** | Two-panel | Photo on top, agenda on bottom with configurable split ratio |

## Automation

### Background Task

The app registers a `BGProcessingTask` that runs daily at 4 AM:

1. Loads user settings and selected template from App Group
2. Fetches today's calendar events via EventKit
3. Renders wallpaper at device resolution
4. Saves to App Group shared container
5. Posts a local notification
6. Reschedules for the next day

### iOS Shortcuts

The `GenerateWallpaperIntent` (`AppIntents` framework) allows users to create Shortcuts automations:

- Trigger: Time of Day, When Opening App, etc.
- Action: "Generate Wallpaper" from Schedulock
- Output: PNG image file

## Lock Screen Widgets

Three widget families are available via WidgetKit:

| Family | Description |
|--------|-------------|
| **Inline** (`.accessoryInline`) | Shows next event time and title above the clock |
| **Circular** (`.accessoryCircular`) | Shows next event time or total event count |
| **Rectangular** (`.accessoryRectangular`) | Shows "AGENDA" header with up to 3 events |

The timeline provider creates entries at each event transition point (start/end times) and refreshes at midnight.

## Testing

The test suite contains **6 test files** covering:

| File | Coverage |
|------|----------|
| `SchedulockTests.swift` | Core models: DesignSettings codable round-trip, TemplateType, FontFamily, CalendarEvent truncation, DeviceResolution, WallpaperTemplate |
| `RenderingTests.swift` | All 6 renderers: output validation, edge cases (0/50 events, all-day), all resolutions, custom settings, concurrent rendering |
| `SnapshotTests.swift` | Template matrix: all templates x event counts x font families x RTL text, resolution validation, pixel content checks |
| `EdgeCaseTests.swift` | Boundary conditions: long titles, empty data, midnight rollover, 100+ events, extreme DesignSettings, Unicode/emoji |
| `CalendarProviderTests.swift` | CalendarDataProvider structural tests |
| `UtilityTests.swift` | ImageProcessor, TextRenderer, ColorUtils, AppGroupManager, DesignTokens |

Run all tests:

```bash
xcodebuild test \
  -project Schedulock.xcodeproj \
  -scheme Schedulock \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO
```

## Configuration

Settings are stored in the App Group's `UserDefaults` and accessible from all targets:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `autoGenerateTime` | `TimeInterval` | `18000` (5 AM) | Daily auto-generation time |
| `targetDevice` | `String` | Device name | Target resolution for rendering |
| `defaultTemplateType` | `String` | `"minimal"` | Default template to use |
| `enabledCalendarIDs` | `[String]` | `[]` | Selected calendar identifiers |
| `maxEvents` | `Int` | `6` | Maximum events to display |
| `clockFormat` | `String` | `"24h"` | Time format (12h/24h) |
| `showDeclined` | `Bool` | `false` | Include declined events |
| `showAllDay` | `Bool` | `true` | Include all-day events |
| `randomizeDaily` | `Bool` | `false` | Randomize template each day |
| `onboardingCompleted` | `Bool` | `false` | Has onboarding been completed |

## Privacy

- **No data collection** — All processing happens on-device
- **No network requests** — The app works fully offline
- **Calendar access is read-only** — Used exclusively to display event titles and times
- **No tracking** — No analytics, no telemetry, no third-party SDKs
- Privacy manifest (`PrivacyInfo.xcprivacy`) declares `UserDefaults` and `FileTimestamp` API usage

## License

All rights reserved.
