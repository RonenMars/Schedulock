**Schedulock: Schedulock app**

iOS Lock Screen Wallpaper Generator

*Design & Implementation Plan*

Version 1.0 \| February 2026

Target: iOS 16.2+ \| Swift 5.9 \| SwiftUI + UIKit

Xcode 15+ \| Minimum deployment: iPhone 8 and later

**Contents**

**1.** Executive Summary

**2.** Architecture Overview

**3.** Project Structure

**4.** Phase 1: Foundation & Core Data

**5.** Phase 2: Calendar Integration (EventKit)

**6.** Phase 3: Wallpaper Rendering Engine

**7.** Phase 4: Design Templates & Customization

**8.** Phase 5: Background Scheduler (BGTaskScheduler)

**9.** Phase 6: Shortcuts Integration (AppIntents)

**10.** Phase 7: Lock Screen Widget (WidgetKit)

**11.** Phase 8: Settings, Onboarding & Polish

**12.** Phase 9: Testing & QA

**13.** Phase 10: App Store Submission

**14.** UI/UX Design Specifications

**15.** Data Model Reference

**16.** Risk Registry & Mitigations

**17.** Timeline & Milestones

**18.** Claude Code Playbook: Agent Teams Strategy

**19.** MCP Server Tooling

**1. Executive Summary**

Schedulock is a native iOS application that generates personalized lock screen wallpapers by compositing user-selected photos with calendar agenda data. The app renders a fresh wallpaper daily, combining beautiful design templates with practical at-a-glance scheduling information.

**Core Value Proposition**

-   Automated daily wallpaper that shows today's schedule at a glance

-   Multiple design templates: from minimal to editorial to neon aesthetics

-   Deep calendar integration: pick any combination of calendars

-   True automation: wallpaper updates itself overnight via iOS Shortcuts

-   Lock screen widget companion for real-time agenda display

**Key Technical Decisions**

  ---------------------------- -----------------------------------------------------------------------------------
  **Decision**                 **Rationale**

  **Native Swift (not RN)**    AppIntents, WidgetKit, BGTaskScheduler have no React Native equivalents

  **SwiftUI + UIKit hybrid**   SwiftUI for app chrome, UIKit/Core Graphics for pixel-perfect wallpaper rendering

  **Core Graphics renderer**   Pixel-perfect control for export at exact device resolutions

  **App Group shared data**    Widget extension + main app + intent extension share images/settings

  **SwiftData persistence**    Modern Apple ORM for templates, user preferences, and generation history
  ---------------------------- -----------------------------------------------------------------------------------

**2. Architecture Overview**

**2.1 High-Level Component Diagram**

The application is composed of four targets sharing a core rendering engine and data layer through an App Group container:

> ┌──────────────────────────────────────────────────┐
>
> │ Schedulock Main App (SwiftUI) │
>
> │ ┌────────────┐ ┌─────────────┐ ┌──────────────┐ │
>
> │ │ Image │ │ Calendar │ │ Template │ │
>
> │ │ Picker │ │ Selector │ │ Editor │ │
>
> │ └────────────┘ └─────────────┘ └──────────────┘ │
>
> └─────────┬─────────────┬─────────────┬────────┘
>
> │ App Group │ Shared │
>
> ┌───────┴─┐ Container ┌┴──────┐ ┌┴────────┐
>
> │ Widget │ (images+ │ Intent │ │ BG Task │
>
> │ Extn │ settings) │ Extn │ │ Scheduler│
>
> └────────┘ └───────┘ └─────────┘

**2.2 Data Flow: Daily Wallpaper Generation**

1.  BGTaskScheduler fires at configured time (default: 5:00 AM)

2.  WallpaperEngine reads user settings from App Group container

3.  EventKit fetches today's events from selected calendars

4.  Core Graphics composites: background image + template overlay + event data

5.  Rendered image saved to App Group shared directory

6.  AppIntent triggered → Shortcuts automation sets wallpaper on lock screen

7.  Widget extension refreshes timeline with updated agenda

8.  Optional push notification sent with wallpaper preview

**2.3 Framework Dependencies**

  --------------------- ----------------------------------------- --------------------------
  **Framework**         **Purpose**                               **Target**

  **SwiftUI**           App UI, navigation, state management      Main App

  **Core Graphics**     Pixel-perfect wallpaper rendering         All targets

  **EventKit**          Calendar read access                      Main App, BG Task

  **PhotosUI**          PHPicker for image selection              Main App

  **WidgetKit**         Lock screen widget                        Widget Extension

  **AppIntents**        Shortcuts "Set Wallpaper" hook            Intent Extension

  **BGTaskScheduler**   Overnight wallpaper generation            Main App

  **SwiftData**         Persistence (templates, prefs, history)   All targets
  --------------------- ----------------------------------------- --------------------------

**3. Project Structure**

The Xcode project contains four targets sharing a common Swift Package:

