import Foundation

struct Manifest: Codable {
    let version: Int
    let collections: [GalleryCollection]
    let artworks: [Artwork]
}

struct GalleryCollection: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let coverArtworkID: String?
}

enum FrameStyle: String, Codable {
    /// Ornate gold frame — old-master paintings
    case gilded
    /// Dark wood frame — earlier works, woodblock prints
    case classic
    /// Thin black frame, no mat — modern works
    case modern
    /// Wide ivory mat inside a thin frame — posters, prints, photographs
    case float
    /// No frame at all — street art painted straight onto the wall
    case none
}

struct MusicTrack: Codable, Hashable {
    let title: String
    let composer: String
    let year: String
    /// Bundled filename (e.g. "gymnopedie-1.mp3") or an absolute http(s) URL
    let file: String
    let credit: String?
}

struct Artwork: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let year: String
    let medium: String
    /// One or two sentences shown on the wall placard
    let summary: String
    /// The longer story shown when the placard is selected
    let story: String
    /// Why this music was paired with this piece (optional)
    let pairing: String?
    /// Bundled filename (e.g. "wheat-field.jpg") or an absolute http(s) URL
    let image: String
    let frameStyle: FrameStyle
    let collections: [String]
    let music: MusicTrack?
    let credit: String
}
