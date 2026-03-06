import SwiftUI
import SwiftData
import Shared

struct TemplateGalleryView: View {
    @Binding var selectedTab: Int
    @State private var viewModel = WallpaperViewModel()
    @State private var navPath: [TemplateType] = []
    @Query private var allSavedSettings: [SavedTemplateSettings]

    @AppStorage("defaultTemplateType", store: AppGroupManager.userDefaults)
    private var defaultTemplateTypeRawValue: String = TemplateType.minimal.rawValue

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: DesignTokens.spacingSM),
                            GridItem(.flexible(), spacing: DesignTokens.spacingSM)
                        ],
                        spacing: DesignTokens.spacingMD
                    ) {
                        ForEach(TemplateType.allCases, id: \.self) { template in
                            TemplateCard(
                                template: template,
                                preview: viewModel.generatePreview(
                                    templateType: template,
                                    settings: savedDesignSettings(for: template)
                                ),
                                isSelected: template.rawValue == defaultTemplateTypeRawValue
                            )
                            .onTapGesture {
                                lightHaptic()
                                navPath.append(template)
                            }
                        }
                    }
                    .padding(DesignTokens.spacingMD)
                }
            }
            .navigationTitle("Templates")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { loadSavedBackgroundImage() }
            .navigationDestination(for: TemplateType.self) { template in
                TemplateEditorView(templateType: template, viewModel: viewModel, selectedTab: $selectedTab)
            }
        }
    }

    // MARK: - Helpers

    private func savedDesignSettings(for type: TemplateType) -> DesignSettings {
        allSavedSettings.first { $0.templateTypeRaw == type.rawValue }?.asDesignSettings ?? .default
    }

    private func loadSavedBackgroundImage() {
        if let imagePath = AppGroupManager.userDefaults.string(forKey: "selectedBackgroundImagePath"),
           let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)),
           let bgImage = UIImage(data: imageData) {
            viewModel.backgroundImage = bgImage
        }
    }

    private func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct TemplateCard: View {
    let template: TemplateType
    let preview: UIImage?
    let isSelected: Bool
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: DesignTokens.spacingSM) {
            Group {
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .aspectRatio(9/19.5, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                } else {
                    RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                        .fill(DesignTokens.surface)
                        .aspectRatio(9/19.5, contentMode: .fit)
                        .overlay {
                            ProgressView()
                                .tint(DesignTokens.primary)
                        }
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, DesignTokens.primary)
                        .font(.system(size: 22))
                        .padding(8)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                        .stroke(DesignTokens.primary, lineWidth: 2)
                }
            }

            Text(template.displayName)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? DesignTokens.primary : DesignTokens.textPrimary)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
