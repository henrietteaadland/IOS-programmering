import SwiftUI
import SwiftData

struct MineStederView: View {
    @Query private var favorites: [Favorite]

    var body: some View {
        NavigationStack {
            List(favorites, id: \.placeId) { fav in
                VStack(alignment: .leading) {
                    Text(fav.name).bold()
                    Text(fav.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Mine steder")
        }
    }
}