> Schedulock/
>
> ├── Schedulock.xcodeproj
>
> ├── App/ \# Main app target
>
> │ ├── SchedulockApp.swift \# \@main entry point
>
> │ ├── Views/
>
> │ │ ├── HomeView.swift
>
> │ │ ├── ImagePickerView.swift
>
> │ │ ├── CalendarPickerView.swift
>
> │ │ ├── TemplateGalleryView.swift
>
> │ │ ├── TemplateEditorView.swift
>
> │ │ ├── PreviewView.swift
>
> │ │ ├── SettingsView.swift
>
> │ │ └── OnboardingView.swift
>
> │ ├── ViewModels/
>
> │ │ ├── WallpaperViewModel.swift
>
> │ │ └── CalendarViewModel.swift
>
> │ └── Resources/
>
> ├── Shared/ \# Shared Swift Package
>
> │ ├── Models/
>
> │ │ ├── WallpaperTemplate.swift
>
> │ │ ├── DesignSettings.swift
>
> │ │ ├── CalendarSource.swift
>
> │ │ └── GenerationHistory.swift
>
> │ ├── Engine/
>
> │ │ ├── WallpaperRenderer.swift
>
> │ │ ├── TemplateRenderers/
>
> │ │ │ ├── MinimalRenderer.swift
>
> │ │ │ ├── GlassRenderer.swift
>
> │ │ │ ├── GradientBandRenderer.swift
>
> │ │ │ ├── EditorialRenderer.swift
>
> │ │ │ ├── NeonRenderer.swift
>
> │ │ │ └── SplitViewRenderer.swift
>
> │ │ └── CalendarDataProvider.swift
>
> │ └── Utilities/
>
> ├── WidgetExtension/
>
> ├── IntentExtension/
>
> └── Tests/

**4. Phase 1: Foundation & Core Data**

**PHASE 1 Foundation & Core Data**

Estimated duration: 3--4 days. Set up the Xcode project, App Group, shared data layer, and basic navigation shell.

**4.1 Xcode Project Setup**

9.  Create a new Xcode project: iOS App, SwiftUI lifecycle, Swift language

10. Product name: Schedulock. Organization identifier: your reverse-domain

11. Add four targets: Main App, Widget Extension, Intent Extension, Shared Swift Package (local)

12. Enable App Group capability on all targets: group.com.ronenmars.Schedulock

13. Configure signing: each target needs its own provisioning profile

**4.2 App Group & Shared Container**

The App Group container is the backbone that enables all targets to share data:

