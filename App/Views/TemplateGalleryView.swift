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
                                )
                            )
                            .onTapGesture {
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
}

private struct TemplateCard: View {
    let template: TemplateType
    let preview: UIImage?

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
    }
}
