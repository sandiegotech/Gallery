import SwiftUI

/// The gallery wall. By day: paper plaster, evenly lit, a breath of
/// shadow at the floor. By night: navy ink, dim, with a warm spotlight
/// falling where the artwork hangs.
struct WallBackground: View {
    @Environment(\.sditTheme) private var theme
    var spotlightCenter: UnitPoint = UnitPoint(x: 0.5, y: 0.40)

    var body: some View {
        ZStack {
            theme.canvas
            // Void wall: pure black, no overlays — the TV bezel disappears.
            if theme.canvas != .black {
                if theme.isDark {
                    LinearGradient(
                        colors: [SDITTheme.paper.opacity(0.04), .clear, Color.black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.96, blue: 0.86).opacity(0.11), .clear],
                        center: spotlightCenter,
                        startRadius: 80,
                        endRadius: 780
                    )
                } else {
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), .clear, Color(red: 0.55, green: 0.52, blue: 0.46).opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [Color.white.opacity(0.18), .clear],
                        center: spotlightCenter,
                        startRadius: 100,
                        endRadius: 820
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}
