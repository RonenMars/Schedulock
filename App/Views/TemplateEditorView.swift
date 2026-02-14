import SwiftUI
import Shared

struct TemplateEditorView: View {
    let templateType: TemplateType
    @Bindable var viewModel: WallpaperViewModel
    @State private var settings: DesignSettings = .default
    @State private var preview: UIImage?

    var body: some View {
        ZStack {
            DesignTokens.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacingMD) {
                    // Live preview
                    previewSection

                    // Editor sections
                    typographySection
                    colorsSection
                    effectsSection
                    layoutSection
                }
                .padding(DesignTokens.spacingMD)
            }
        }
        .navigationTitle(templateType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { refreshPreview() }
        .onChange(of: settings) { _, _ in refreshPreview() }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: DesignTokens.spacingSM) {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(9/19.5, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius))
                    .shadow(color: DesignTokens.primary.opacity(0.2), radius: 20)
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius)
                    .fill(DesignTokens.surface)
                    .aspectRatio(9/19.5, contentMode: .fit)
                    .overlay { ProgressView().tint(DesignTokens.primary) }
            }
        }
        .padding(.horizontal, DesignTokens.spacingXL)
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

                HStack {
                    Text("Alignment")
                        .foregroundStyle(DesignTokens.textMuted)
                    Spacer()
                    Picker("Alignment", selection: $settings.textAlignment) {
                        Text("Left").tag(Shared.TextAlignment.left)
                        Text("Center").tag(Shared.TextAlignment.center)
                        Text("Right").tag(Shared.TextAlignment.right)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                SliderRow(
                    title: "Text Shadow",
                    value: $settings.textShadow,
                    range: 0...10
                )
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
                ColorRow(title: "Secondary Color", hex: $settings.secondaryColor)
                ColorRow(title: "Card Background", hex: $settings.cardBackground)
            }
        }
    }

    // MARK: - Effects

    private var effectsSection: some View {
        EditorSection(title: "Effects") {
            VStack(spacing: DesignTokens.spacingSM) {
                SliderRow(title: "Overlay Opacity", value: $settings.overlayOpacity, range: 0...1)
                SliderRow(title: "Glass Blur", value: $settings.glassBlur, range: 0...50)
                SliderRow(title: "Background Blur", value: $settings.backgroundBlur, range: 0...30)
                SliderRow(title: "Brightness", value: $settings.brightness, range: -0.5...0.5)
            }
        }
    }

    // MARK: - Layout

    private var layoutSection: some View {
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

    // MARK: - Helpers

    private func refreshPreview() {
        preview = viewModel.generatePreview(
            templateType: templateType,
            settings: settings
        )
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
        }
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
