import SwiftUI

/// The room itself: one spotlit artwork at a time, a quiet placard below,
/// paired music playing. Entering shows a brief wall-text title card.
/// Left/right browses, play/pause controls the music, selecting the
/// placard opens the story, Menu returns to the lobby.
struct ExhibitionView: View {
    let collection: GalleryCollection
    let number: Int

    @EnvironmentObject private var store: ContentStore
    @EnvironmentObject private var music: MusicPlayer
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.sditTheme) private var theme

    @State private var artworks: [Artwork] = []
    @State private var index = 0
    @State private var showDetail = false
    @State private var showIntro = true
    @State private var pendingAdvance = false
    @State private var advanceTask: Task<Void, Never>?

    /// Timed pacing, or nil when the room moves on with the music.
    private var dwell: Duration? {
        settings.dwell > 0 ? .seconds(settings.dwell) : nil
    }

    private var current: Artwork? {
        artworks.indices.contains(index) ? artworks[index] : nil
    }

    var body: some View {
        ZStack {
            WallBackground()

            if showIntro {
                RoomIntroView(collection: collection, number: number)
                    .transition(.opacity)
            } else if let artwork = current {
                // Artwork fills the wall; placard hangs beside it at eye level.
                HStack(alignment: .center, spacing: 0) {
                    FramedArtworkView(artwork: artwork)
                        .frame(maxWidth: .infinity, maxHeight: 860)
                    PlacardButton(artwork: artwork) { showDetail = true }
                        .frame(width: 360)
                        .padding(.leading, 52)
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 50)
                .id(artwork.id)
                .transition(.opacity)
            } else if artworks.isEmpty {
                Text("This room is being rehung.")
                    .font(.sditDisplay(30, italic: true))
                    .foregroundStyle(theme.textSecondary)
            }

        }
        .onMoveCommand { direction in
            switch direction {
            case .left: step(-1)
            case .right: step(1)
            default: break
            }
        }
        .onPlayPauseCommand { music.togglePause() }
        .onAppear {
            artworks = store.artworks(in: collection)
            music.loopsTracks = dwell != nil
            music.onTrackEnd = { advanceWithTheMusic() }
            music.play(current?.music)
            scheduleAdvance()
            if UserDefaults.standard.bool(forKey: "showDetail") { showDetail = true }
            Task {
                try? await Task.sleep(for: .seconds(3.6))
                withAnimation(.easeInOut(duration: 0.9)) { showIntro = false }
            }
        }
        .onDisappear {
            advanceTask?.cancel()
            music.onTrackEnd = nil
            music.fadeOutAndStop()
        }
        .onChange(of: showDetail) { _, isShowing in
            if !isShowing {
                if pendingAdvance {
                    pendingAdvance = false
                    step(1)
                } else {
                    scheduleAdvance()
                }
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let artwork = current {
                ArtworkDetailView(artwork: artwork)
            }
        }
    }

    private func step(_ delta: Int) {
        guard !artworks.isEmpty else { return }
        withAnimation(.easeInOut(duration: 1.1)) {
            index = (index + delta + artworks.count) % artworks.count
        }
        music.play(current?.music)
        scheduleAdvance()
    }

    private func scheduleAdvance() {
        advanceTask?.cancel()
        // In "with the music" pacing the track ending advances the room;
        // the timer only covers timed pacing and works that have no music.
        let wait = dwell ?? (current?.music == nil ? .seconds(60) : nil)
        guard let wait else { return }
        advanceTask = Task {
            try? await Task.sleep(for: wait)
            guard !Task.isCancelled, !showDetail else { return }
            step(1)
        }
    }

    /// The recording ended. Move on — unless the viewer is reading.
    private func advanceWithTheMusic() {
        guard !showDetail else {
            pendingAdvance = true
            return
        }
        step(1)
    }
}

/// The wall text at the entrance of a room: exhibition number, title,
/// and a line of italic standfirst — shown briefly before the first work.
private struct RoomIntroView: View {
    @Environment(\.sditTheme) private var theme
    let collection: GalleryCollection
    let number: Int

    var body: some View {
        VStack(spacing: 24) {
            Eyebrow("Exhibition \(romanNumeral(number))", size: 20)
                .rise(0)
            Text(collection.title)
                .font(.sditDisplay(66))
                .foregroundStyle(theme.textPrimary)
                .rise(0.08)
            Text(collection.subtitle)
                .font(.sditDisplay(28, italic: true))
                .foregroundStyle(theme.marine)
                .rise(0.16)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 200)
    }
}
