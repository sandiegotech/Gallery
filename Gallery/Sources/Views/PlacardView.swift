import SwiftUI

/// The wall label, hung beside the work the way a gallery would place it:
/// artist, title in italic, date and medium, a few lines of description, and
/// the paired music. A position line and a left/right hint make clear the
/// room moves with the remote. Selecting it opens the full story.
struct PlacardButton: View {
    @Environment(\.sditTheme) private var theme
    let artwork: Artwork
    /// e.g. "2 / 9" — where this work sits in the room. Hidden when nil.
    var position: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Eyebrow(artwork.artist, size: 15)
                Text(artwork.title)
                    .font(.sditDisplay(30, italic: true))
                    .foregroundStyle(theme.marine)
                    .lineLimit(3)
                Text("\(artwork.year) · \(artwork.medium)".uppercased())
                    .font(.sditMono(14))
                    .tracking(1.7)
                    .foregroundStyle(theme.textMetadata)
                    .lineLimit(1)
                Text(artwork.summary)
                    .font(.sditBody(20))
                    .lineSpacing(4)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(6)
                    .padding(.top, 10)
                if let music = artwork.music {
                    Text("♪ \(music.composer) — \(music.title), \(music.year)".uppercased())
                        .font(.sditMono(14))
                        .tracking(1.7)
                        .foregroundStyle(theme.textMetadata)
                        .lineLimit(2)
                        .padding(.top, 12)
                }

                HairlineRule().padding(.vertical, 18)

                HStack(spacing: 12) {
                    if let position {
                        Text(position)
                            .font(.sditMono(14))
                            .tracking(2)
                            .foregroundStyle(theme.textMetadata)
                    }
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("MOVE")
                    }
                    .font(.sditMono(14))
                    .tracking(2)
                    .foregroundStyle(theme.textMetadata)
                    Spacer(minLength: 0)
                    Text("THE STORY →")
                        .font(.sditMono(14))
                        .tracking(2)
                        .foregroundStyle(theme.gold)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(SDITCardButtonStyle(quiet: true))
    }
}
