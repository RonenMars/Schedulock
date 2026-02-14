import SwiftUI
import Shared

struct HomeView: View {
    @State private var currentWallpaper: UIImage?
    @State private var isGlowing = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()

                VStack(spacing: DesignTokens.spacingLG) {
                    // Wallpaper preview
                    Group {
                        if let currentWallpaper {
                            Image(uiImage: currentWallpaper)
                                .resizable()
                                .aspectRatio(9/19.5, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius))
                        } else {
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
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingXL)

                    // Generate button with pulsing glow
                    Button {
                        mediumHaptic()
                        // Will trigger wallpaper generation
                    } label: {
                        Text("Generate Wallpaper")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                            .shadow(
                                color: DesignTokens.primary.opacity(isGlowing ? 0.6 : 0.3),
                                radius: isGlowing ? 20 : 10
                            )
                    }
                    .padding(.horizontal, DesignTokens.spacingLG)
                }
            }
            .navigationTitle("Schedulock")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadCurrentWallpaper()
                startGlowAnimation()
            }
        }
    }

    // MARK: - Helpers

    private func loadCurrentWallpaper() {
        let wallpaperURL = AppGroupManager.wallpaperDirectory.appending(path: "current.png")
        if let imageData = try? Data(contentsOf: wallpaperURL),
           let image = UIImage(data: imageData) {
            currentWallpaper = image
        }
    }

    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isGlowing = true
        }
    }

    private func mediumHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
