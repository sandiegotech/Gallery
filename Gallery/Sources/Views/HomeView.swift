import SwiftUI

/// The lobby: pick tonight's exhibition.
struct HomeView: View {
    @EnvironmentObject private var store: ContentStore
    @Environment(\.sditTheme) private var theme
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                WallBackground(spotlightCenter: UnitPoint(x: 0.5, y: 0.28))

                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    Text("The Gallery")
                        .font(.sditDisplay(74))
                        .foregroundStyle(theme.textPrimary)
                        .rise(0)
                    Text("A museum for your living room.")
                        .font(.sditDisplay(28, italic: true))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.top, 12)
                        .rise(0.08)

                    Group {
                        if store.collections.isEmpty {
                            if let error = store.loadError {
                                Text(error)
                                    .font(.sditMono(20))
                                    .foregroundStyle(theme.textSecondary)
                            } else {
                                ProgressView().tint(theme.textMetadata)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 44) {
                                ForEach(Array(store.collections.enumerated()), id: \.element.id) { index, collection in
                                    NavigationLink(value: collection) {
                                        CollectionCard(
                                            collection: collection,
                                            number: index + 1,
                                            cover: store.coverArtwork(for: collection)
                                        )
                                    }
                                    .buttonStyle(SDITCardButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.top, 66)
                    .rise(0.16)
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 80)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(value: "settings") {
                            Image(systemName: "gearshape")
                                .font(.system(size: 23, weight: .light))
                        }
                        .buttonStyle(SDITOptionButtonStyle(isSelected: false))
                        .padding(.trailing, 56)
                        .padding(.bottom, 40)
                        .rise(0.24)
                    }
                }
            }
            .navigationDestination(for: GalleryCollection.self) { collection in
                ExhibitionView(
                    collection: collection,
                    number: (store.collections.firstIndex(of: collection) ?? 0) + 1
                )
            }
            .navigationDestination(for: String.self) { _ in
                SettingsView()
            }
            // Debug hooks: `simctl launch ... -exhibition street` or `-openSettings YES`
            // jump straight to a screen.
            .onChange(of: store.collections) { _, collections in
                if let id = UserDefaults.standard.string(forKey: "exhibition"),
                   let match = collections.first(where: { $0.id == id }) {
                    path.append(match)
                }
                if UserDefaults.standard.bool(forKey: "openSettings") {
                    path.append("settings")
                }
            }
        }
    }
}

struct CollectionCard: View {
    @Environment(\.sditTheme) private var theme
    let collection: GalleryCollection
    let number: Int
    let cover: Artwork?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                theme.surfaceFocused
                if let cover {
                    ArtImage(name: cover.image)
                        .scaledToFill()
                }
            }
            .frame(width: 330, height: 264)
            .clipped()

            HairlineRule()

            VStack(alignment: .leading, spacing: 9) {
                Eyebrow("Exhibition \(romanNumeral(number))", size: 15)
                Text(collection.title)
                    .font(.sditDisplay(29))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(collection.subtitle)
                    .font(.sditBody(18))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(width: 330, alignment: .leading)
        }
    }
}
