import SwiftUI

struct CategoryView: View {

    let categories: [Category]
    @Binding var selectedPlaylistID: String?
    @Binding var showCategories: Bool
    @Binding var showGame: Bool

    @ObservedObject var auth: SpotifyAuthManager

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        VStack {

            Text("Choose Category")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .foregroundStyle(.color)

            ScrollView {

                VStack(spacing: 16) {

                    ForEach(categories) { category in

                        Button(action: {

                            selectedPlaylistID = category.playlistID

                            auth.fetchPlaylistTracks(playlistID: category.playlistID)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                auth.playRandomSong()
                                showGame = true
                                showCategories = false
                            }

                        }) {
                            Text(category.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                                .foregroundStyle(.color.opacity(0.8))
                        }
                    }
                }
                .padding()
            }
            
            Button("Back to Home") {
                showCategories = false
            }
            .foregroundStyle(.red)
            .padding(.bottom)
        }
    }
}
