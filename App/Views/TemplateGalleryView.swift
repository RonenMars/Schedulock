import SwiftUI
import Shared

struct TemplateGalleryView: View {
    @State private var viewModel = WallpaperViewModel()
    @State private var selectedTemplate: TemplateType?

    var body: some View {
        NavigationStack {
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
                                    settings: .default
                                ),
                                isSelected: selectedTemplate == template
                            )
                            .onTapGesture {
                                lightHaptic()
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding(DesignTokens.spacingMD)
                }
            }
            .navigationTitle("Templates")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedTemplate) { template in
                TemplateEditorView(
                    templateType: template,
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Helpers

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

            Text(template.displayName)
                .font(.caption.bold())
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
