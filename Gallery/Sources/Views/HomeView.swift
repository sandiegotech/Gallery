import SwiftUI

/// The lobby: pick tonight's exhibition.
struct HomeView: View {
    @EnvironmentObject private var store: ContentStore
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.sditTheme) private var theme
    @State private var path = NavigationPath()
    @State private var showWelcome = false
    @State private var showRelease = false

    /// True when a debug launch argument is steering us straight to a screen,
    /// so the first-run welcome doesn't get in the way.
    private var isDeepLaunch: Bool {
        let d = UserDefaults.standard
        return d.string(forKey: "exhibition") != nil
            || d.bool(forKey: "openSettings")
            || d.bool(forKey: "openRelease")
    }

    /// The exhibitions shown in the lobby — hidden wings stay out until found.
    private var lobbyCollections: [GalleryCollection] {
        store.collections.filter { !$0.isHidden }
    }

    private var wineDarkCollection: GalleryCollection? {
        store.collections.first { $0.id == "winedark" }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                WallBackground(spotlightCenter: UnitPoint(x: 0.5, y: 0.28))

                VStack(spacing: 0) {
                    Spacer(minLength: 30)
                    Text("The Gallery")
                        .font(.sditDisplay(74))
                        .foregroundStyle(theme.textPrimary)
                        .rise(0)
                    Text("A museum for your living room.")
                        .font(.sditDisplay(28, italic: true))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.top, 12)
                        .rise(0.08)

                    Group {
                        if store.collections.isEmpty {
                            if let error = store.loadError {
                                Text(error)
                                    .font(.sditMono(20))
                                    .foregroundStyle(theme.textSecondary)
                            } else {
                                ProgressView().tint(theme.textMetadata)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 44) {
                                ForEach(Array(lobbyCollections.enumerated()), id: \.element.id) { index, collection in
                                    NavigationLink(value: collection) {
                                        CollectionCard(
                                            collection: collection,
                                            number: index + 1,
                                            cover: store.coverArtwork(for: collection)
                                        )
                                    }
                                    .buttonStyle(SDITCardButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.top, 54)
                    .rise(0.16)

                    // The exclusive release, once the door behind the colophon
                    // has been found. Opening it spends it — see the cover's
                    // onDismiss below.
                    if settings.wineDarkUnlocked, let wine = wineDarkCollection {
                        WineDarkBanner(collection: wine, cover: store.coverArtwork(for: wine)) {
                            showRelease = true
                        }
                        .padding(.top, 34)
                        .frame(maxWidth: 1480)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 80)

                // The imprint — and the door to the Wine-Dark wing.
                VStack {
                    Spacer()
                    ColophonView()
                        .padding(.bottom, 34)
                        .rise(0.32)
                }

                // Settings.
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(value: "settings") {
                            Image(systemName: "gearshape")
                                .font(.system(size: 23, weight: .light))
                        }
                        .buttonStyle(SDITOptionButtonStyle(isSelected: false))
                        .padding(.trailing, 56)
                        .padding(.bottom, 40)
                        .rise(0.24)
                    }
                }
            }
            .navigationDestination(for: GalleryCollection.self) { collection in
                ExhibitionView(
                    collection: collection,
                    number: (store.collections.firstIndex(of: collection) ?? 0) + 1
                )
            }
            .navigationDestination(for: String.self) { _ in
                SettingsView()
            }
            // First-run note: set the system screen saver to Never.
            .onAppear {
                if !settings.seenScreensaverTip && !isDeepLaunch {
                    showWelcome = true
                }
            }
            // The exclusive release. Showing it once spends it: on dismiss the
            // door closes and the banner leaves the lobby.
            .fullScreenCover(isPresented: $showRelease, onDismiss: {
                withAnimation(.easeInOut(duration: 0.8)) {
                    settings.wineDarkUnlocked = false
                }
            }) {
                WineDarkReleaseView(artwork: wineDarkCollection.flatMap { store.coverArtwork(for: $0) })
            }
            .fullScreenCover(isPresented: $showWelcome, onDismiss: {
                settings.seenScreensaverTip = true
            }) {
                WelcomeTipView()
            }
            // Debug hooks: `simctl launch ... -exhibition street`, `-openSettings YES`,
            // or `-openRelease YES` jump straight to a screen.
            .onChange(of: store.collections) { _, collections in
                if let id = UserDefaults.standard.string(forKey: "exhibition"),
                   let match = collections.first(where: { $0.id == id }) {
                    path.append(match)
                }
                if UserDefaults.standard.bool(forKey: "openSettings") {
                    path.append("settings")
                }
                if UserDefaults.standard.bool(forKey: "openRelease") {
                    showRelease = true
                }
            }
        }
    }
}

