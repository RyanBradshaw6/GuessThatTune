import Foundation
import AuthenticationServices
import Combine
import UIKit

final class SpotifyAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
    @Published var playlistTracks: [[String: Any]] = []
    @Published var currentYear: String = ""
    @Published var accessToken: String?
        @Published var currentTrackName: String = ""
        @Published var currentArtistName: String = ""
    @Published var artwork: UIImage? = nil
        @Published var isLoggedIn = false
    
    let playlistID = "4qLvBGBK53LJnGYh1csZYT"

    private let clientID = "bf1579a346634c0983bd210948c86cc1"
    private let redirectURI = "guessthattune://callback"

    private let scopes = "user-read-playback-state user-modify-playback-state"

    private var authSession: ASWebAuthenticationSession?

    // MARK: - Start Login

    func login() {

        let codeVerifier = PKCE.generateCodeVerifier()
        let codeChallenge = PKCE.generateCodeChallenge(from: codeVerifier)

        let state = UUID().uuidString

        let authURL = URL(string:
            "https://accounts.spotify.com/authorize" +
            "?client_id=\(clientID)" +
            "&response_type=code" +
            "&redirect_uri=\(redirectURI)" +
            "&scope=\(scopes)" +
            "&code_challenge_method=S256" +
            "&code_challenge=\(codeChallenge)" +
            "&state=\(state)"
        )!

        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "guessthattune"
        ) { callbackURL, error in

            guard let url = callbackURL else { return }

            let code = URLComponents(string: url.absoluteString)?
                .queryItems?
                .first(where: { $0.name == "code" })?
                .value

            guard let code = code else { return }

            self.exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
        }

        authSession?.presentationContextProvider = self
        authSession?.start()
    }
    
    func playRandomSong() {
        guard let token = accessToken else { return }
        guard !playlistTracks.isEmpty else { return }

        let randomItem = playlistTracks.randomElement()
        let track = randomItem?["track"] as? [String: Any]

        let name = track?["name"] as? String ?? "Unknown"

        let artists = track?["artists"] as? [[String: Any]]
        let artistName = artists?.first?["name"] as? String ?? "Unknown"

        let album = track?["album"] as? [String: Any]
        let releaseDate = album?["release_date"] as? String ?? ""

        let images = album?["images"] as? [[String: Any]]
        let imageURLString = images?.first?["url"] as? String
        if let urlString = imageURLString,
           let url = URL(string: urlString) {

            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.artwork = image
                    }
                }
            }.resume()
        }
        // 🎯 Extract year (first 4 digits)
        let year = String(releaseDate.prefix(4))

        let uri = track?["uri"] as? String ?? ""

        DispatchQueue.main.async {
            self.currentTrackName = name
            self.currentArtistName = artistName
            self.currentYear = year
        }

        startPlayback(uri: uri)
    }
    func startPlayback(uri: String) {
        guard let token = accessToken else { return }

        let url = URL(string: "https://api.spotify.com/v1/me/player/play")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "uris": [uri]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Playback error:", error)
            } else {
                print("🎵 Playing random song")
            }
        }.resume()
    }
    
    
    func openSpotifyApp() {
        if let url = URL(string: "spotify://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    

    func fetchPlaylistTracks(playlistID: String) {
        guard let token = accessToken else {
            print("❌ No access token")
            return
        }
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("❌ Network error:", error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else { return }
            print("📡 Status Code:", httpResponse.statusCode)

            guard let data = data else {
                print("❌ No data returned")
                return
            }

            let raw = String(data: data, encoding: .utf8) ?? ""
            print("📦 RAW RESPONSE:", raw)

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]] {

                DispatchQueue.main.async {
                    self.playlistTracks = items
                    print("✅ Loaded \(items.count) tracks")
                }
            } else {
                print("❌ Failed to parse playlist")
            }

        }.resume()
    }
    
    func getCurrentlyPlaying() {
            guard let token = accessToken else { return }

            let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data else { return }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let item = json["item"] as? [String: Any],
                   let name = item["name"] as? String,
                   let artists = item["artists"] as? [[String: Any]],
                   let artistName = artists.first?["name"] as? String {

                    DispatchQueue.main.async {
                        self.currentTrackName = name
                        self.currentArtistName = artistName
                    }
                }
            }.resume()
        }
    
    func play() {
        guard let token = accessToken else { return }

        let url = URL(string: "https://api.spotify.com/v1/me/player/play")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request).resume()
    }
    
    func pause() {
        guard let token = accessToken else { return }

        let url = URL(string: "https://api.spotify.com/v1/me/player/pause")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request).resume()
    }
    
    func skipNext() {
        guard let token = accessToken else { return }

        let url = URL(string: "https://api.spotify.com/v1/me/player/next")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request).resume()
    }
    

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String, codeVerifier: String) {

        let url = URL(string: "https://accounts.spotify.com/api/token")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let body = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data = data else { return }

            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

            DispatchQueue.main.async {
                self.accessToken = json?["access_token"] as? String

                print("🎉 ACCESS TOKEN:", self.accessToken ?? "nil")

                self.openSpotifyApp()   // 👈 ADD THIS LINE HERE
            }

        }.resume()
    }
}
