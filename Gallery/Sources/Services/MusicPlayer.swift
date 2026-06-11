import AVFoundation
import Foundation

/// Plays the ambient track paired with the current artwork, crossfading
/// whenever the artwork changes. In timed pacing the track repeats; in
/// "with the music" pacing the room is told when the recording ends so
/// it can hang the next work.
@MainActor
final class MusicPlayer: NSObject, ObservableObject {
    @Published private(set) var nowPlaying: MusicTrack?
    @Published private(set) var isPlaying = false

    /// When true, a finished track starts over. When false, `onTrackEnd`
    /// fires instead.
    var loopsTracks = true
    var onTrackEnd: (() -> Void)?

    private var player: AVAudioPlayer?
    private var fadingOut: AVAudioPlayer?
    private var manuallyPaused = false

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ track: MusicTrack?) {
        let enabled = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
        guard let track, enabled else {
            fadeOutAndStop()
            return
        }
        // Same track, still sounding (or deliberately paused): leave it be.
        if track == nowPlaying, let player, player.isPlaying || manuallyPaused { return }
        nowPlaying = track
        guard let url = ContentStore.mediaURL(for: track.file) else { return }

        Task {
            do {
                let newPlayer: AVAudioPlayer
                if url.isFileURL {
                    newPlayer = try AVAudioPlayer(contentsOf: url)
                } else {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    newPlayer = try AVAudioPlayer(data: data)
                }
                // The viewer may have moved to another piece while this loaded.
                guard nowPlaying == track else { return }
                crossfade(to: newPlayer)
            } catch {
                // Silence is better than breaking the mood.
            }
        }
    }

    func togglePause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            manuallyPaused = true
        } else {
            player.play()
            isPlaying = true
            manuallyPaused = false
        }
    }

    func fadeOutAndStop() {
        nowPlaying = nil
        isPlaying = false
        manuallyPaused = false
        guard let old = player else { return }
        player = nil
        old.setVolume(0, fadeDuration: 1.2)
        fadingOut = old
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            old.stop()
            if fadingOut === old { fadingOut = nil }
        }
    }

    private func crossfade(to newPlayer: AVAudioPlayer) {
        if let old = player {
            old.setVolume(0, fadeDuration: 1.5)
            fadingOut = old
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                old.stop()
                if fadingOut === old { fadingOut = nil }
            }
        }
        newPlayer.numberOfLoops = 0
        newPlayer.delegate = self
        newPlayer.volume = 0
        newPlayer.prepareToPlay()
        newPlayer.play()
        newPlayer.setVolume(0.8, fadeDuration: 2.5)
        player = newPlayer
        isPlaying = true
        manuallyPaused = false
    }

    private func trackFinished(_ finished: AVAudioPlayer) {
        guard finished === player else { return }
        if loopsTracks {
            finished.currentTime = 0
            finished.play()
        } else {
            isPlaying = false
            onTrackEnd?()
        }
    }
}

extension MusicPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.trackFinished(player) }
    }
}
