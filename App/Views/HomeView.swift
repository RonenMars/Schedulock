import SwiftUI
import PhotosUI
import SwiftData
import Shared

struct HomeView: View {
    @State private var currentWallpaper: UIImage?
    @State private var isGlowing = false
    @State private var viewModel = WallpaperViewModel()
    @State private var calendarProvider = CalendarDataProvider()
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var showShareSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingBackgroundImage = false
    @Environment(\.modelContext) private var modelContext

    @AppStorage("defaultTemplateType", store: AppGroupManager.userDefaults)
    private var defaultTemplateTypeRawValue: String = TemplateType.minimal.rawValue

    @AppStorage("targetDevice", store: AppGroupManager.userDefaults)
    private var targetDeviceName: String = DeviceResolution.iPhone16Pro.name

    @AppStorage("maxEvents", store: AppGroupManager.userDefaults)
    private var maxEvents: Int = 6

    @AppStorage("showDeclined", store: AppGroupManager.userDefaults)
    private var showDeclined: Bool = false

    @AppStorage("saveToPhotos", store: AppGroupManager.userDefaults)
    private var saveToPhotos: Bool = false

    @Query private var allSavedSettings: [SavedTemplateSettings]

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
                    .overlay {
                        if isGenerating {
                            RoundedRectangle(cornerRadius: DesignTokens.phoneFrameRadius)
                                .fill(.black.opacity(0.4))
                                .aspectRatio(9/19.5, contentMode: .fit)
                                .overlay {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacingXL)

                    // Background photo picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: DesignTokens.spacingXS) {
                            if isLoadingBackgroundImage {
                                ProgressView()
                                    .tint(DesignTokens.textMuted)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "photo.on.rectangle")
                            }
                            Text(isLoadingBackgroundImage ? "Loading..." : "Change Background Photo")
                        }
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textMuted)
                    }
                    .disabled(isLoadingBackgroundImage)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            isLoadingBackgroundImage = true
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                saveBackgroundImage(image)
                            }
                            isLoadingBackgroundImage = false
                        }
                    }

                    if let generationError {
                        Text(generationError)
                            .font(.caption)
                            .foregroundStyle(DesignTokens.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.spacingLG)
                    }

                    // Generate button with pulsing glow
                    Button {
                        mediumHaptic()
                        generateWallpaper()
                    } label: {
                        Group {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Generate Wallpaper")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                        .shadow(
                            color: DesignTokens.primary.opacity(isGlowing ? 0.6 : 0.3),
                            radius: isGlowing ? 20 : 10
                        )
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal, DesignTokens.spacingXL)
                    .padding(.bottom, DesignTokens.spacingXL)
                }
            }
            .navigationTitle("")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if currentWallpaper != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(DesignTokens.textPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let wallpaper = currentWallpaper {
                    ShareSheet(items: [wallpaper])
                }
            }
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

    private func saveBackgroundImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        AppGroupManager.ensureDirectoriesExist()
        let imageURL = AppGroupManager.imagesDirectory.appendingPathComponent("selected_background.jpg")
        try? imageData.write(to: imageURL)
        AppGroupManager.userDefaults.set(imageURL.path, forKey: "selectedBackgroundImagePath")
    }

    private func generateWallpaper() {
        Task {
            isGenerating = true
            generationError = nil
            defer { isGenerating = false }

            // Yield to let SwiftUI render the loading state before blocking the main thread
            await Task.yield()

            // 1. Fetch calendar events if access is granted, otherwise use samples
            let enabledIDs = AppGroupManager.userDefaults.stringArray(forKey: "enabledCalendarIDs") ?? []
            let events: [CalendarEvent]
            if CalendarDataProvider.authorizationStatus == .fullAccess {
                events = calendarProvider.fetchTodayEvents(
                    from: enabledIDs,
                    excludeDeclined: !showDeclined,
                    maxEvents: maxEvents
                )
            } else {
                events = WallpaperViewModel.sampleEvents
            }

            // 2. Load background image from saved path
            if let imagePath = AppGroupManager.userDefaults.string(forKey: "selectedBackgroundImagePath"),
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)),
               let bgImage = UIImage(data: imageData) {
                viewModel.backgroundImage = bgImage
            } else {
                viewModel.backgroundImage = nil
            }

            // 3. Configure template and device resolution from settings
            viewModel.selectedTemplateType = TemplateType(rawValue: defaultTemplateTypeRawValue) ?? .minimal
            let savedSettings = allSavedSettings.first { $0.templateTypeRaw == defaultTemplateTypeRawValue }
            viewModel.designSettings = savedSettings?.asDesignSettings ?? .default
            let resolution = DeviceResolution.all.first { $0.name == targetDeviceName } ?? .iPhone16Pro

            // 4. Generate full-resolution wallpaper
            guard let wallpaper = viewModel.generateFullResolution(events: events, resolution: resolution) else {
                generationError = "Failed to generate wallpaper"
                return
            }

            // 5. Save to app group disk (shared with widget)
            let wallpaperURL = AppGroupManager.wallpaperDirectory.appending(path: "current.png")
            if let pngData = wallpaper.pngData() {
                try? pngData.write(to: wallpaperURL)
            }

            // 6. Save to the user's photo library so they can set it as their wallpaper
            if saveToPhotos {
                UIImageWriteToSavedPhotosAlbum(wallpaper, nil, nil, nil)
            }

            // 7. Record to history
            let historyEntry = GenerationHistory(
                templateType: viewModel.selectedTemplateType.rawValue,
                imagePath: wallpaperURL.path,
                eventCount: events.count
            )
            modelContext.insert(historyEntry)
            try? modelContext.save()

            // 8. Update preview
            currentWallpaper = wallpaper
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
