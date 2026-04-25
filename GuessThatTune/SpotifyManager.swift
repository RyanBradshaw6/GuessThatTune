import Foundation
import SpotifyiOS
import UIKit
import Combine
class SpotifyManager: NSObject, ObservableObject {

    // MARK: UI State
    @Published var isConnected = false
    @Published var trackName = ""
    @Published var artwork: UIImage?
    @Published var isPaused = true

    // MARK: Config (IMPORTANT: must match plist + Spotify dashboard)
    private let clientID = "YOUR_CLIENT_ID"
    private let redirectURI = URL(string: "guessthattune://callback")!

    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURI)
        config.playURI = ""
        return config
    }()

    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        return remote
    }()

    lazy var sessionManager: SPTSessionManager = {
        SPTSessionManager(configuration: configuration, delegate: self)
    }()

    // MARK: Connect
    func connect() {
        let scopes: SPTScope = [
            .appRemoteControl,
            .userReadPlaybackState,
            .userModifyPlaybackState
            
        ]

        sessionManager.initiateSession(
            with: scopes,
            options: .default,
            campaign: nil
        )
    }

    func disconnect() {
        appRemote.disconnect()
        isConnected = false
    }

    func togglePlayPause() {
        if isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }
}

// MARK: - Session Delegate
extension SpotifyManager: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Session started")

        DispatchQueue.main.async {
            self.appRemote.connectionParameters.accessToken = session.accessToken

            // small delay prevents race condition with Spotify app switching
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.appRemote.connect()
            }
        }
    }
    

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Session failed:", error.localizedDescription)
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {}
}

// MARK: - App Remote Delegate
extension SpotifyManager: SPTAppRemoteDelegate {

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("✅ Spotify connected")

        DispatchQueue.main.async {
            self.isConnected = true
        }

        appRemote.playerAPI?.delegate = self

        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("Subscribe error:", error.localizedDescription)
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected")
        DispatchQueue.main.async { self.isConnected = false }
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Connection failed:", error?.localizedDescription ?? "nil")
    }
}

// MARK: - Player State
extension SpotifyManager: SPTAppRemotePlayerStateDelegate {

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {

        DispatchQueue.main.async {
            self.trackName = playerState.track.name
            self.isPaused = playerState.isPaused
        }

        appRemote.imageAPI?.fetchImage(forItem: playerState.track, with: .zero) { image, _ in
            if let img = image as? UIImage {
                DispatchQueue.main.async {
                    self.artwork = img
                }
            }
        }
    }
}