struct CollectionCard: View {
    @Environment(\.sditTheme) private var theme
    let collection: GalleryCollection
    let number: Int
    let cover: Artwork?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                theme.surfaceFocused
                if let cover {
                    ArtImage(name: cover.image)
                        .scaledToFill()
                }
            }
            .frame(width: 330, height: 264)
            .clipped()

            HairlineRule()

            VStack(alignment: .leading, spacing: 9) {
                Eyebrow("Exhibition \(romanNumeral(number))", size: 15)
                Text(collection.title)
                    .font(.sditDisplay(29))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(collection.subtitle)
                    .font(.sditBody(18))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(width: 330, alignment: .leading)
        }
    }
}

// MARK: - The colophon (and the hidden door)

/// The imprint at the foot of the lobby. It reads as fine print — but the
/// wine-dark seal beside it fills a little with every press, and on the fifth
/// it opens a wing the lobby never advertised.
private struct ColophonView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.sditTheme) private var theme
    @State private var taps = 0
    @State private var justUnlocked = false
    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity: Double = 0

    private let threshold = 5
    /// A garnet that stays legible on both dark and light walls.
    private static let wine = Color(red: 0.62, green: 0.17, blue: 0.30)

    private var unlocked: Bool { settings.wineDarkUnlocked }
    private var progress: Double {
        unlocked ? 1 : min(1, Double(taps) / Double(threshold))
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: press) {
                HStack(spacing: 12) {
                    seal
                    imprint
                }
            }
            .buttonStyle(ColophonButtonStyle())
            .disabled(unlocked)

            if justUnlocked {
                Text("An exclusive release has surfaced.")
                    .font(.sditDisplay(19, italic: true))
                    .foregroundStyle(theme.gold)
                    .transition(.opacity)
            }
        }
        // When the release is spent the door closes; reset so it takes the
        // full five presses to summon again.
        .onChange(of: unlocked) { _, isOpen in
            if !isOpen { taps = 0 }
        }
    }

    private var seal: some View {
        ZStack {
            Circle().strokeBorder(theme.textMetadata.opacity(0.55), lineWidth: 1.5)
            Circle()
                .fill(Self.wine)
                .scaleEffect(progress)
            Circle()
                .strokeBorder(theme.gold, lineWidth: 1.5)
                .opacity(unlocked ? 1 : 0)
            // The bloom: a gold ring that flares outward the moment it opens.
            Circle()
                .strokeBorder(theme.gold, lineWidth: 2)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
        }
        .frame(width: 16, height: 16)
    }

    private var imprint: Text {
        Text("Built by the San Diego Institute of Technology")
            .foregroundColor(theme.textMetadata)
    }

    private func press() {
        guard !unlocked else { return }
        let next = taps + 1
        if next >= threshold {
            withAnimation(.easeInOut(duration: 0.9)) {
                settings.wineDarkUnlocked = true
                justUnlocked = true
            }
            // Flare the seal open.
            ringScale = 1
            ringOpacity = 0.9
            withAnimation(.easeOut(duration: 1.2)) {
                ringScale = 3.2
                ringOpacity = 0
            }
            // Let the welcome linger, then settle back to fine print.
            Task {
                try? await Task.sleep(for: .seconds(4.5))
                withAnimation(.easeOut(duration: 0.8)) { justUnlocked = false }
            }
        } else {
            withAnimation(.easeOut(duration: 0.35)) { taps = next }
        }
    }
}

