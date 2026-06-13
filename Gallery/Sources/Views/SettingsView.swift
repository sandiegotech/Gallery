import SwiftUI

/// The gallery's few preferences, laid out as charter spec rows.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.sditTheme) private var theme
    @State private var showAbout = false
    @State private var showWineDark = false

    var body: some View {
        ZStack {
            WallBackground(spotlightCenter: UnitPoint(x: 0.5, y: 0.22))

            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.sditDisplay(58))
                    .foregroundStyle(theme.textPrimary)
                    .rise(0)
                Text("The room, kept to your liking.")
                    .font(.sditSerif(26))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, 10)
                    .rise(0.08)

                VStack(alignment: .leading, spacing: 0) {
                    SettingRow(
                        label: "Wall",
                        note: "The wall the collection hangs on.",
                        options: [("ink", "Ink"), ("charcoal", "Charcoal"), ("stone", "Stone"), ("void", "Void")],
                        selection: $settings.wall
                    )
                    SettingRow(
                        label: "Music",
                        note: "Each work's paired recording, played quietly on a loop.",
                        options: [("on", "On"), ("off", "Off")],
                        selection: musicBinding
                    )
                    SettingRow(
                        label: "Pace",
                        note: "The room moves on when each recording ends, or by the clock.",
                        options: [("0", "With the music"), ("60", "1 min"), ("300", "5 min")],
                        selection: dwellBinding
                    )
                    HairlineRule()
                }
                .padding(.top, 54)
                .rise(0.16)

                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow("For the best experience", size: 15)
                    Text("The Gallery keeps the screen awake while it's open. To stop the Apple TV's own screen saver from interrupting a long viewing, set Settings › General › Screen Saver › Start After to Never.")
                        .font(.sditBody(19))
                        .lineSpacing(4)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: 1000, alignment: .leading)
                }
                .padding(.top, 40)
                .rise(0.2)
            }
            .frame(maxWidth: 1300, alignment: .leading)
            .padding(.horizontal, 90)

            VStack(spacing: 14) {
                Spacer()
                HStack(spacing: 0) {
                    Text("Built by the ")
                        .foregroundStyle(theme.textMetadata)
                    Button { showAbout = true } label: {
                        Text("San Diego Institute of Technology")
                    }
                    .buttonStyle(SettingsLinkButtonStyle())
                }
                Button { showWineDark = true } label: {
                    Text("Wine-Dark — the exclusive imprint")
                }
                .buttonStyle(SettingsLinkButtonStyle())
                .padding(.bottom, 40)
            }
            .font(.sditMono(14))
            .tracking(1.2)
            .rise(0.24)
        }
        .fullScreenCover(isPresented: $showAbout) {
            AboutSDITView()
        }
        .fullScreenCover(isPresented: $showWineDark) {
            AboutWineDarkView()
        }
        // Debug hooks: `simctl launch ... -openSettings YES -openAbout YES`
        // (or `-openWineDark YES`).
        .onAppear {
            if UserDefaults.standard.bool(forKey: "openAbout") { showAbout = true }
            if UserDefaults.standard.bool(forKey: "openWineDark") { showWineDark = true }
        }
    }

    private var musicBinding: Binding<String> {
        Binding(
            get: { settings.musicOn ? "on" : "off" },
            set: { settings.musicOn = ($0 == "on") }
        )
    }

    private var dwellBinding: Binding<String> {
        Binding(
            get: { String(settings.dwell) },
            set: { settings.dwell = Int($0) ?? 0 }
        )
    }
}

/// A quiet footer link: brighter than its neighbors at rest, gold and
/// underlined under focus, so it reads as the one tappable word in the line.
private struct SettingsLinkButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.sditTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isFocused ? theme.gold : theme.textSecondary)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.gold)
                    .frame(height: 1)
                    .opacity(isFocused ? 1 : 0)
                    .offset(y: 4)
            }
            .animation(.easeOut(duration: 0.22), value: isFocused)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// A quick overview of the studio behind the app, reached from the Settings
/// footer. Menu or "Return" closes it.
struct AboutSDITView: View {
    @Environment(\.sditTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "The Gallery · Version \(short) (\(build))"
    }

