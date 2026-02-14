import SwiftUI
import Shared

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                VStack(spacing: DesignTokens.spacingLG) {
                    // Wallpaper preview placeholder
                    RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius)
                        .fill(DesignTokens.surface)
                        .aspectRatio(9/19.5, contentMode: .fit)
                        .overlay {
                            VStack(spacing: DesignTokens.spacingSM) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(DesignTokens.textMuted)
                                Text("Your wallpaper preview")
                                    .font(.subheadline)
                                    .foregroundStyle(DesignTokens.textMuted)
                            }
                        }
                        .padding(.horizontal, DesignTokens.spacingXL)

                    // Generate button
                    Button {
                        // Will trigger wallpaper generation
                    } label: {
                        Text("Generate Wallpaper")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                    }
                    .padding(.horizontal, DesignTokens.spacingLG)
                }
            }
            .navigationTitle("Schedulock")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
