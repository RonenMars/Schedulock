import SwiftUI
import AppIntents
import Shared

struct ShortcutsGuideView: View {
    @State private var showTestResult = false
    @State private var testSuccess = false
    @State private var testError: String?
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                stepsSection
                testSection
                siriTipSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(DesignTokens.background)
        .navigationTitle("Shortcuts Setup")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automate Daily Wallpapers")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(DesignTokens.textPrimary)

            Text("Set up a Shortcuts automation to generate your wallpaper every morning at 6 AM — or whenever you like.")
                .font(.system(size: 16))
                .foregroundColor(DesignTokens.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepCard(
                number: "1",
                title: "Open Shortcuts App",
                description: "Tap the 'Automation' tab at the bottom, then tap the '+' button in the top right.",
                icon: "plus.circle"
            )

            stepCard(
                number: "2",
                title: "Create Time of Day Automation",
                description: "Select 'Time of Day' trigger. Set time to 6:00 AM (or your preference) and choose 'Daily'.",
                icon: "clock"
            )

            stepCard(
                number: "3",
                title: "Add Schedulock Action",
                description: "Tap 'Add Action' and search for 'Generate Today's Wallpaper'. Select it from Schedulock.",
                icon: "sparkles"
            )

            stepCard(
                number: "4",
                title: "Set Wallpaper Automatically",
                description: "Tap '+' to add another action. Search for 'Set Wallpaper', then tap 'Lock Screen' and select the output from the previous action.",
                icon: "photo"
            )

            stepCard(
                number: "5",
                title: "Enable Run Immediately",
                description: "Toggle OFF 'Ask Before Running' and toggle ON 'Notify When Run'. This lets the automation run silently.",
                icon: "bell.badge"
            )

            stepCard(
                number: "6",
                title: "Done!",
                description: "Tap 'Done' in the top right. Your wallpaper will now update automatically every morning.",
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func stepCard(number: String, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(DesignTokens.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(number)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(DesignTokens.primary)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                }

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(DesignTokens.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(DesignTokens.surface)
        .cornerRadius(DesignTokens.cardRadius)
    }

    // MARK: - Test Section

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test It Now")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)

            Text("Verify your Shortcuts integration is working by generating a wallpaper right now.")
                .font(.system(size: 15))
                .foregroundColor(DesignTokens.textMuted)

            Button {
                testShortcutIntegration()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(isGenerating ? "Generating..." : "Test Intent Now")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isGenerating ? DesignTokens.primary.opacity(0.6) : DesignTokens.primary)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.cardRadius)
            }
            .disabled(isGenerating)

            if showTestResult {
                HStack(spacing: 12) {
                    Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(testSuccess ? DesignTokens.success : DesignTokens.danger)

                    Text(testSuccess ? "Wallpaper generated successfully!" : "Error: \(testError ?? "Unknown error")")
                        .font(.system(size: 14))
                        .foregroundColor(testSuccess ? DesignTokens.success : DesignTokens.danger)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((testSuccess ? DesignTokens.success : DesignTokens.danger).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.top, 8)
    }

    private func testShortcutIntegration() {
        isGenerating = true
        showTestResult = false

        Task {
            do {
                let intent = GenerateWallpaperIntent()
                _ = try await intent.perform()
                await MainActor.run {
                    testSuccess = true
                    testError = nil
                    showTestResult = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    testSuccess = false
                    testError = error.localizedDescription
                    showTestResult = true
                    isGenerating = false
                }
            }
        }
    }

    // MARK: - Siri Tip

    private var siriTipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(DesignTokens.primary)
                Text("Hey Siri")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
            }

            Text("You can also trigger wallpaper generation with your voice:")
                .font(.system(size: 15))
                .foregroundColor(DesignTokens.textMuted)

            VStack(alignment: .leading, spacing: 8) {
                siriPhrase("Hey Siri, generate my wallpaper")
                siriPhrase("Hey Siri, generate today's wallpaper")
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func siriPhrase(_ phrase: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 12))
                .foregroundColor(DesignTokens.textMuted)
            Text(phrase)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
                .italic()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.surface)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ShortcutsGuideView()
    }
}
