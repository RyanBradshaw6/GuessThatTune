import SwiftUI

struct ContentView: View {
    
    @State private var showCategories = false
    @State private var selectedPlaylistID: String?
    @EnvironmentObject var auth: SpotifyAuthManager
    @State private var isRocking = false
    @State private var showGame = false
    @State private var isAnimating = false
    @State private var rotatingAngle = 0.0
    @State private var showTutorial = false
    @State private var showMenu = false
    
    
    let categories = [
        Category(name: "Rock", playlistID: "61jNo7WKLOIQkahju8i0hw"),
        Category(name: "Metal", playlistID: "1yMlpNGEpIVUIilZlrbdS0"),
        Category(name: "Hip-Hop", playlistID: "29S1jCDVUgUlF4baQA7wxB"),
        Category(name: "Jazz", playlistID: "6ylvGA8NeX2CuaeGtwHWDJ"),
        Category(name: "Pop", playlistID: "2OFfgjs6kj0eA6FNayhAAJ"),
        Category(name: "60s", playlistID: "56mhesd8bUeUOJeLQ1MCfD"),
        Category(name: "70s", playlistID: "1JScFG4mGFBcYOkNtJpaHp"),
        Category(name: "80s", playlistID: "19PgP2QSGPcm6Ve8VhbtpG"),
        Category(name: "90s", playlistID: "3C64V048fGyQfCjmu9TIGA"),
        Category(name: "2000s", playlistID: "6dgEU1wVuB6nyY0ArmniXC"),
        Category(name: "2010s", playlistID: "67Xzz1bAstFPquDMzMiIKi"),
        Category(name: "Dev's Playlist", playlistID: "0sTpwD8nIpirNZOvGbp4Sx")
    ]
    
    
    var body: some View {
        
        ZStack(alignment: .topTrailing){
            VStack(spacing: 30) {
                
                // MARK: NOT LOGGED IN
                if auth.accessToken == nil {
                    
                    Text("Guess That Tune!")
                        .font(.largeTitle)
                        .foregroundStyle(.color)
                        .fontWeight(.black)
                    
                    Button("Login with Spotify") {
                        auth.login()
                    }
                    .foregroundStyle(.green.opacity(0.8))
                }
                else {
                    
                    if showCategories {
                        CategoryView(
                            categories: categories,
                            selectedPlaylistID: $selectedPlaylistID,
                            showCategories: $showCategories,
                            showGame: $showGame,
                            auth: auth
                        )
                    }
                    
                    else if showGame {
                        GuessView(auth: auth, showGame: $showGame)
                    }
                    // MARK: HOME SCREEN (POST LOGIN)
                    
                    else {
                        
                        if showGame {
                            GuessView(auth: auth, showGame: $showGame)
                        } else {
                            
                            Spacer()
                            
                            Image("GuessThatIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                                .animation(
                                    .easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                                .onAppear {
                                    showMenu = true
                                    isAnimating = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                        isAnimating = true
                                    }
                                    
                                }
                            Text("Guess That Tune!")
                                .font(.largeTitle)
                                .foregroundStyle(.color)
                                .fontWeight(.black)
                            Spacer()
                            
                            // buttons...
                            
                            
                            
                            // QUICK PLAY (FUNCTIONAL)
                            Button(action: {
                                auth.fetchPlaylistTracks(playlistID: "4qLvBGBK53LJnGYh1csZYT")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    auth.playRandomSong()
                                    showGame = true
                                }
                            }) {
                                Text("Quick Play")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.color.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            // CATEGORY CHOOSER (PLACEHOLDER)
                            Button("Category Chooser") {
                                showCategories = true
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                            .foregroundStyle(.color.opacity(0.8))
                            
                            // FAVORITES (PLACEHOLDER)
                            //                        Button("Favorites") {
                            ////                            // TODO later
                            ////                        }
                            //                        .font(.headline)
                            //                        .frame(maxWidth: .infinity)
                            //                        .padding()
                            //                        .background(Color.gray.opacity(0.3))
                            //                        .cornerRadius(12)
                            //                        .foregroundStyle(.color.opacity(0.8))
                            
                            
                            Spacer()
                        }
                    }
                }
            }
            if showMenu && !showGame && !showCategories{
                Button(action: {
                    showTutorial = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .padding()
                        .foregroundStyle(.color)
                }
            }
        }
        
        .sheet(isPresented: $showTutorial) {
            
            ScrollView {
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("How to Play")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("🎮 GAME OVERVIEW")
                        .font(.headline)
                    
                    Text("""
                    Guess That Tune is a music guessing game where you test your knowledge of artists and their biggest hits!
                    """)
                    
                    Text("🎵 QUICK PLAY")
                        .font(.headline)
                    
                    Text("""
                    Starts a random song from a list of the world's greates hits.
                    """)
                    
                    Text("🎯 HOW TO PLAY")
                        .font(.headline)
                    
                    Text("""
                    • Listen to the song  
                    • Guess the artist name  
                    • Submit your answer  
                    """)
                    
                    Text("❤️ LIVES & SCORING")
                        .font(.headline)
                    
                    Text("""
                    • You start with 3 lives  
                    • Correct answer = +1 point  
                    • Wrong answer = lose a life  
                    """)
                    
                    Text("🏆 HIGH SCORE")
                        .font(.headline)
                    
                    Text("""
                    Try to beat your best score across all games!
                    """)
                    
                    Text("🚨 IMPORTANT DIRECTION")
                        .font(.headline)
                    Text("""
                    When Spotify opens, make sure you start playing a song, this will ensure the playback work as intended.
                    """)
                    Image("GuessThatIcon")
                        .resizable()
                        .scaledToFit()

                    
                }
                .padding()
                .padding(.top, 10)
                
            }
        }
    }
}
