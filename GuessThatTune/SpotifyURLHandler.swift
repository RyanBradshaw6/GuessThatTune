import UIKit
import SpotifyiOS

final class SpotifyURLHandler {
    static let shared = SpotifyURLHandler()
    
    func handle(_ url: URL, spotifyManager: SpotifyManager) -> Bool {
        return spotifyManager.sessionManager.application(
            UIApplication.shared,
            open: url,
            options: [:]
        )
    }

}
