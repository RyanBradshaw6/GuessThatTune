import SwiftUI

@main
struct GuessThatTuneApp: App {

    @StateObject var spotify = SpotifyAuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(spotify)
        }
    }
}
