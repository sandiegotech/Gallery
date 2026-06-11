import SwiftUI

/// The gallery's few preferences, laid out as charter spec rows.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.sditTheme) private var theme

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
            }
            .frame(maxWidth: 1300, alignment: .leading)
            .padding(.horizontal, 90)
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
