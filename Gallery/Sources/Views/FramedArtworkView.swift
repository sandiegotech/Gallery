import SwiftUI

/// Loads an artwork image from the bundle or a remote URL.
struct ArtImage: View {
    let name: String

    var body: some View {
        if let url = ContentStore.mediaURL(for: name) {
            if url.isFileURL {
                if let ui = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                } else {
                    missing
                }
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        missing
                    default:
                        ProgressView()
                            .frame(width: 600, height: 450)
                    }
                }
            }
        } else {
            missing
        }
    }

    private var missing: some View {
        ZStack {
            Rectangle().fill(Color(red: 13 / 255, green: 24 / 255, blue: 37 / 255))
            Text("WORK UNAVAILABLE")
                .font(.sditMono(18))
                .tracking(3)
                .foregroundStyle(SDITTheme.paper.opacity(0.4))
        }
        .frame(width: 600, height: 450)
    }
}

/// A slow, museum-quiet drift — a gentle zoom and pan that gives a still
/// image a breath of life on a television, the way Ken Burns did for stills
/// on film. Honors Reduce Motion (then it simply doesn't move).
private struct KenBurns: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(drift ? 1.045 : 1.0)
            .offset(x: drift ? 9 : 0, y: drift ? -6 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 24).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
    }
}

extension View {
    /// Gives a hung work a slow Ken Burns drift.
    func kenBurns() -> some View { modifier(KenBurns()) }
}

/// Wraps an artwork in its frame chrome and hangs it with a shadow.
struct FramedArtworkView: View {
    @Environment(\.sditTheme) private var theme
    let artwork: Artwork

    var body: some View {
        framed
            .compositingGroup()
            .shadow(color: theme.artShadow, radius: 34, x: 0, y: 22)
    }

    @ViewBuilder
    private var framed: some View {
        let image = ArtImage(name: artwork.image)
        switch artwork.frameStyle {
        case .gilded:
            image
                .padding(3)
                .background(Color(red: 0.22, green: 0.16, blue: 0.05))
                .padding(7)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.69, blue: 0.34),
                            Color(red: 0.55, green: 0.42, blue: 0.16),
                            Color(red: 0.93, green: 0.80, blue: 0.48),
                            Color(red: 0.62, green: 0.48, blue: 0.20),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.57, blue: 0.26),
                            Color(red: 0.48, green: 0.36, blue: 0.13),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(3)
                .background(Color(red: 0.30, green: 0.22, blue: 0.08))

        case .baroque:
            // A deep, ornate Salon gold: a bright inner ogee, a dark carved
            // recess, then a broad antiqued outer course. The frame Caravaggio
            // and Sargent's Madame X would actually hang in.
            image
                .padding(3)
                .background(Color(red: 0.16, green: 0.11, blue: 0.03))
                .padding(11)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.83, blue: 0.51),
                            Color(red: 0.66, green: 0.50, blue: 0.21),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(8)
                .background(Color(red: 0.20, green: 0.14, blue: 0.05))
                .padding(22)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.80, green: 0.64, blue: 0.30),
                            Color(red: 0.50, green: 0.37, blue: 0.14),
                            Color(red: 0.88, green: 0.73, blue: 0.41),
                            Color(red: 0.56, green: 0.42, blue: 0.17),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(4)
                .background(Color(red: 0.18, green: 0.12, blue: 0.04))

        case .dutch:
            // Dutch Golden Age: an ebonized black frame with the thin gold
            // sight-line that catches the light at the picture's edge.
            image
                .padding(3)
                .background(Color(red: 0.56, green: 0.44, blue: 0.18))
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.10, blue: 0.09),
                            Color(red: 0.04, green: 0.035, blue: 0.03),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(2)
                .background(Color.black)

        case .secession:
            // Vienna Secession: a wide, flat, matte-gold frame ruled with thin
            // incised lines — the geometry Klimt and Hoffmann favored.
            image
                .padding(3)
                .background(Color(red: 0.16, green: 0.13, blue: 0.06))
                .padding(7)
                .background(Color(red: 0.79, green: 0.65, blue: 0.31))
                .padding(2)
                .background(Color(red: 0.16, green: 0.13, blue: 0.06))
                .padding(18)
                .background(Color(red: 0.84, green: 0.70, blue: 0.35))
                .padding(2)
                .background(Color(red: 0.16, green: 0.13, blue: 0.06))

        case .classic:
            image
                .padding(3)
                .background(Color(red: 0.10, green: 0.07, blue: 0.05))
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.20, blue: 0.13),
                            Color(red: 0.16, green: 0.11, blue: 0.07),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(2)
                .background(Color.black)

        case .modern:
            image
                .padding(10)
                .background(Color(white: 0.08))

        case .float:
            image
                .padding(44)
                .background(Color(red: 0.95, green: 0.93, blue: 0.88))
                .padding(8)
                .background(Color(white: 0.12))

        case .none:
            image
        }
    }
}