    var body: some View {
        ZStack {
            WallBackground(spotlightCenter: UnitPoint(x: 0.3, y: 0.4))

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("About", size: 17).rise(0)
                Text("San Diego Institute of Technology")
                    .font(.sditDisplay(52))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.top, 14)
                    .rise(0.06)

                HairlineRule().padding(.vertical, 30)

                VStack(alignment: .leading, spacing: 22) {
                    Text("The San Diego Institute of Technology is a school for builders and thinkers who hold that technology should widen human attention, not harvest it — and that what a tool makes possible matters more than what it can capture.")
                    Text("Our vision is a generation fluent in both the machine and the humanities: people who read a poem and a compiler with equal care, and who build in the age of AI with judgment, restraint, and taste. We teach focus over distraction, craft over scale, and privacy and dignity as defaults rather than afterthoughts.")
                    Text("The Gallery is one expression of that philosophy — a quiet room where art and music are simply given, with no account, no feed, and no algorithm between you and the work.")
                    Text("Wine-Dark is the Institute's imprint for its rarest work — released seldom, and only to those who go looking.")
                        .foregroundStyle(theme.textSecondary)
                }
                .font(.sditBody(24))
                .lineSpacing(8)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: 1180, alignment: .leading)
                .rise(0.12)

                HairlineRule().padding(.vertical, 30)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("sandiegotech.org".uppercased())
                            .font(.sditMono(15))
                            .tracking(2)
                            .foregroundStyle(theme.gold)
                        Text(versionLine.uppercased())
                            .font(.sditMono(13))
                            .tracking(1.4)
                            .foregroundStyle(theme.textMetadata)
                    }
                    Spacer()
                    Button("Return") { dismiss() }
                        .buttonStyle(SDITCTAButtonStyle())
                }
                .frame(maxWidth: 1180, alignment: .leading)
                .rise(0.18)
            }
            .padding(.horizontal, 110)
        }
        .onExitCommand { dismiss() }
    }
}

/// What Wine-Dark is — the Institute's imprint for its rarest work. Shown
/// against its own oxblood wall, and quietly hinting that a release can be
/// found by those who go looking.
struct AboutWineDarkView: View {
    @Environment(\.dismiss) private var dismiss
    private let theme = SDITTheme.wineDarkWall

    var body: some View {
        ZStack {
            WallBackground(spotlightCenter: UnitPoint(x: 0.32, y: 0.4))

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("The Imprint", size: 17).rise(0)
                Text("Wine-Dark")
                    .font(.sditDisplay(56))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.top, 14)
                    .rise(0.06)

                HairlineRule().padding(.vertical, 30)

                VStack(alignment: .leading, spacing: 22) {
                    Text("Wine-Dark is the San Diego Institute of Technology's imprint for its rarest work — pieces released seldom, and with a little ceremony.")
                    Text("The name is Homer's. He called the sea oînops póntos, the wine-dark sea — his epithet for the deep, where the most beautiful and dangerous things are kept.")
                    Text("A Wine-Dark release is never listed and never permanent. It surfaces, it is seen, and it returns to the deep. Those who go looking sometimes find one waiting.")
                        .foregroundStyle(theme.textSecondary)
                }
                .font(.sditBody(24))
                .lineSpacing(8)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: 1180, alignment: .leading)
                .rise(0.12)

                HairlineRule().padding(.vertical, 30)

                HStack(alignment: .center) {
                    Text("San Diego Institute of Technology".uppercased())
                        .font(.sditMono(14))
                        .tracking(2)
                        .foregroundStyle(theme.gold)
                    Spacer()
                    Button("Return") { dismiss() }
                        .buttonStyle(SDITCTAButtonStyle())
                }
                .frame(maxWidth: 1180, alignment: .leading)
                .rise(0.18)
            }
            .padding(.horizontal, 110)
        }
        .environment(\.sditTheme, theme)
        .onExitCommand { dismiss() }
    }
}

private struct SettingRow: View {
    @Environment(\.sditTheme) private var theme
    let label: String
    let note: String
    let options: [(value: String, label: String)]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HairlineRule()
            HStack(alignment: .center, spacing: 40) {
                VStack(alignment: .leading, spacing: 7) {
                    Eyebrow(label, size: 17)
                    Text(note)
                        .font(.sditBody(18))
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(width: 520, alignment: .leading)

                Spacer(minLength: 0)

                HStack(spacing: 14) {
                    ForEach(options, id: \.value) { option in
                        Button {
                            selection = option.value
                        } label: {
                            Text(option.label.uppercased())
                                .font(.sditMono(17))
                                .tracking(2.2)
                                .lineLimit(1)
                        }
                        .buttonStyle(SDITOptionButtonStyle(isSelected: selection == option.value))
                    }
                }
            }
            .padding(.vertical, 28)
        }
    }
}