/// Fine print that brightens and lifts under focus — no card, no border.
private struct ColophonButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sditMono(15))
            .tracking(1.2)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .opacity(configuration.isPressed ? 0.55 : (isFocused ? 1 : 0.6))
            .scaleEffect(isFocused ? 1.06 : 1.0)
            .animation(.easeOut(duration: 0.25), value: isFocused)
    }
}

/// The exclusive release, presented as its own wine-dark plate beneath the
/// standard exhibitions. Selecting it opens a one-time ceremonial moment.
private struct WineDarkBanner: View {
    let collection: GalleryCollection
    let cover: Artwork?
    let action: () -> Void

    private static let gold = Color(red: 0.84, green: 0.70, blue: 0.37)
    private static let rose = Color(red: 0.85, green: 0.62, blue: 0.66)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 30) {
                seal
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Exclusive Release · Wine-Dark", size: 14, color: Self.gold)
                    Text(collection.title)
                        .font(.sditDisplay(36))
                        .foregroundStyle(SDITTheme.paper.opacity(0.96))
                    Text("A release that shows once, then returns to the deep.")
                        .font(.sditSerif(21))
                        .foregroundStyle(Self.rose)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if let cover {
                    ArtImage(name: cover.image)
                        .scaledToFill()
                        .frame(width: 230, height: 104)
                        .clipped()
                        .overlay(Rectangle().strokeBorder(Self.gold.opacity(0.5), lineWidth: 1))
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.24, green: 0.06, blue: 0.11),
                        Color(red: 0.12, green: 0.03, blue: 0.07),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .buttonStyle(SDITCardButtonStyle(quiet: true))
    }

    private var seal: some View {
        ZStack {
            Circle().fill(Self.gold.opacity(0.14))
            Circle().strokeBorder(Self.gold, lineWidth: 2)
            Text("✦")
                .font(.system(size: 30))
                .foregroundStyle(Self.gold)
        }
        .frame(width: 66, height: 66)
    }
}

// MARK: - First-run welcome

/// The first-run welcome: a slow, spotlit gallery entrance that doubles as the
/// one note worth giving up front — turn off the system screen saver so a long
/// viewing is never interrupted. Shown once.
private struct WelcomeTipView: View {
    @Environment(\.sditTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WallBackground(spotlightCenter: UnitPoint(x: 0.5, y: 0.38))
            // A touch dimmer than the lobby — like stepping into the room
            // before the lights come up.
            Color.black.opacity(0.22).ignoresSafeArea()

            VStack(spacing: 0) {
                Eyebrow("Welcome to", size: 17).rise(0.1)
                Text("The Gallery")
                    .font(.sditDisplay(80))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.top, 10)
                    .rise(0.3)
                Text("A museum for your living room.")
                    .font(.sditDisplay(27, italic: true))
                    .foregroundStyle(theme.marine)
                    .padding(.top, 12)
                    .rise(0.6)

                VStack(spacing: 16) {
                    HairlineRule().frame(width: 200)
                    Text("Before you enter")
                        .font(.sditMono(14))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundStyle(theme.gold)
                    Text("The Gallery lights its own room and keeps the screen awake. For an unbroken view, set the Apple TV's screen saver never to start.")
                        .font(.sditBody(22))
                        .lineSpacing(6)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: 880)
                    Text("Settings › General › Screen Saver › Start After › Never")
                        .font(.sditMono(17))
                        .tracking(1.2)
                        .foregroundStyle(theme.textMetadata)
                }
                .padding(.top, 50)
                .rise(0.9)

                Button("Enter the gallery") { dismiss() }
                    .buttonStyle(SDITCTAButtonStyle())
                    .padding(.top, 54)
                    .rise(1.2)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 120)
        }
        .onExitCommand { dismiss() }
    }
}
