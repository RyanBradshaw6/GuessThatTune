import SwiftUI

struct GuessView: View {

    @ObservedObject var auth: SpotifyAuthManager
    @Binding var showGame: Bool
    @State private var hasStartedGame = false

    // MARK: - Game State
    @State private var artistGuess = ""
    @State private var highScore = UserDefaults.standard.integer(forKey: "highScore")
    @State private var shouldShowArtwork = false
    @State private var decadeGuess: Double = 2000
    @FocusState private var isArtistFieldFocused: Bool
    @State private var showAnswer = false
    @State private var showGameOver = false
    @State private var isAnimating = false

    @State private var lastWasCorrect: Bool? = nil
    @State private var lives = 3
    @State private var score = 0
    @State private var canSubmit = true
@State private var isFlipped = false
    var body: some View {
        if !hasStartedGame {

            VStack(spacing: 20) {
                Spacer()
                Text("Ready to Play?")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.color)
                

                Button("Start Game") {

                    hasStartedGame = true

                    artistGuess = ""
                    decadeGuess = 2000
                    showAnswer = false
                    lastWasCorrect = nil

                    auth.playRandomSong()
                }
                .buttonStyle(.borderedProminent)
                .tint(.color)
                Spacer()
            }

            Spacer()
        } else {
            VStack(spacing: 20) {
                
                // MARK: - GAME OVER SCREEN
                if showGameOver {
                    
                    VStack(spacing: 20) {
                        
                        Text("Game Over 💀")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Final Score: \(score)")
                            .font(.title2)
                        
                        Text("High Score: \(highScore)")
                        
                        if score >= highScore {
                            Text("New High Score!")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                        
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
                                isAnimating = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                    isAnimating = true
                                }
                                
                            }
                        
                        Button("Start Again") {

                            // GAME STATS
                            lives = 3
                            score = 0
                            showGameOver = false

                            // ROUND STATE
                            showAnswer = false
                            lastWasCorrect = nil
                            canSubmit = true

                            // INPUT RESET
                            artistGuess = ""
                            decadeGuess = 2000

                            // 🔥 FLIP BACK IMAGE
                            withAnimation {
                                isFlipped = false
                            }

                            // 🎵 START NEW ROUND
                            auth.playRandomSong()
                        }
                        .tint(.color)
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }
                
                // MARK: - NORMAL GAME UI
                else {
                    
                    // TOP HUD (lives + score)
                    HStack {
                        
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < lives ? "heart.fill" : "heart")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Score: \(score)")
                                .font(.headline)

                            Text("High Score: \(highScore)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                    }
                    .padding(.horizontal)
                    
                    Text("Guess the Artist")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.color)
                    
                    // ARTIST GUESS
                    TextField("Guess artist", text: $artistGuess)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .focused($isArtistFieldFocused)
                    
                    // DECADE SLIDER
//                    VStack {
//                        Text("Guess decade: \(Int(decadeGuess))")
//
//                        Slider(value: $decadeGuess, in: 1960...2020, step: 10)
//                            .padding(.horizontal)
//                    }
                    
                    // SUBMIT BUTTON
                    ZStack {

                        // FRONT (placeholder)
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                            .opacity(isFlipped ? 0 : 1)

                        // BACK (album art) — only allowed AFTER submit
                        if shouldShowArtwork, let image = auth.artwork {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .opacity(isFlipped ? 1 : 0)
                        }
                    }
                 
                    .frame(height: 200)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.easeInOut(duration: 0.6), value: isFlipped)


                    Button("Submit Guess") {
                        
                        isArtistFieldFocused = false   // 🔥 hides keyboard
                        
                        let correctArtist = auth.currentArtistName
                            .lowercased()
                            .trimmingCharacters(in: .whitespaces)
                        
                        let userArtist = artistGuess
                            .lowercased()
                            .trimmingCharacters(in: .whitespaces)
                        
                        let isCorrect = (userArtist == correctArtist)
                        
                        lastWasCorrect = isCorrect
                        
                        if isCorrect {
                            score += 1
                            
                            if score > highScore {
                                highScore = score
                                UserDefaults.standard.set(highScore, forKey: "highScore")
                            }
                        } else {
                            lives -= 1
                        }


                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            shouldShowArtwork = true
                            withAnimation{
                                isFlipped = true
                            }
                        }
                        showAnswer = true
                        canSubmit = false
                        
                        if lives <= 0 {
                            showGameOver = true
                        }
                    }
                    .disabled(!canSubmit)   // 🔥 disables button
                    .opacity(canSubmit ? 1.0 : 0.4)  // makes it look greyed out
                    .buttonStyle(.borderedProminent)
                    .tint(.color)
                    
                    // ANSWER REVEAL
                    if showAnswer {
                        
                        Divider()
                        if let result = lastWasCorrect {
                            
                            Text(result ? "Correct ✅" : "Incorrect ❌")
                                .font(.headline)
                                .foregroundColor(result ? .green : .red)
                                .padding(.vertical, 5)
                        }
                        Text("Answer")
                            .font(.headline)
                        
                        Text("Song: \(auth.currentTrackName)")
                        Text("Artist: \(auth.currentArtistName)")
                        Text("Year: \(auth.currentYear)")
                        
                        Button("Next Song") {
                            shouldShowArtwork = false
                            withAnimation {
                                isFlipped = false
                            }
                            
                            artistGuess = ""
                            decadeGuess = 2000
                            showAnswer = false
                            lastWasCorrect = nil
                            
                            canSubmit = true   // 🔥 re-enable submit for new round
                           
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                auth.playRandomSong()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.color)
                    }
                    
                    Spacer()
                    
                    // BACK BUTTON
                    Button("Back to Home") {
                        showGame = false
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
