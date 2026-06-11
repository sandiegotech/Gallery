import Foundation
import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
    @Published private(set) var manifest: Manifest?
    @Published private(set) var loadError: String?

    /// Point this at a hosted manifest.json later to stream new exhibitions
    /// without shipping an app update. Artwork `image` and music `file` fields
    /// may then be absolute URLs. Falls back to the bundled manifest on failure.
    static let remoteManifestURL: URL? = nil

    func load() async {
        if let url = Self.remoteManifestURL,
           let (data, _) = try? await URLSession.shared.data(from: url),
           let remote = try? JSONDecoder().decode(Manifest.self, from: data) {
            manifest = remote
            return
        }
        do {
            guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json") else {
                loadError = "manifest.json is missing from the app bundle"
                return
            }
            let data = try Data(contentsOf: url)
            manifest = try JSONDecoder().decode(Manifest.self, from: data)
        } catch {
            loadError = error.localizedDescription
        }
    }

    var collections: [GalleryCollection] { manifest?.collections ?? [] }

    func artworks(in collection: GalleryCollection) -> [Artwork] {
        guard let all = manifest?.artworks else { return [] }
        let filtered = collection.id == "eclectic"
            ? all
            : all.filter { $0.collections.contains(collection.id) }
        return filtered.shuffled()
    }

    func coverArtwork(for collection: GalleryCollection) -> Artwork? {
        guard let all = manifest?.artworks else { return nil }
        if let id = collection.coverArtworkID,
           let match = all.first(where: { $0.id == id }) {
            return match
        }
        if collection.id == "eclectic" { return all.first }
        return all.first { $0.collections.contains(collection.id) }
    }

    /// Resolves a manifest media reference to either a bundled file or remote URL.
    static func mediaURL(for name: String) -> URL? {
        if name.hasPrefix("http") { return URL(string: name) }
        return Bundle.main.url(forResource: name, withExtension: nil)
    }
}
