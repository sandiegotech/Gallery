import Foundation
import SwiftUI

/// The room's few preferences, persisted in UserDefaults under the same
/// keys the debug launch arguments use — so `-appearance night` and the
/// settings screen are one mechanism.
@MainActor
final class SettingsStore: ObservableObject {
    /// The gallery wall: "ink", "charcoal", or "stone".
    @Published var wall: String {
        didSet { UserDefaults.standard.set(wall, forKey: "wall") }
    }
    @Published var musicOn: Bool {
        didSet { UserDefaults.standard.set(musicOn, forKey: "musicEnabled") }
    }
    /// Seconds each work hangs before the room moves on.
    /// 0 means "with the music" — the room advances when the track ends.
    @Published var dwell: Int {
        didSet { UserDefaults.standard.set(dwell, forKey: "dwellSeconds") }
    }

    init() {
        let defaults = UserDefaults.standard
        wall = defaults.string(forKey: "wall") ?? "ink"
        musicOn = defaults.object(forKey: "musicEnabled") as? Bool ?? true
        dwell = defaults.object(forKey: "dwellSeconds") as? Int ?? 0
    }
}