> struct AppGroupManager {
>
> static let groupID = \"group.com.ronenmars.Schedulock\"
>
> static var containerURL: URL {
>
> FileManager.default.containerURL(
>
> forSecurityApplicationGroupIdentifier: groupID)!
>
> }
>
> static var wallpaperDirectory: URL {
>
> containerURL.appending(path: \"Wallpapers\")
>
> }
>
> static var userDefaults: UserDefaults {
>
> UserDefaults(suiteName: groupID)!
>
> }
>
> }

**4.3 SwiftData Models**

**WallpaperTemplate**

-   id: UUID

-   name: String

-   templateType: TemplateType (enum)

-   isBuiltIn: Bool

-   settings: DesignSettings (Codable)

**DesignSettings (Codable)**

-   textColor, accentColor, secondaryColor, cardBackground: String (hex)

-   overlayOpacity, glassBlur, backgroundBlur, brightness, textShadow: Double

-   fontFamily: FontFamily enum

-   textAlignment: TextAlignment enum

-   useCalendarColors: Bool

-   splitRatio: Double

**CalendarSource**

-   id: String (EKCalendar identifier)

-   name, colorHex: String

-   isEnabled: Bool

**GenerationHistory**

-   id: UUID, generatedAt: Date

-   templateType, imagePath: String

-   eventCount: Int

**4.4 Navigation Shell**

-   Tab 1: Home --- today's wallpaper preview + quick generate

-   Tab 2: Templates --- gallery of designs

-   Tab 3: History --- past generated wallpapers

-   Tab 4: Settings --- calendars, schedule, appearance

**5. Phase 2: Calendar Integration (EventKit)**

**PHASE 2 Calendar Integration**

Estimated duration: 2--3 days.

**5.1 Permission Request Flow**

14. Add NSCalendarsUsageDescription and NSCalendarsFullAccessUsageDescription to Info.plist

15. Request permission during onboarding. Handle authorized, denied, restricted states

16. If denied, deep-link to Settings app with explanation

**5.2 CalendarDataProvider**

> class CalendarDataProvider {
>
> private let store = EKEventStore()
>
> func requestAccess() async throws -\> Bool
>
> func fetchCalendars() -\> \[EKCalendar\]
>
> func fetchTodayEvents(from calIDs: \[String\]) -\> \[CalendarEvent\]
>
> }

**CalendarEvent struct**

-   id, title, calendarName: String

-   startTime, endTime: Date

-   isAllDay: Bool

-   calendarColor: UIColor

-   location: String? (optional)

**5.3 Calendar Picker UI**

-   Group calendars by account (iCloud, Google, Exchange)

-   Color swatch + toggle for each calendar

-   Live count of today's events from selected calendars

-   Pull-to-refresh to reload from EventKit

**5.4 Event Formatting Rules**

-   All-day events: banner at top, no time shown

-   Timed events: HH:mm format, sorted chronologically

-   Declined events: excluded by default (configurable)

-   Max display: 6 events (configurable). Show "+N more" if exceeded

-   Title truncation: ellipsis at 32 characters

**6. Phase 3: Wallpaper Rendering Engine**

**PHASE 3 Core Graphics Rendering**

Estimated duration: 5--7 days. The most complex phase.

**6.1 Rendering Pipeline**

17. Create CGContext at target resolution (e.g. 1179×2556)

18. Draw background image with aspect-fill + optional blur/brightness

19. Apply template-specific overlay layers

20. Render clock text with configured font, size, alignment, shadow

21. Render date text (day, month, date)

22. Render event list with calendar color bars, titles, times

23. Apply post-processing (vignette, noise grain if enabled)

24. Export as PNG UIImage

**6.2 WallpaperRenderer Protocol**

> protocol WallpaperRenderer {
>
> var templateType: TemplateType { get }
>
> func render(context: CGContext, size: CGSize,
>
> backgroundImage: UIImage?,
>
> events: \[CalendarEvent\],
>
> settings: DesignSettings, date: Date)
>
> }
>
> class WallpaperEngine {
>
> private let renderers: \[TemplateType: WallpaperRenderer\]
>
> func generateWallpaper(
>
> template: WallpaperTemplate,
>
> image: UIImage?,
>
> events: \[CalendarEvent\],
>
> resolution: DeviceResolution) -\> UIImage?
>
> }

**6.3 Image Processing**

-   Source: PHPicker image stored in App Group

-   Aspect-fill crop to device ratio (9:19.5)

-   CIGaussianBlur for background blur

-   CIColorControls for brightness adjustment

-   NSAttributedString + CTFramesetter for text layout

-   Cache processed images to avoid redundant computation

**6.4 Device Resolution Registry**

  ----------------------- --------------- --------------- ---------------
  **Device**              **Width**       **Height**      **Scale**

  iPhone SE 3             750             1334            2x

  iPhone 14/15            1170            2532            3x

  iPhone 15 Pro           1179            2556            3x

  iPhone 15 Pro Max       1290            2796            3x

  iPhone 16 Pro           1206            2622            3x

  iPhone 16 Pro Max       1320            2868            3x
  ----------------------- --------------- --------------- ---------------

**7. Phase 4: Design Templates & Customization**

**PHASE 4 6 Design Templates**

Estimated duration: 5--6 days. Implement all six built-in templates.

**7.1 Minimal**

Let the photo breathe. Clock and events overlay with subtle gradients.

-   Top/bottom gradient overlays, opacity-controlled

-   Large clock at top, events bottom-aligned

-   Thin calendar-colored bars per event

**7.2 Frosted Glass**

Floating translucent card with agenda.

-   Glass card: centered, rounded 20pt corners, backdrop blur

-   Card header: "TODAY'S AGENDA" uppercase label

-   Customizable: glass opacity, blur radius, card tint

**7.3 Gradient Band**

Strong color statement with gradient strip at bottom.

-   Linear gradient from accent to secondary color

-   Events: time + dot marker + title layout

-   Customizable: gradient colors, band height

**7.4 Editorial**

Bold typographic statement. The date IS the design.

-   Massive 86pt date number, uppercase day/month

-   Accent bar separator

-   Events bottom-aligned

**7.5 Neon Glow**

Dark, moody, with glowing accent text. Perfect for OLED.

-   Clock in accent color with multi-layered glow shadow

-   Events in rounded pill containers

-   Customizable: glow color, intensity, overlay darkness

**7.6 Split View**

Image on top, solid panel for agenda below.

-   Configurable split ratio (default 55% image)

-   Solid color bottom panel with accent top-border

-   Day name + date header, events below

**7.7 Template Editor UI**

-   Top: scrollable live preview (real-time rendering)

-   Bottom: settings organized in collapsible sections

-   Sections: Typography, Colors, Effects, Layout

-   Save as custom template or reset to defaults

**8. Phase 5: Background Scheduler (BGTaskScheduler)**

**PHASE 5 Background Generation**

Estimated duration: 2--3 days.

**8.1 Task Registration**

> // Info.plist: BGTaskSchedulerPermittedIdentifiers
>
> // -\> com.ronenmars.Schedulock.wallpaper-generation
>
> BGTaskScheduler.shared.register(
>
> forTaskWithIdentifier: \"\...wallpaper-generation\",
>
> using: nil
>
> ) { task in
>
> self.handleWallpaperGeneration(task: task as! BGProcessingTask)
>
> }

**8.2 Scheduling Strategy**

-   Use BGProcessingTask (CPU-intensive rendering)

-   Schedule: earliestBeginDate = next day at 4:00 AM

-   requiresNetworkConnectivity = false (all data local)

-   Re-schedule at END of each successful execution

**8.3 Execution Flow**

25. Load settings from App Group UserDefaults

26. Fetch today's events via EventKit

27. Load background image from App Group

28. Render wallpaper with WallpaperEngine

29. Save to App Group/Wallpapers/current.png

30. Trigger AppIntent for Shortcuts automation

31. Post notification: "Your wallpaper is ready!"

32. Save to GenerationHistory, schedule next execution

**8.4 Failure Handling**

-   No events: generate wallpaper without agenda

-   No image: use gradient fallback

-   Render fails: retry in 30 minutes

-   Low Power Mode: BG task may be deferred (inform user)

**9. Phase 6: Shortcuts Integration (AppIntents)**

**PHASE 6 AppIntents / Shortcuts**

Estimated duration: 3--4 days. KEY enabler for automatic wallpaper setting.

**9.1 How It Works**

33. Schedulock exposes AppIntent: "Generate Today's Wallpaper"

34. Intent generates wallpaper and returns the image as IntentFile

35. Shortcuts automation chains: Schedulock Intent → Set Wallpaper action

36. User sets up one-time automation (app guides them through it)

**9.2 GenerateWallpaperIntent**

> struct GenerateWallpaperIntent: AppIntent {
>
> static var title: LocalizedStringResource =
>
> \"Generate Today\'s Wallpaper\"
>
> \@Parameter(title: \"Template\")
>
> var templateName: String?
>
> func perform() async throws
>
> -\> some IntentResult & ReturnsValue\<IntentFile\> {
>
> let engine = WallpaperEngine()
>
> let image = try await engine.generateTodayWallpaper()
>
> let file = IntentFile(
>
> data: image.pngData()!,
>
> filename: \"wallpaper.png\", type: .png)
>
> return .result(value: file)
>
> }
>
> }

**9.3 Shortcuts Setup Guide (in-app)**

37. Open Shortcuts app → Automation → + → Time of Day

38. Set to 6:00 AM, Daily

39. Add action: "Generate Today's Wallpaper" (Schedulock)

40. Add action: "Set Wallpaper" → Lock Screen → input = previous

41. Toggle "Run Immediately" on

42. Done --- wallpaper updates automatically every morning

*Include annotated screenshots and a "Test Now" button in the guide.*

**9.4 Siri Integration**

-   "Hey Siri, generate my wallpaper"

-   Add SiriTipView in the app for discoverability

**10. Phase 7: Lock Screen Widget (WidgetKit)**

**PHASE 7 WidgetKit Lock Screen Widget**

Estimated duration: 3--4 days.

**10.1 Widget Families**

  --------------------------- -------------------------- --------------------------
  **Family**                  **Size**                   **Content**

  **.accessoryInline**        Single line, above clock   Next event: title + time

  **.accessoryCircular**      Small circle               Event count or next time

  **.accessoryRectangular**   Rectangle below clock      Next 2--3 events
  --------------------------- -------------------------- --------------------------

**10.2 Timeline Provider**

-   Refresh at midnight; one entry per event transition

-   Shows upcoming event, current event, or "No more events"

-   Uses .privacySensitive() for Always On Display

-   Uses .widgetAccentable() for tintable elements

**11. Phase 8: Settings, Onboarding & Polish**

**PHASE 8 Settings & Onboarding**

Estimated duration: 3--4 days.

**11.1 Settings**

**General**

-   Auto-generate schedule: time picker

-   Target device: auto-detect or manual override

-   Notification & save-to-Photos toggles

**Calendar**

-   Calendar selection, max events (1--8), show declined/all-day toggles

**Appearance**

-   Default template, clock format (24h/12h), date format

-   Randomize template daily: toggle

**Data & Privacy**

-   Clear history, clear cache, export settings, reset defaults

**11.2 Onboarding Flow (7 screens)**

43. **Welcome:** Hero image, tagline

44. **Calendar Permission:** Explain + grant button

45. **Choose Photo:** PHPicker inline, or skip for gradient

46. **Pick Calendars:** Toggle list, pre-select primary

47. **Choose Template:** Horizontal scroll with live previews

48. **Automation Setup:** Shortcuts guide (skippable)

49. **Done:** Generate first wallpaper, show result

**11.3 Haptics & Animations**

-   Light haptic on template selection, medium on generation complete

-   Spring animations on card transitions

-   Crossfade preview updates

**12. Phase 9: Testing & QA**

**PHASE 9 Testing & QA**

Estimated duration: 3--4 days.

**12.1 Unit Tests**

-   Renderer: verify non-nil UIImage at expected resolution

-   CalendarDataProvider: mock EKEventStore, test filtering

-   DesignSettings: Codable round-trip

-   AppGroupManager: file I/O

**12.2 Snapshot Tests (swift-snapshot-testing)**

-   One per template: 3 events, 0 events, 8 events (overflow)

-   All font families per template

-   RTL text (Hebrew/Arabic)

**12.3 Integration Tests**

-   Full pipeline: image → calendars → generate → verify

-   BG task simulation via Xcode Debug

-   AppIntent invocation

-   Widget timeline verification

**12.4 Edge Cases**

-   No calendars selected → wallpaper without events

-   Calendar permission revoked mid-use

-   No background image → gradient fallback

-   Very long titles (100+ chars) → truncation

-   RTL text → correct alignment

-   Midnight rollover, 100+ events, Low Power Mode

-   Fully offline: app must work with no internet

**13. Phase 10: App Store Submission**

**PHASE 10 App Store Submission**

Estimated duration: 2--3 days.

**13.1 Metadata**

-   Name: Schedulock

-   Subtitle: Daily wallpaper with your agenda

-   Category: Productivity (primary), Lifestyle (secondary)

**13.2 Screenshots**

-   6.7": 1290×2796, 6.5": 1284×2778, 5.5": 1242×2208

-   6 screenshots per size: each template, calendar picker, widget

**13.3 App Review Notes**

-   Calendar: read-only, display purposes, nothing leaves device

-   Shortcuts: uses official API, not private APIs

-   BGTask: legitimate daily wallpaper generation

**13.4 Privacy Declarations**

-   Data collected: None

-   Data linked to user: None

-   Data used to track: None

-   All processing is fully on-device

**14. UI/UX Design Specifications**

**14.1 Design Language**

-   Dark-first: primary BG #0A0B0F, secondary #0F1014

-   Accent gradient: #6C63FF → #E040FB

-   Corner radius: 12pt cards, 20pt glass, 32pt phone frame

-   8pt grid spacing system

**14.2 Color Palette**

  ----------------- ----------------- -----------------------------------
  **Token**         **Value**         **Usage**

  **background**    #0A0B0F           Main app background

  **surface**       #0F1014           Cards, sidebar, panels

  **primary**       #6C63FF           Actions, accents, active states

  **primaryGlow**   #E040FB           Gradient end, premium feel

  **textPrimary**   #E8E8ED           Primary body text

  **textMuted**     #555555           Hints, placeholders

  **danger**        #FF3B30           Destructive actions

  **success**       #30D158           Success, enabled toggles
  ----------------- ----------------- -----------------------------------

**15. Data Model Reference**

**15.1 Enumerations**

> enum TemplateType: String, Codable, CaseIterable {
>
> case minimal, glass, gradient, editorial, neon, split
>
> }
>
> enum FontFamily: String, Codable, CaseIterable {
>
> case sfPro, avenir, georgia, futura, menlo, didot
>
> var displayName: String { \... }
>
> var fontName: String { \... }
>
> }

**15.2 App Group Storage Layout**

> group.com.ronenmars.Schedulock/
>
> ├── Images/
>
> │ ├── background-original.jpg
>
> │ ├── background-cropped.jpg
>
> │ └── background-processed.jpg
>
> ├── Wallpapers/
>
> │ ├── current.png
>
> │ └── history/ (last 30 days)
>
> ├── Database/ (SwiftData store)
>
> └── UserDefaults (shared prefs)

**16. Risk Registry & Mitigations**

  -------- ---------------------------------- ---------------- -------------- -----------------------------------------------------------
  **\#**   **Risk**                           **Likelihood**   **Impact**     **Mitigation**

  1        BGTask not guaranteed daily        **High**         **High**       Shortcuts time trigger as primary; BG task as backup

  2        iOS changes Set Wallpaper action   **Low**          **Critical**   Monitor WWDC. Fallback: notification with manual set

  3        App Review rejection               **Medium**       **Medium**     Clear privacy docs, on-device only, detailed review notes

  4        Memory pressure during render      **Medium**       **Low**        Autorelease pools, tile-based rendering

  5        Calendar sync delay                **Medium**       **Low**        Schedule late enough for sync; manual regeneration

  6        User confusion: Shortcuts setup    **High**         **Medium**     In-app guided walkthrough with screenshots + FAQ
  -------- ---------------------------------- ---------------- -------------- -----------------------------------------------------------

**17. Timeline & Milestones**

  ----------- ----------------------------------------------- -------------- ---------------------------
  **Phase**   **Deliverable**                                 **Duration**   **Milestone**

  **1**       Xcode project, App Group, models, navigation    3--4 days      App launches & navigates

  **2**       EventKit, calendar picker, event formatting     2--3 days      Events displayed in app

  **3**       Core Graphics engine, image processing          5--7 days      First wallpaper generated

  **4**       6 templates, editor, live preview               5--6 days      All templates working

  **5**       BGTaskScheduler, overnight gen, notifications   2--3 days      Auto-generation works

  **6**       AppIntents, Shortcuts, Siri                     3--4 days      Wallpaper auto-sets

  **7**       WidgetKit lock screen widgets (3 families)      3--4 days      Widget on lock screen

  **8**       Settings, onboarding, haptics, animations       3--4 days      Complete UX

  **9**       Unit tests, snapshots, device testing           3--4 days      QA passed

  **10**      App Store metadata, screenshots, submission     2--3 days      Submitted
  ----------- ----------------------------------------------- -------------- ---------------------------

**Total estimated timeline: 6--8 weeks** for a single developer.

This plan covers the complete journey from empty Xcode project to App Store submission. Each phase builds on the previous one, and the shared Swift package ensures the rendering engine, data models, and calendar provider work identically across all targets.

---

**18. Claude Code Playbook: Agent Teams Strategy**

**Using Agent Teams (Experimental) for Parallel Development**

Agent Teams let you coordinate multiple Claude Code sessions working together. One session acts as the **team lead** (orchestrator), spawning **teammates** that work independently in their own context windows and communicate directly with each other via a shared task list and mailbox system.

This is fundamentally different from subagents: subagents report back to the caller only. Agent team teammates **message each other**, share findings, and self-coordinate — making them ideal for Schedulock's multi-target, multi-layer architecture.

**18.1 Prerequisites & Setup**

Enable the experimental feature (one-time):

```json
// ~/.config/claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or via shell:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Ensure you have a solid `CLAUDE.md` at the project root — all teammates inherit it automatically. This is where you put Schedulock-specific conventions: file structure, naming patterns, App Group constants, target membership rules, etc.

**18.2 When to Use Agent Teams vs Subagents vs Single Session**

| Scenario                                          | Approach         | Reason                                                        |
|---------------------------------------------------|------------------|---------------------------------------------------------------|
| Single-file edits, sequential logic               | **Single session** | No coordination overhead needed                               |
| Focused task that reports results (e.g. "lint X") | **Subagent**     | Fire-and-forget, no cross-communication needed                |
| Multi-target feature spanning Shared + App + Widget | **Agent Team** | Teammates own separate targets, coordinate interfaces directly |
| Rendering engine + template implementations       | **Agent Team**   | Protocol owner negotiates with template implementors           |
| QA pass across all 6 templates + edge cases       | **Agent Team**   | Parallel exploration finds issues a single agent misses        |
| Debugging competing hypotheses                    | **Agent Team**   | Teammates test different theories, converge on answer faster   |

**Rule of thumb:** If teammates need to coordinate interfaces or share findings with each other (not just report back), use Agent Teams.

**18.3 Recommended Team Structures by Phase**

**Phase 1–2: Foundation & Calendar (Single Session)**

Sequential setup work. No parallelism benefit — use a single Claude Code session.

**Phase 3–4: Rendering Engine + Templates (Agent Team — 4 teammates)**

This is the highest-value phase for Agent Teams. The rendering protocol, 6 template implementations, and image processing pipeline are independent tracks that need to agree on interfaces.

```
Prompt to Claude Code:

Create an agent team for building Schedulock's wallpaper rendering engine. Spawn 4 teammates:

1. **Engine Architect** — owns WallpaperRenderer protocol, WallpaperEngine class,
   DeviceResolution registry, and the rendering pipeline in Shared/Engine/.
   Defines the protocol contract FIRST, then messages other teammates with the interface.

2. **Template Builder A** — implements MinimalRenderer, GlassRenderer, and
   GradientBandRenderer. Waits for Engine Architect's protocol, then builds
   and tests each renderer independently.

3. **Template Builder B** — implements EditorialRenderer, NeonRenderer, and
   SplitViewRenderer. Same pattern: wait for protocol, build, test.

4. **Image Pipeline** — owns image processing: PHPicker → crop → blur → brightness →
   cache in App Group. Works in Shared/Engine/ on CalendarDataProvider and
   image utilities. Coordinates with Engine Architect on input types.

Use Sonnet for teammates. Coordinate through the shared task list.
File ownership: no two teammates edit the same file.
```

**Why this works:** The Engine Architect defines the protocol first, then Template Builders A and B can implement 3 renderers each in parallel — zero file conflicts. The Image Pipeline teammate works on orthogonal code.

**Phase 5–6: Background Scheduler + Shortcuts (Agent Team — 3 teammates)**

```
Create an agent team for Schedulock's background generation and Shortcuts integration:

1. **BG Task Owner** — implements BGTaskScheduler registration, scheduling strategy,
   execution flow, and failure handling in App/ target.

2. **Intent Owner** — implements GenerateWallpaperIntent, AppIntent extension,
   and Siri integration in IntentExtension/ target.

3. **Integration Tester** — writes integration tests that verify the full pipeline:
   BG task fires → engine generates → image saved to App Group → intent returns
   IntentFile. Reports issues to the other two teammates directly.
```

**Phase 7: WidgetKit (Single Session or Subagent)**

Widget extension is self-contained. Single session is sufficient. Can use a subagent from the main session to scaffold the 3 widget families while you continue other work.

**Phase 8: Settings & Onboarding (Agent Team — 3 teammates)**

```
Create an agent team for Schedulock's settings and onboarding:

1. **Settings UI** — builds SettingsView with all sections (General, Calendar,
   Appearance, Data & Privacy). Uses SwiftUI forms, binds to App Group UserDefaults.

2. **Onboarding Flow** — implements 7-screen onboarding with permission requests,
   PHPicker, calendar selection, and first wallpaper generation.

3. **Polish & Haptics** — adds haptic feedback, spring animations, crossfade
   transitions across the entire app. Reviews existing views for consistency.
```

**Phase 9: QA Swarm (Agent Team — 3+ teammates)**

QA is arguably the **best use case** for Agent Teams — parallel exploration catches more bugs than sequential testing.

```
Create an agent team to QA Schedulock:

1. **Unit Test Writer** — writes unit tests for WallpaperRenderer (non-nil UIImage
   at expected resolution), CalendarDataProvider (mock EKEventStore), DesignSettings
   (Codable round-trip), AppGroupManager (file I/O).

2. **Snapshot Tester** — sets up swift-snapshot-testing. Creates snapshots for all
   6 templates × 3 event counts (0, 3, 8) × all font families × RTL text.

3. **Edge Case Hunter** — tests: no calendars selected, permission revoked mid-use,
   no background image, 100+ char titles, midnight rollover, 100+ events,
   Low Power Mode, fully offline. Reports failures to other teammates.
```

**18.4 Key Patterns & Best Practices**

**Pattern 1: Protocol-First Coordination**

For Schedulock, the WallpaperRenderer protocol is the central contract. Have the Engine Architect teammate define and commit it first. Other teammates read the committed protocol file — no stale context.

**Pattern 2: File Ownership Boundaries**

Prevent edit collisions by assigning clear file ownership in your spawn prompt:

- Engine Architect → `Shared/Engine/WallpaperRenderer.swift`, `WallpaperEngine.swift`
- Template Builder A → `Shared/Engine/TemplateRenderers/Minimal*.swift`, `Glass*.swift`, `Gradient*.swift`
- Template Builder B → `Shared/Engine/TemplateRenderers/Editorial*.swift`, `Neon*.swift`, `Split*.swift`
- Image Pipeline → `Shared/Engine/CalendarDataProvider.swift`, `Shared/Utilities/`

**Pattern 3: Plan Cheap, Execute Expensive**

Agent teams multiply token usage. Use this 2-step approach:

1. **Plan mode** (single session, cheap): outline the exact tasks, file ownership, and interface contracts
2. **Team execution** (agent team, expensive but fast): hand the plan to the team for parallel implementation

This gives you a checkpoint before committing tokens.

**Pattern 4: Lead as Orchestrator, Not Implementor**

The lead sometimes starts implementing instead of delegating. If this happens, tell it:

> "Do not implement anything yourself. Wait for your teammates to complete their tasks. Your role is coordination and synthesis only."

Or use **delegate mode** (Shift+Tab) to restrict the lead to coordination-only tools.

**Pattern 5: Nudge Stuck Tasks**

Teammates sometimes fail to mark tasks as completed, blocking dependent work. If a task appears stuck, check whether the work is actually done and tell the lead to update the status or nudge the teammate.

**18.5 CLAUDE.md Additions for Agent Teams**

Add this section to your project's `CLAUDE.md` so all teammates inherit the context:

```markdown
## Schedulock Agent Team Conventions

### Targets & Ownership
- `App/` — Main app target (SwiftUI views, ViewModels)
- `Shared/` — Swift Package shared across ALL targets (models, engine, utilities)
- `WidgetExtension/` — WidgetKit lock screen widgets
- `IntentExtension/` — AppIntents for Shortcuts
- `Tests/` — All test targets

### Critical Constants
- App Group ID: `group.com.ronenmars.Schedulock`
- BG Task ID: `com.ronenmars.Schedulock.wallpaper-generation`
- Shared container paths: Images/, Wallpapers/, Database/

### File Conflict Rules
- NEVER have two teammates edit the same file
- Protocol definitions must be committed before implementations begin
- All new files must specify target membership explicitly

### Rendering Contract
- All template renderers conform to `WallpaperRenderer` protocol
- Renderers receive `CGContext`, `CGSize`, `UIImage?`, `[CalendarEvent]`, `DesignSettings`, `Date`
- Output: rendered content drawn into the provided CGContext (no return value)

### SwiftData Models
- All models live in `Shared/Models/`
- Changes to model schema must be communicated to ALL teammates
```

**18.6 Token Cost & Practical Advice**

Each teammate is a full Claude instance with its own context window. A 4-teammate team uses roughly 4–5× the tokens of a single session (including coordination overhead).

**Cost optimization strategy for Schedulock:**

| Phase     | Approach         | Estimated Token Multiplier |
|-----------|------------------|---------------------------|
| 1–2       | Single session   | 1×                        |
| 3–4       | 4-teammate team  | 4–5×                      |
| 5–6       | 3-teammate team  | 3–4×                      |
| 7         | Single session   | 1×                        |
| 8         | 3-teammate team  | 3–4×                      |
| 9 (QA)    | 3-teammate team  | 3–4×                      |
| 10        | Single session   | 1×                        |

Trade-off: Phases 3–4 would take a single agent 5–7 days. With a 4-teammate team, expect ~2–3 days wall-clock time at higher token cost. The rendering engine and 6 templates are ideal for parallelization because they're independent implementations behind a shared protocol.

**18.7 Known Limitations (Experimental)**

- **No session resumption**: `/resume` and `/rewind` don't restore in-process teammates. After resuming, the lead may try to message dead teammates — tell it to spawn new ones.
- **One team per session**: clean up the current team before starting a new one.
- **No nested teams**: teammates cannot spawn their own teams.
- **Shutdown can be slow**: teammates finish their current tool call before stopping.
- **Split pane mode** (tmux/iTerm2): lets you see all teammates' output simultaneously. Does NOT work in VS Code integrated terminal — use in-process mode there (Shift+Up/Down to navigate).

**18.8 Quick-Start: Your First Schedulock Agent Team**

After enabling the feature flag, start Claude Code in the Schedulock project root and paste:

```
I'm building Schedulock, an iOS lock screen wallpaper generator.
Read CLAUDE.md for full project context.

Create an agent team to build the wallpaper rendering engine (Phase 3-4).
Spawn teammates:
- Engine Architect: WallpaperRenderer protocol + WallpaperEngine + DeviceResolution
- Template Builder A: MinimalRenderer, GlassRenderer, GradientBandRenderer
- Template Builder B: EditorialRenderer, NeonRenderer, SplitViewRenderer
- Image Pipeline: image processing, CalendarDataProvider, App Group file I/O

Rules:
- Engine Architect defines and commits the protocol BEFORE builders start
- No two teammates edit the same file
- Use Sonnet for each teammate
- Coordinate through the shared task list
```

Claude will create the team, spawn the teammates, and begin coordinated execution. Monitor progress via the shared task list, or switch between teammate sessions with Shift+Up/Down.

---

**19. MCP Server Tooling**

Claude Code sessions for this project are equipped with 13 MCP (Model Context Protocol) servers that provide AI-native access to the iOS development toolchain, Apple documentation, and project management tools.

**Configuration**: [`.mcp.json`](.mcp.json) @.mcp.json
**Full documentation**: [`mcp-servers-and-plugins-front.md`](mcp-servers-and-plugins-front.md) @mcp-servers-and-plugins-front.md

**19.1 iOS-Specific Servers**

| Server | Purpose | Key Phases |
|--------|---------|------------|
| **XcodeBuildMCP** | Build, test, and deploy to simulators/devices from the agent | All phases |
| **Apple Docs** | Search Apple Developer Documentation, WWDC videos, framework APIs | 2 (EventKit), 3 (Core Graphics), 5 (BGTaskScheduler), 6 (AppIntents), 7 (WidgetKit) |
| **Mobile MCP** | iOS Simulator automation — screenshots, UI interaction, app lifecycle | 8 (onboarding), 9 (QA), 10 (App Store screenshots) |
| **SwiftLens** | Semantic Swift analysis via SourceKit-LSP — symbols, references, types | 3--4 (renderer protocol + templates), 9 (refactoring) |

**19.2 General-Purpose Servers**

| Server | Purpose |
|--------|---------|
| **Figma Desktop** | Design-to-code: read Figma layouts, components, and tokens |
| **task-master-ai** | Parse this plan into tasks, manage dependencies, track progress |
| **Serena** | Symbol-level code navigation and editing across the codebase |
| **GitHub** | Repository management, issues, PRs, code search |
| **Octocode** | Code forensics — deep search across GitHub repos and local codebase with LSP |
| **Playwright** | Browser automation for web-based testing |
| **ESLint** | JavaScript/TypeScript linting |
| **Chrome DevTools** | Browser debugging and performance profiling |
| **Context7** (plugin) | Up-to-date library documentation and code examples |

**19.3 Recommended MCP Usage by Phase**

- **Phase 1--2**: Use **task-master-ai** to parse this plan into structured tasks. Use **Apple Docs** to verify EventKit permission APIs for iOS 16.2+.
- **Phase 3--4**: Use **SwiftLens** to navigate the WallpaperRenderer protocol across all conforming types. Use **Apple Docs** for Core Graphics drawing APIs. Use **XcodeBuildMCP** to build and verify each template renderer compiles.
- **Phase 5--6**: Use **Apple Docs** to look up BGTaskScheduler scheduling rules and AppIntents return types. Use **XcodeBuildMCP** to test background task registration.
- **Phase 7**: Use **Apple Docs** for WidgetKit timeline provider patterns and `.accessoryInline`/`.accessoryCircular`/`.accessoryRectangular` family constraints.
- **Phase 8**: Use **Figma Desktop** to translate onboarding screen designs into SwiftUI. Use **Mobile MCP** to test the 7-screen onboarding flow on simulator.
- **Phase 9**: Use **XcodeBuildMCP** to run the full test suite. Use **Mobile MCP** to visually verify all 6 templates across device resolutions. Use **SwiftLens** to find untested symbol references.
- **Phase 10**: Use **Mobile MCP** to capture App Store screenshots at required resolutions (6.7", 6.5", 5.5"). Use **GitHub** to manage the release branch and PR.

---

*End of Document*
