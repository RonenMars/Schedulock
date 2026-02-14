import SwiftUI
import Shared

struct TemplateGalleryView: View {
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
                        spacing: DesignTokens.spacingSM
                    ) {
                        ForEach(TemplateType.allCases, id: \.self) { template in
                            TemplateCard(template: template)
                        }
                    }
                    .padding(DesignTokens.spacingMD)
                }
            }
            .navigationTitle("Templates")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct TemplateCard: View {
    let template: TemplateType

    var body: some View {
        VStack(spacing: DesignTokens.spacingSM) {
            RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                .fill(DesignTokens.surface)
                .aspectRatio(9/19.5, contentMode: .fit)
                .overlay {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(DesignTokens.primary)
                }

            Text(template.displayName)
                .font(.caption)
                .foregroundStyle(DesignTokens.textPrimary)
        }
    }
}
