import SwiftUI
import SwiftData
import Shared

struct TemplateEditorView: View {
    let templateType: TemplateType
    @Bindable var viewModel: WallpaperViewModel
    @State private var settings: DesignSettings = .default
    @State private var showFinalPreview = false
    @State private var isApproving = false
    @State private var calendarProvider = CalendarDataProvider()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var savedRecord: SavedTemplateSettings?

    @AppStorage("defaultTemplateType", store: AppGroupManager.userDefaults)
    private var defaultTemplateTypeRawValue: String = TemplateType.minimal.rawValue

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DesignTokens.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacingMD) {
                    typographySection
                    colorsSection
                    effectsSection
                    layoutSection
                }
                .padding(DesignTokens.spacingMD)
                .padding(.bottom, 72)
            }

            // Sticky eye button — bottom-right corner
            Button {
                showFinalPreview = true
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(DesignTokens.accentGradient)
                    .clipShape(Circle())
                    .shadow(color: DesignTokens.primary.opacity(0.4), radius: 10, y: 3)
            }
            .padding(.trailing, DesignTokens.spacingMD)
            .padding(.bottom, 24)
        }
        .onAppear { loadSavedSettings() }
        .navigationTitle(templateType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Apply to All") {
                    applySettingsToAllTemplates()
                }
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textMuted)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFinalPreview = true
                } label: {
                    if defaultTemplateTypeRawValue == templateType.rawValue {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignTokens.primary)
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundStyle(DesignTokens.primary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFinalPreview) {
            finalPreviewCover
        }
    }

    // MARK: - Final Preview Cover

    @ViewBuilder
    private var finalPreviewCover: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(templateType.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { showFinalPreview = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8), .white.opacity(0.2))
                    }
                }
                .padding()

                GeometryReader { geo in
                    let hPad = DesignTokens.spacingXL
                    let bottomPad: CGFloat = 70
                    let buttonH: CGFloat = 41
                    let gap = DesignTokens.spacingMD
                    let imageH = geo.size.height - buttonH - gap - bottomPad
                    let imageW = min(geo.size.width - hPad * 2, imageH * 9.0 / 19.5)
                    let halfW = (imageW - DesignTokens.spacingSM) / 2

                    VStack(spacing: gap) {
                        Group {
                            if let preview = viewModel.generatePreview(templateType: templateType, settings: settings) {
                                Image(uiImage: preview)
                                    .resizable()
                                    .aspectRatio(9/19.5, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius))
                                    .shadow(color: .white.opacity(0.15), radius: 30)
                            } else {
                                RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius)
                                    .fill(DesignTokens.surface)
                                    .aspectRatio(9/19.5, contentMode: .fit)
                                    .overlay { ProgressView().tint(DesignTokens.primary) }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        HStack(spacing: DesignTokens.spacingSM) {
                            // Back
                            Button {
                                showFinalPreview = false
                            } label: {
                                Text("Back")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: halfW)
                                    .padding(.vertical, 12)
                                    .background(.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                            }
                            .disabled(isApproving)

                            // Save
                            Button {
                                Task {
                                    isApproving = true
                                    await Task.yield()
                                    approveTemplate()
                                    isApproving = false
                                    showFinalPreview = false
                                    dismiss()
                                }
                            } label: {
                                Group {
                                    if isApproving {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Save")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: halfW)
                                .padding(.vertical, 12)
                                .background(DesignTokens.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                            }
                            .disabled(isApproving)
                        }
                        .padding(.bottom, bottomPad)
                    }
                    .padding(.horizontal, hPad)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        EditorSection(title: "Typography") {
            VStack(spacing: DesignTokens.spacingSM) {
                HStack {
                    Text("Font")
                        .foregroundStyle(DesignTokens.textMuted)
                    Spacer()
                    Picker("Font", selection: $settings.fontFamily) {
                        ForEach(FontFamily.allCases, id: \.self) { font in
                            Text(font.displayName).tag(font)
                        }
                    }
                    .tint(DesignTokens.primary)
                }

                if [TemplateType.minimal, .gradient, .editorial, .split].contains(templateType) {
                    SliderRow(
                        title: "Text Shadow",
                        value: $settings.textShadow,
                        range: 0...10
                    )
                }
            }
        }
    }

    // MARK: - Colors

    private var colorsSection: some View {
        EditorSection(title: "Colors") {
            VStack(spacing: DesignTokens.spacingSM) {
                Toggle("Use Calendar Colors", isOn: $settings.useCalendarColors)
                    .tint(DesignTokens.primary)
                    .foregroundStyle(DesignTokens.textPrimary)

                ColorRow(title: "Text Color", hex: $settings.textColor)
                ColorRow(title: "Accent Color", hex: $settings.accentColor)

                if templateType == .gradient {
                    ColorRow(title: "Secondary Color", hex: $settings.secondaryColor)
                }

                if templateType != .editorial {
                    ColorRow(title: "Card Background", hex: $settings.cardBackground)
                }
            }
        }
    }

    // MARK: - Effects

    @ViewBuilder
    private var effectsSection: some View {
        if [TemplateType.minimal, .glass, .neon].contains(templateType) {
            EditorSection(title: "Effects") {
                VStack(spacing: DesignTokens.spacingSM) {
                    SliderRow(title: "Overlay Opacity", value: $settings.overlayOpacity, range: 0...1)
                }
            }
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private var layoutSection: some View {
        if templateType == .split {
            EditorSection(title: "Layout") {
                VStack(spacing: DesignTokens.spacingSM) {
                    SliderRow(
                        title: "Split Ratio",
                        value: $settings.splitRatio,
                        range: 0.3...0.8,
                        format: "%.0f%%",
                        multiplier: 100
                    )
                }
            }
        }
    }

    // MARK: - Helpers

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

    private func applySettingsToAllTemplates() {
        let all = (try? modelContext.fetch(FetchDescriptor<SavedTemplateSettings>())) ?? []
        for record in all {
            record.apply(settings)
        }
        try? modelContext.save()
    }

    private func approveTemplate() {
        savedRecord?.apply(settings)
        try? modelContext.save()
        defaultTemplateTypeRawValue = templateType.rawValue
        viewModel.selectedTemplateType = templateType
        viewModel.designSettings = settings

        let enabledIDs = AppGroupManager.userDefaults.stringArray(forKey: "enabledCalendarIDs") ?? []
        let events: [CalendarEvent]
        if CalendarDataProvider.authorizationStatus == .fullAccess {
            events = calendarProvider.fetchTodayEvents(from: enabledIDs, excludeDeclined: true, maxEvents: 6)
        } else {
            events = WallpaperViewModel.sampleEvents
        }

        AppGroupManager.ensureDirectoriesExist()
        guard let wallpaper = viewModel.generateFullResolution(events: events, resolution: .iPhone16Pro) else { return }
        let wallpaperURL = AppGroupManager.wallpaperDirectory.appending(path: "current.png")
        try? wallpaper.pngData()?.write(to: wallpaperURL)
    }
}

// MARK: - Reusable Editor Components

private struct EditorSection<Content: View>: View {
    let title: String
    @State private var isExpanded = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DesignTokens.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(DesignTokens.spacingMD)
            }

            if isExpanded {
                content
                    .padding(.horizontal, DesignTokens.spacingMD)
                    .padding(.bottom, DesignTokens.spacingMD)
            }
        }
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.1f"
    var multiplier: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(DesignTokens.textMuted)
                Spacer()
                Text(String(format: format, value * multiplier))
                    .font(.caption)
                    .foregroundStyle(DesignTokens.textMuted)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range)
                .tint(DesignTokens.primary)
                .onChange(of: value) { _, _ in
                    lightHaptic()
                }
        }
    }

    private func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct ColorRow: View {
    let title: String
    @Binding var hex: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(DesignTokens.textMuted)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(UIColor(cgColor: ColorUtils.color(from: hex).cgColor)))
                .frame(width: 24, height: 24)
            Text(hex)
                .font(.caption.monospaced())
                .foregroundStyle(DesignTokens.textMuted)
        }
    }
}
