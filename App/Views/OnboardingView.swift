import SwiftUI
import PhotosUI
import EventKit
import Shared

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var calendarProvider = CalendarDataProvider()
    @State private var availableCalendars: [EKCalendar] = []
    @State private var enabledCalendarIDs: Set<String> = []
    @State private var selectedTemplateType: TemplateType = .minimal
    @State private var calendarAccessGranted = false
    @State private var viewModel = WallpaperViewModel()
    @State private var isGeneratingInitialWallpaper = false
    @State private var isLoadingImage = false
    @State private var selectedCalendarSource: CalendarSourceType = .apple
    @State private var googleCalendarVM = GoogleCalendarViewModel()
    @State private var isSigningInWithGoogle = false
    @State private var maxAllowedPage = 0

    let onComplete: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            welcomeScreen.tag(0)
            calendarSourceScreen.tag(1)
            calendarPermissionScreen.tag(2)
            photoPickerScreen.tag(3)
            calendarSelectionScreen.tag(4)
            templatePickerScreen.tag(5)
            automationScreen.tag(6)
            doneScreen.tag(7)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(DesignTokens.background.ignoresSafeArea())
        .onChange(of: currentPage) { _, newPage in
            // Allow backward swipes, prevent forward swipes past completed steps
            if newPage > maxAllowedPage {
                currentPage = maxAllowedPage
                return
            }
            // Auto-skip calendar permission if already granted (Apple path)
            if newPage == 2 && calendarAccessGranted {
                advanceTo(3)
            }
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundStyle(DesignTokens.accentGradient)
                .padding(.bottom, DesignTokens.spacingLG)

            Text("Schedulock")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(DesignTokens.textPrimary)

            Text("Your agenda, your lock screen")
                .font(.system(size: 18))
                .foregroundColor(DesignTokens.textMuted)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                advanceTo(1)
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .cornerRadius(DesignTokens.cardRadius)
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
    }

    // MARK: - Screen 2: Calendar Source

    private var calendarSourceScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.accentGradient)
                .padding(.bottom, DesignTokens.spacingLG)

            VStack(spacing: DesignTokens.spacingMD) {
                Text("Choose Calendar")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Select which calendar to display on your wallpaper")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: DesignTokens.spacingMD) {
                // Apple Calendar button
                Button {
                    selectedCalendarSource = .apple
                    AppGroupManager.userDefaults.set(CalendarSourceType.apple.rawValue, forKey: "calendarSource")
                    advanceTo(2)
                } label: {
                    HStack(spacing: DesignTokens.spacingSM) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Apple Calendar")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .cornerRadius(DesignTokens.cardRadius)
                }

                // Google Calendar button
                Button {
                    isSigningInWithGoogle = true
                    Task {
                        await googleCalendarVM.signIn()
                        isSigningInWithGoogle = false
                        if googleCalendarVM.isSignedIn {
                            selectedCalendarSource = .google
                            AppGroupManager.userDefaults.set(CalendarSourceType.google.rawValue, forKey: "calendarSource")
                            advanceTo(3)
                        }
                    }
                } label: {
                    Group {
                        if isSigningInWithGoogle {
                            ProgressView().tint(.white)
                        } else {
                            HStack(spacing: DesignTokens.spacingSM) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                Text("Google Calendar")
                                    .font(.headline)
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.20, green: 0.40, blue: 0.80)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.cardRadius)
                }
                .disabled(isSigningInWithGoogle)

                if let error = googleCalendarVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
    }

    // MARK: - Screen 3: Calendar Permission

    private var calendarPermissionScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.accentGradient)
                .padding(.bottom, DesignTokens.spacingLG)

            VStack(spacing: DesignTokens.spacingMD) {
                Text("Calendar Access")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Schedulock reads your calendar to show today's agenda")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: DesignTokens.spacingSM) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(DesignTokens.success)
                    Text("No data leaves your device")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.success)
                }
                .padding(.top, DesignTokens.spacingSM)
            }

            Spacer()

            VStack(spacing: DesignTokens.spacingMD) {
                Button {
                    Task {
                        do {
                            calendarAccessGranted = try await calendarProvider.requestAccess()
                            if calendarAccessGranted {
                                availableCalendars = calendarProvider.fetchCalendars()
                                enabledCalendarIDs = Set(availableCalendars.map { $0.calendarIdentifier })
                            }
                            advanceTo(3)
                        } catch {
                            print("Calendar access error: \(error)")
                        }
                    }
                } label: {
                    Text("Grant Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.accentGradient)
                        .cornerRadius(DesignTokens.cardRadius)
                }

                Button {
                    advanceTo(3)
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textMuted)
                }
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
        .onAppear {
            if CalendarDataProvider.authorizationStatus == .fullAccess {
                availableCalendars = calendarProvider.fetchCalendars()
                enabledCalendarIDs = Set(availableCalendars.map { $0.calendarIdentifier })
                calendarAccessGranted = true
            }
        }
    }

    // MARK: - Screen 4: Choose Photo

    private var photoPickerScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.accentGradient)
                .padding(.bottom, DesignTokens.spacingLG)

            VStack(spacing: DesignTokens.spacingMD) {
                Text("Choose Background")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Pick a photo for your wallpaper background")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if isLoadingImage {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                    .fill(DesignTokens.surface)
                    .frame(width: 200, height: 200)
                    .overlay {
                        ProgressView().tint(DesignTokens.primary)
                    }
            } else if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                            .stroke(DesignTokens.primary, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                    .fill(DesignTokens.surface)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(DesignTokens.textMuted)
                    )
            }

            Spacer()

            VStack(spacing: DesignTokens.spacingMD) {
                if selectedImage != nil {
                    // Image selected: Continue as primary, Change Image as secondary
                    Button {
                        advanceTo(4)
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.accentGradient)
                            .cornerRadius(DesignTokens.cardRadius)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Change Image")
                        }
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textMuted)
                    }
                } else {
                    // No image: Select Photo as primary, Skip as secondary
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Select Photo")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.accentGradient)
                        .cornerRadius(DesignTokens.cardRadius)
                    }

                    Button {
                        advanceTo(4)
                    } label: {
                        Text("Skip for gradient background")
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.textMuted)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    isLoadingImage = true
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        saveSelectedImage(image)
                    }
                    isLoadingImage = false
                }
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
    }

    // MARK: - Screen 5: Pick Calendars

    private var calendarSelectionScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            VStack(spacing: DesignTokens.spacingMD) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignTokens.accentGradient)

                Text("Select Calendars")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                if selectedCalendarSource == .google {
                    if googleCalendarVM.availableCalendars.isEmpty {
                        Text("Loading your Google calendars...")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Choose which calendars to show on your wallpaper")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if !calendarAccessGranted || availableCalendars.isEmpty {
                    VStack(spacing: DesignTokens.spacingMD) {
                        Text("Calendar access not granted. Sample events will be shown until you grant access.")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        } label: {
                            Text("Open Settings to Grant Access")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.primary)
                        }
                    }
                    .padding(.top, DesignTokens.spacingLG)
                } else {
                    Text("Choose which calendars to show on your wallpaper")
                        .font(.system(size: 16))
                        .foregroundColor(DesignTokens.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, DesignTokens.spacingXL)

            if selectedCalendarSource == .google && !googleCalendarVM.availableCalendars.isEmpty {
                googleCalendarListView
            } else if selectedCalendarSource == .apple && calendarAccessGranted && !availableCalendars.isEmpty {
                appleCalendarListView
            } else {
                Spacer()
            }

            Button {
                saveCalendarSelections()
                advanceTo(5)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .cornerRadius(DesignTokens.cardRadius)
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Apple Calendar List

    private var appleCalendarListView: some View {
        Group {
            let allSelected = enabledCalendarIDs.count == availableCalendars.count

            HStack {
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        enabledCalendarIDs = []
                    } else {
                        enabledCalendarIDs = Set(availableCalendars.map { $0.calendarIdentifier })
                    }
                }
                .font(.subheadline)
                .foregroundColor(DesignTokens.primary)
                Spacer()
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: DesignTokens.spacingSM) {
                    ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(cgColor: calendar.cgColor))
                                .frame(width: 12, height: 12)

                            Text(calendar.title)
                                .font(.system(size: 16))
                                .foregroundColor(DesignTokens.textPrimary)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { enabledCalendarIDs.contains(calendar.calendarIdentifier) },
                                set: { isOn in
                                    if isOn {
                                        enabledCalendarIDs.insert(calendar.calendarIdentifier)
                                    } else {
                                        enabledCalendarIDs.remove(calendar.calendarIdentifier)
                                    }
                                }
                            ))
                            .tint(DesignTokens.primary)
                        }
                        .padding()
                        .background(DesignTokens.surface)
                        .cornerRadius(DesignTokens.cardRadius)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Google Calendar List

    private var googleCalendarListView: some View {
        Group {
            let allSelected = googleCalendarVM.enabledGoogleCalendarIDs.count == googleCalendarVM.availableCalendars.count

            HStack {
                Button(allSelected ? "Deselect All" : "Select All") {
                    if allSelected {
                        googleCalendarVM.enabledGoogleCalendarIDs = []
                    } else {
                        googleCalendarVM.enabledGoogleCalendarIDs = Set(googleCalendarVM.availableCalendars.map { $0.id })
                    }
                }
                .font(.subheadline)
                .foregroundColor(DesignTokens.primary)
                Spacer()
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: DesignTokens.spacingSM) {
                    ForEach(googleCalendarVM.availableCalendars) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(uiColor: ColorUtils.color(from: calendar.backgroundColor ?? "#4285F4")))
                                .frame(width: 12, height: 12)

                            Text(calendar.summary ?? calendar.id)
                                .font(.system(size: 16))
                                .foregroundColor(DesignTokens.textPrimary)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { googleCalendarVM.enabledGoogleCalendarIDs.contains(calendar.id) },
                                set: { isOn in
                                    if isOn {
                                        googleCalendarVM.enabledGoogleCalendarIDs.insert(calendar.id)
                                    } else {
                                        googleCalendarVM.enabledGoogleCalendarIDs.remove(calendar.id)
                                    }
                                }
                            ))
                            .tint(DesignTokens.primary)
                        }
                        .padding()
                        .background(DesignTokens.surface)
                        .cornerRadius(DesignTokens.cardRadius)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Screen 6: Choose Template

    private var templatePickerScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            VStack(spacing: DesignTokens.spacingMD) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignTokens.accentGradient)

                Text("Pick Your Style")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Choose your default wallpaper template")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, DesignTokens.spacingXL)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.spacingMD) {
                    ForEach(TemplateType.allCases, id: \.self) { template in
                        templateCard(for: template)
                    }
                }
                .padding(.horizontal, DesignTokens.spacingXL)
            }

            Spacer()

            Button {
                saveTemplateSelection()
                advanceTo(6)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .cornerRadius(DesignTokens.cardRadius)
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
    }

    private func templateCard(for template: TemplateType) -> some View {
        let isSelected = selectedTemplateType == template

        return VStack(spacing: DesignTokens.spacingMD) {
            RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                .fill(templateGradient(for: template))
                .frame(width: 140, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cardRadius)
                        .stroke(isSelected ? DesignTokens.primary : Color.clear, lineWidth: 3)
                )

            Text(template.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? DesignTokens.primary : DesignTokens.textPrimary)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTemplateType = template
            }
        }
    }

    private func templateGradient(for template: TemplateType) -> LinearGradient {
        switch template {
        case .minimal:
            return LinearGradient(colors: [DesignTokens.surface, DesignTokens.background], startPoint: .top, endPoint: .bottom)
        case .glass:
            return LinearGradient(colors: [DesignTokens.primary.opacity(0.3), DesignTokens.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gradient:
            return LinearGradient(colors: [DesignTokens.primary, DesignTokens.primaryGlow], startPoint: .leading, endPoint: .trailing)
        case .editorial:
            return LinearGradient(colors: [DesignTokens.textPrimary.opacity(0.1), DesignTokens.surface], startPoint: .top, endPoint: .bottom)
        case .neon:
            return LinearGradient(colors: [DesignTokens.primaryGlow, DesignTokens.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .split:
            return LinearGradient(colors: [DesignTokens.primary, DesignTokens.surface], startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: - Screen 7: Automation Setup

    private var automationScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.accentGradient)
                .padding(.bottom, DesignTokens.spacingLG)

            VStack(spacing: DesignTokens.spacingMD) {
                Text("Automation")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Set up Shortcuts to automatically update your wallpaper throughout the day")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: DesignTokens.spacingMD) {
                NavigationLink {
                    ShortcutsGuideView()
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Set Up Shortcuts")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.accentGradient)
                    .cornerRadius(DesignTokens.cardRadius)
                }

                Button {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: DesignTokens.spacingSM) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Open Shortcuts App")
                    }
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.primary)
                }

                Button {
                    advanceTo(7)
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textMuted)
                }
            }
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
    }

    // MARK: - Screen 8: Done

    private var doneScreen: some View {
        VStack(spacing: DesignTokens.spacingXL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.success.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(DesignTokens.success)
            }
            .padding(.bottom, DesignTokens.spacingLG)

            VStack(spacing: DesignTokens.spacingMD) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("Ready to create your first beautiful wallpaper")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                Task {
                    isGeneratingInitialWallpaper = true
                    await generateInitialWallpaper()
                    completeOnboarding()
                }
            } label: {
                Group {
                    if isGeneratingInitialWallpaper {
                        ProgressView().tint(.white)
                    } else {
                        Text("Generate First Wallpaper")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignTokens.accentGradient)
                .cornerRadius(DesignTokens.cardRadius)
            }
            .disabled(isGeneratingInitialWallpaper)
            .padding(.horizontal, DesignTokens.spacingXL)
            .padding(.bottom, 50)
        }
        .padding()
    }

    // MARK: - Navigation

    private func advanceTo(_ page: Int) {
        maxAllowedPage = max(maxAllowedPage, page)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentPage = page
        }
    }

    // MARK: - Helper Methods

    private func saveSelectedImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let imageURL = AppGroupManager.imagesDirectory.appendingPathComponent("selected_background.jpg")
        try? imageData.write(to: imageURL)
        AppGroupManager.userDefaults.set(imageURL.path, forKey: "selectedBackgroundImagePath")
    }

    private func saveCalendarSelections() {
        if selectedCalendarSource == .google {
            googleCalendarVM.saveEnabledCalendarIDs()
        } else {
            let idsArray = Array(enabledCalendarIDs)
            AppGroupManager.userDefaults.set(idsArray, forKey: "enabledCalendarIDs")
        }
    }

    private func saveTemplateSelection() {
        AppGroupManager.userDefaults.set(selectedTemplateType.rawValue, forKey: "defaultTemplateType")
    }

    private func generateInitialWallpaper() async {
        viewModel.backgroundImage = selectedImage
        viewModel.selectedTemplateType = selectedTemplateType

        let events: [CalendarEvent]
        if selectedCalendarSource == .google {
            events = googleCalendarVM.todayEvents.isEmpty
                ? WallpaperViewModel.sampleEvents
                : Array(googleCalendarVM.todayEvents.prefix(6))
        } else if calendarAccessGranted {
            let enabledIDs = Array(enabledCalendarIDs)
            events = calendarProvider.fetchTodayEvents(
                from: enabledIDs,
                excludeDeclined: true,
                maxEvents: 6
            )
        } else {
            events = WallpaperViewModel.sampleEvents
        }

        AppGroupManager.ensureDirectoriesExist()
        guard let wallpaper = viewModel.generateFullResolution(
            events: events,
            resolution: .iPhone16Pro
        ) else { return }

        let wallpaperURL = AppGroupManager.wallpaperDirectory.appending(path: "current.png")
        if let pngData = wallpaper.pngData() {
            try? pngData.write(to: wallpaperURL)
        }
    }

    private func completeOnboarding() {
        AppGroupManager.userDefaults.set(true, forKey: "onboardingCompleted")
        onComplete()
    }
}

#Preview {
    NavigationStack {
        OnboardingView(onComplete: {})
    }
}
