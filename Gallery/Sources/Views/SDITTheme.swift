import SwiftUI

/// SDIT Founding Charter design tokens, one set per gallery wall.
/// Three walls: Ink (the charter navy), Charcoal (neutral dark), and
/// Stone (a muted warm grey) — chosen in Settings.
struct SDITTheme: Equatable {
    let isDark: Bool

    let canvas: Color           // the wall
    let surface: Color          // panel at rest
    let surfaceFocused: Color   // panel under focus

    let textPrimary: Color
    let textSecondary: Color
    let textMetadata: Color

    let gold: Color
    let marine: Color
    let hairline: Color

    let artShadow: Color        // shadow under hung artwork

    static let paper = Color(red: 252 / 255, green: 251 / 255, blue: 248 / 255) // #FCFBF8
    static let ink   = Color(red: 16 / 255, green: 28 / 255, blue: 44 / 255)    // #101C2C

    /// The charter navy — the gallery's signature dark wall.
    static let inkWall = SDITTheme(
        isDark: true,
        canvas: ink,
        surface: Color(red: 13 / 255, green: 24 / 255, blue: 37 / 255),          // #0D1825
        surfaceFocused: Color(red: 22 / 255, green: 36 / 255, blue: 58 / 255),   // #16243A
        textPrimary: paper.opacity(0.92),
        textSecondary: Color(red: 246 / 255, green: 245 / 255, blue: 240 / 255).opacity(0.62),
        textMetadata: paper.opacity(0.40),
        gold: Color(red: 196 / 255, green: 162 / 255, blue: 78 / 255),           // #C4A24E
        marine: Color(red: 74 / 255, green: 138 / 255, blue: 181 / 255),         // #4A8AB5
        hairline: paper.opacity(0.12),
        artShadow: Color.black.opacity(0.60)
    )

    /// A neutral near-black — the dark room without the navy cast.
    static let charcoalWall = SDITTheme(
        isDark: true,
        canvas: Color(red: 33 / 255, green: 32 / 255, blue: 30 / 255),           // #21201E
        surface: Color(red: 27 / 255, green: 26 / 255, blue: 24 / 255),          // #1B1A18
        surfaceFocused: Color(red: 45 / 255, green: 43 / 255, blue: 40 / 255),   // #2D2B28
        textPrimary: paper.opacity(0.92),
        textSecondary: Color(red: 246 / 255, green: 245 / 255, blue: 240 / 255).opacity(0.62),
        textMetadata: paper.opacity(0.40),
        gold: Color(red: 196 / 255, green: 162 / 255, blue: 78 / 255),           // #C4A24E
        marine: Color(red: 122 / 255, green: 160 / 255, blue: 185 / 255),        // #7AA0B9
        hairline: paper.opacity(0.12),
        artShadow: Color.black.opacity(0.55)
    )

    /// Pure black — the TV disappears and only the work exists.
    static let voidWall = SDITTheme(
        isDark: true,
        canvas: Color.black,
        surface: Color(white: 0.07),
        surfaceFocused: Color(white: 0.12),
        textPrimary: paper.opacity(0.90),
        textSecondary: Color(red: 246 / 255, green: 245 / 255, blue: 240 / 255).opacity(0.58),
        textMetadata: paper.opacity(0.36),
        gold: Color(red: 196 / 255, green: 162 / 255, blue: 78 / 255),
        marine: Color(red: 74 / 255, green: 138 / 255, blue: 181 / 255),
        hairline: paper.opacity(0.10),
        artShadow: Color.black.opacity(0.80)
    )

    /// A muted warm grey — the light wall, dimmed so the work carries it.
    static let stoneWall = SDITTheme(
        isDark: false,
        canvas: Color(red: 215 / 255, green: 210 / 255, blue: 199 / 255),        // #D7D2C7
        surface: Color(red: 226 / 255, green: 222 / 255, blue: 212 / 255),       // #E2DED4
        surfaceFocused: Color(red: 236 / 255, green: 232 / 255, blue: 223 / 255), // #ECE8DF
        textPrimary: ink,
        textSecondary: Color(red: 84 / 255, green: 93 / 255, blue: 106 / 255),   // #545D6A
        textMetadata: ink.opacity(0.45),
        gold: Color(red: 168 / 255, green: 132 / 255, blue: 44 / 255),           // #A8842C
        marine: Color(red: 35 / 255, green: 78 / 255, blue: 112 / 255),          // #234E70
        hairline: Color(red: 180 / 255, green: 174 / 255, blue: 161 / 255),      // #B4AEA1
        artShadow: Color.black.opacity(0.32)
    )
}

