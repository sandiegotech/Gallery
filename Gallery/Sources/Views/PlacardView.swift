import SwiftUI

/// The wall label, hung beside the work the way a gallery would place
/// it: artist, title in italic, date and medium, and a few lines of
/// description. Selecting it opens the full story.
struct PlacardButton: View {
    @Environment(\.sditTheme) private var theme
    let artwork: Artwork
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(artwork.artist, size: 14)
                Text(artwork.title)
                    .font(.sditDisplay(26, italic: true))
                    .foregroundStyle(theme.marine)
                    .lineLimit(2)
                Text("\(artwork.year) · \(artwork.medium)".uppercased())
                    .font(.sditMono(13))
                    .tracking(1.6)
                    .foregroundStyle(theme.textMetadata)
                    .lineLimit(1)
                Text(artwork.summary)
                    .font(.sditBody(18))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(4)
                    .padding(.top, 8)
                if let music = artwork.music {
                    Text("♪ \(music.composer) — \(music.title), \(music.year)".uppercased())
                        .font(.sditMono(13))
                        .tracking(1.6)
                        .foregroundStyle(theme.textMetadata)
                        .lineLimit(2)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(SDITCardButtonStyle(quiet: true))
    }
}
