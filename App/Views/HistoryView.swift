import SwiftUI
import SwiftData
import Shared

struct HistoryView: View {
    @Query(sort: \GenerationHistory.generatedAt, order: .reverse)
    private var history: [GenerationHistory]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                if history.isEmpty {
                    VStack(spacing: DesignTokens.spacingSM) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(DesignTokens.textMuted)
                        Text("No wallpapers generated yet")
                            .foregroundStyle(DesignTokens.textMuted)
                        Text("Generate your first wallpaper from the Home tab")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                } else {
                    List(history) { entry in
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignTokens.surface)
                                .frame(width: 50, height: 50)
                            VStack(alignment: .leading) {
                                Text(entry.templateType.capitalized)
                                    .foregroundStyle(DesignTokens.textPrimary)
                                Text("\(entry.eventCount) events")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.textMuted)
                            }
                            Spacer()
                            Text(entry.generatedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(DesignTokens.textMuted)
                        }
                        .listRowBackground(DesignTokens.surface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
