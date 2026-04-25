import UIKit
import SpotifyiOS

class AppDelegate: NSObject, UIApplicationDelegate {

    var spotifyManager: SpotifyManager?

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        print("🔥 APP DELEGATE HIT:", url.absoluteString)

        return spotifyManager?.sessionManager.application(
            app,
            open: url,
            options: options
        ) ?? false
    }
}