/// Resolves the chosen wall from UserDefaults ("wall": ink | charcoal |
/// stone) and crossfades the room when the choice changes.
@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var theme: SDITTheme

    private var settingsObserver: NSObjectProtocol?

    init() {
        theme = Self.resolve()
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let next = Self.resolve()
        if next != theme {
            withAnimation(.easeInOut(duration: 1.2)) { theme = next }
        }
    }

    private static func resolve() -> SDITTheme {
        switch UserDefaults.standard.string(forKey: "wall") {
        case "charcoal": return .charcoalWall
        case "stone": return .stoneWall
        case "void": return .voidWall
        default: return .inkWall
        }
    }
}

private struct SDITThemeKey: EnvironmentKey {
    static let defaultValue = SDITTheme.inkWall
}

extension EnvironmentValues {
    var sditTheme: SDITTheme {
        get { self[SDITThemeKey.self] }
        set { self[SDITThemeKey.self] = newValue }
    }
}

extension Font {
    /// EB Garamond — headings, standfirsts, CTAs.
    static func sditDisplay(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "EBGaramond-Italic" : "EBGaramond-Medium", size: size)
    }
    /// EB Garamond Regular — ledes and serif body moments.
    static func sditSerif(_ size: CGFloat) -> Font {
        .custom("EBGaramond-Regular", size: size)
    }
    /// IBM Plex Sans — all prose and UI text.
    static func sditBody(_ size: CGFloat) -> Font {
        .custom("IBMPlexSans-Regular", size: size)
    }
    /// IBM Plex Mono — ALL-CAPS labels, metadata, coordinates.
    static func sditMono(_ size: CGFloat) -> Font {
        .custom("IBMPlexMono-Regular", size: size)
    }
}

/// The brand eyebrow: mono, ALL CAPS, letterspaced, gold by default.
struct Eyebrow: View {
    @Environment(\.sditTheme) private var theme
    let text: String
    var size: CGFloat = 19
    var color: Color?

    init(_ text: String, size: CGFloat = 19, color: Color? = nil) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.sditMono(size))
            .tracking(size * 0.16)
            .foregroundStyle(color ?? theme.gold)
    }
}

/// 1px ruled line — the only border in the system.
struct HairlineRule: View {
    @Environment(\.sditTheme) private var theme
    var body: some View {
        Rectangle().fill(theme.hairline).frame(height: 1)
    }
}

/// Flat charter panel as a focusable card: hairline border at rest,
/// gold border when focused. Zero corner radius, no lift, no spring.
struct SDITCardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.sditTheme) private var theme

    /// When true the panel is invisible at rest — just a hairline —
    /// so the artwork keeps the room.
    var quiet = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isFocused ? theme.surfaceFocused : (quiet ? .clear : theme.surface))
            .overlay(
                Rectangle().strokeBorder(
                    isFocused ? theme.gold : theme.hairline,
                    lineWidth: isFocused ? 2 : 1
                )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.28), value: isFocused)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// A settings option: mono caps, gold when selected, bordered on focus.
struct SDITOptionButtonStyle: ButtonStyle {
    var isSelected: Bool
    @Environment(\.isFocused) private var isFocused
    @Environment(\.sditTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? theme.gold : (isFocused ? theme.textPrimary : theme.textSecondary))
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(isFocused ? theme.surfaceFocused : .clear)
            .overlay(
                Rectangle().strokeBorder(
                    isFocused ? theme.gold : theme.hairline,
                    lineWidth: isFocused ? 2 : 1
                )
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.28), value: isFocused)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// The charter CTA: Garamond italic over a bottom rule, gold on focus.
struct SDITCTAButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.sditTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sditDisplay(26, italic: true))
            .foregroundStyle(isFocused ? theme.gold : theme.textPrimary)
            .padding(.bottom, 5)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isFocused ? theme.gold : theme.textPrimary.opacity(0.5))
                    .frame(height: 1.5)
            }
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.28), value: isFocused)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Brand page reveal: fade in with an 8pt rise, staggerable by delay.
/// Opacity-only when Reduce Motion is on.
private struct Rise: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) { shown = true }
            }
    }
}

extension View {
    func rise(_ delay: Double = 0) -> some View { modifier(Rise(delay: delay)) }
}

/// Roman numerals for exhibition labels, per the charter's section style.
func romanNumeral(_ n: Int) -> String {
    let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    return (1...numerals.count).contains(n) ? numerals[n - 1] : "\(n)"
}
