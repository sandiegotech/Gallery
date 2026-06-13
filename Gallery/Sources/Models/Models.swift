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
    /// A hidden wing (the Wine-Dark wing) — kept out of the lobby until found.
    let hidden: Bool?

    var isHidden: Bool { hidden ?? false }
}

enum FrameStyle: String, Codable {
    /// Ornate gold frame — Impressionist & academic gilt (Van Gogh, Monet)
    case gilded
    /// Heavy carved Salon/Baroque gold with a deep profile (Caravaggio, Sargent)
    case baroque
    /// Ebonized black with a gold sight-line — Dutch Golden Age (Vermeer, Bruegel)
    case dutch
    /// Wide flat gold with incised lines — Vienna Secession (Klimt)
    case secession
    /// Dark wood frame — the plain, default frame
    case classic
    /// Thin black frame, no mat — modern works
    case modern
    /// Wide ivory mat inside a thin frame — posters, prints, woodblocks
    case float
    /// No frame at all — street art painted straight onto the wall
    case none

    /// Unknown values from a future manifest fall back to a plain frame.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FrameStyle(rawValue: raw) ?? .classic
    }
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
