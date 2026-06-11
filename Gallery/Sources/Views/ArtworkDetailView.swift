import SwiftUI

/// The full curatorial story, shown when the placard is selected.
struct ArtworkDetailView: View {
    @Environment(\.sditTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let artwork: Artwork

    var body: some View {
        ZStack {
            WallBackground(spotlightCenter: UnitPoint(x: 0.25, y: 0.45))

            HStack(alignment: .center, spacing: 76) {
                FramedArtworkView(artwork: artwork)
                    .frame(maxWidth: 600, maxHeight: 700)
                    .rise(0)

                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("The Work", size: 17)
                    Text(artwork.title)
                        .font(.sditDisplay(44))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.top, 16)
                    Text("\(artwork.artist) · \(artwork.year) · \(artwork.medium)".uppercased())
                        .font(.sditMono(17))
                        .tracking(2.2)
                        .foregroundStyle(theme.textMetadata)
                        .padding(.top, 12)

                    HairlineRule()
                        .padding(.vertical, 26)

                    Text(artwork.story)
                        .font(.sditBody(24))
                        .lineSpacing(8)
                        .foregroundStyle(theme.textPrimary)

                    if let music = artwork.music {
                        Eyebrow("The Music", size: 17)
                            .padding(.top, 30)
                        Text("\(music.title) — \(music.composer), \(music.year)")
                            .font(.sditDisplay(27, italic: true))
                            .foregroundStyle(theme.marine)
                            .padding(.top, 12)
                        if let pairing = artwork.pairing {
                            Text(pairing)
                                .font(.sditBody(21))
                                .foregroundStyle(theme.textSecondary)
                                .padding(.top, 8)
                        }
                    }

                    HairlineRule()
                        .padding(.vertical, 24)

                    HStack(alignment: .center) {
                        Text(artwork.credit.uppercased())
                            .font(.sditMono(14))
                            .tracking(1.2)
                            .foregroundStyle(theme.textMetadata)
                        Spacer()
                        Button("Return to the room") { dismiss() }
                            .buttonStyle(SDITCTAButtonStyle())
                    }
                }
                .frame(maxWidth: 880, alignment: .leading)
                .rise(0.12)
            }
            .padding(64)
        }
        .onExitCommand { dismiss() }
    }
}
