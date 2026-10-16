import SwiftUI
import SwiftData

struct PlacesListView: View {
    let places: [Place]
    @Query private var ratings: [Rating]   // SwiftData: alle lagrede ratinger

    // Beregner snitt for et gitt sted basert på lagrede ratinger
    func avg(for placeId: String) -> Double? {
        let vals = ratings.filter { $0.placeId == placeId }.map { Double($0.value) }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0,+) / Double(vals.count)
    }

    var body: some View {
        // Viser alle steder i en liste
        List(places) { p in
            // Navigasjon til detaljvisningen for hvert sted
            NavigationLink(destination: PlaceDetailView(place: p)) {
                HStack {
                    // Navn og adresse
                    VStack(alignment: .leading) {
                        Text(p.name).bold()
                        Text(p.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // Viser gjennomsnittlig rating hvis den finnes
                    if let a = avg(for: p.id) {
                        StarFillView(fraction: a / 5.0)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        // Fjerner ekstra bakgrunn for en renere look
        .scrollContentBackground(.hidden)
    }
}

//Stjernevisning
struct StarFillView: View {
    let fraction: Double // Andel av stjernen som skal fylles (0.0–1.0)
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Tom stjerne (bakgrunn)
            Image(systemName: "star")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray.opacity(0.4))

            // Fylte stjerne (forgrunn) maskert etter fraction
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .mask(GeometryReader { geo in
                    Rectangle().frame(width: geo.size.width * fraction)
                })
                .foregroundStyle(Color(hex: "#F7853E")) // Beacon-oransje
        }
    }
}
