import SwiftUI
import UIKit

@main
struct GalleryApp: App {
    @StateObject private var store = ContentStore()
    @StateObject private var music = MusicPlayer()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(music)
                .environmentObject(settings)
                .environment(\.sditTheme, themeManager.theme)
                .preferredColorScheme(themeManager.theme.isDark ? .dark : .light)
                .task { await store.load() }
                .onAppear {
                    // Gallery acts as its own screensaver — keep the display on.
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
