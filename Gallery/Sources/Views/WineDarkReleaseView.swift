import SwiftUI

/// The exclusive Wine-Dark release — not another gallery room, but a single
/// ceremonial moment. A hero work surfaces from a wine-dark deep, with a line
/// of Homer, the sea's own music, and a one-of-one dedication. It is meant to
/// be seen once: when it closes, the lobby forgets the door was ever there.
struct WineDarkReleaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var music: MusicPlayer
    let artwork: Artwork?

    private static let gold = Color(red: 0.84, green: 0.70, blue: 0.37)
    private static let rose = Color(red: 0.87, green: 0.65, blue: 0.69)

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                Text("the wine-dark sea")
                    .font(.sditDisplay(42, italic: true))
                    .foregroundStyle(Self.rose)
                    .rise(0.3)
                Text("Homer's name for the deep")
                    .font(.sditMono(14))
                    .tracking(3.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.gold.opacity(0.8))
                    .padding(.top, 13)
                    .rise(0.7)

                if let artwork {
                    ArtImage(name: artwork.image)
                        .scaledToFit()
                        .frame(maxHeight: 470)
                        .shadow(color: .black.opacity(0.65), radius: 54, y: 26)
                        .kenBurns()
                        .padding(.top, 30)
                        .rise(1.4)
                }

                Spacer(minLength: 22)

                dedication.rise(2.5)

                Spacer(minLength: 26)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 130)
        }
        .onAppear { music.play(artwork?.music) }
        .onDisappear { music.fadeOutAndStop() }
        .onExitCommand { dismiss() }
    }

    private var dedication: some View {
        VStack(spacing: 13) {
            seal
            Text("An exclusive release · Nº 001")
                .font(.sditMono(14))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Self.gold)
            Text("When you leave, it returns to the deep.")
                .font(.sditDisplay(23, italic: true))
                .foregroundStyle(SDITTheme.paper.opacity(0.88))
            Text("Press Menu to close")
                .font(.sditMono(12))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(SDITTheme.paper.opacity(0.32))
                .padding(.top, 6)
        }
    }

    private var seal: some View {
        ZStack {
            Circle().fill(Self.gold.opacity(0.14))
            Circle().strokeBorder(Self.gold, lineWidth: 2)
            Text("✦")
                .font(.system(size: 26))
                .foregroundStyle(Self.gold)
        }
        .frame(width: 58, height: 58)
    }

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.05, blue: 0.10),
                    Color(red: 0.09, green: 0.02, blue: 0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 0.42, green: 0.12, blue: 0.20).opacity(0.55), .clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 60,
                endRadius: 900
            )
            // A deepening at the floor, like water below.
            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
