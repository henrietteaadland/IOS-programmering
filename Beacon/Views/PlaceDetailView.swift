import SwiftUI
import MapKit
import SwiftData

struct PlaceDetailView: View {
    let place: Place

    // Animasjonsstyring for de tre typene steder
    @State private var rotate = false
    @State private var bounce = false
    @State private var steam = false

    // SwiftData-kontekst og spørringer
    @Environment(\.modelContext) private var context
    @Query private var favorites: [Favorite]   // Alle lagrede favoritter
    @Query private var ratings: [Rating]       // Alle lagrede vurderinger

    // Sjekker om stedet allerede er lagret som favoritt
    var isFavorite: Bool {
        favorites.contains(where: { $0.placeId == place.id })
    }

    // Beregner gjennomsnittsrating for stedet fra alle SwiftData-lagringer
    var averageRating: Double? {
        let values = ratings.filter { $0.placeId == place.id }.map { Double($0.value) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Viser riktig animasjon basert på stedets kategori
                headerAnimation.frame(height: 80)

                //  Navn og adresse
                Text(place.name)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(place.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                //  Viser gjennomsnittsrating (leses fra SwiftData)
                if let avg = averageRating {
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f", avg))
                            .font(.headline)
                        StarRowView(rating: .constant(Int(round(avg))), interactive: false)
                    }
                } else {
                    Text("Ingen vurderinger enda")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Legg til ny rating (skrives til SwiftData)
                VStack(spacing: 6) {
                    Text("Gi en vurdering")
                        .font(.subheadline)
                    StarRowView(rating: .init(
                        get: { 0 },
                        set: { newValue in
                            // Oppretter ny rating og lagrer i SwiftData
                            let r = Rating(placeId: place.id, value: newValue)
                            context.insert(r)
                            try? context.save()
                        }
                    ), interactive: true)
                }

                //  Ekstrainfo om stedet
                if let phone = place.phone { Label(phone, systemImage: "phone") }
                if let oh = place.openingHours { Label(oh, systemImage: "clock") }

                // Favoritt-knapp (SwiftData-lagring)
                Button {
                    if let fav = favorites.first(where: { $0.placeId == place.id }) {
                        // Fjerner fra SwiftData hvis allerede lagret
                        context.delete(fav)
                    } else {
                        // Lagrer nytt favorittsted
                        context.insert(Favorite(placeId: place.id, name: place.name, address: place.address))
                    }
                    try? context.save()
                } label: {
                    Label(isFavorite ? "Fjern fra favoritter" : "Legg til favoritt",
                          systemImage: isFavorite ? "star.fill" : "star")
                        .font(.headline)
                        .foregroundColor(isFavorite ? .yellow : .blue)
                }
                .buttonStyle(.bordered)

                // Åpne stedet i Apple Maps
                Button("Åpne i Apple Maps") {
                    let item = MKMapItem(placemark: .init(coordinate: place.coordinate))
                    item.name = place.name
                    item.openInMaps()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FF9B52"))
            }
            .padding()
        }
        .navigationTitle(place.category.titleNO)
        .navigationBarTitleDisplayMode(.inline)
        // Starter riktig animasjon når visningen dukker opp
        .onAppear {
            switch place.category {
            case .restaurant:
                withAnimation(.easeInOut(duration: 1)) { rotate = true }
            case .cafe:
                withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) { steam = true }
            case .hotel:
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { bounce = true }
            }
        }
    }


    @ViewBuilder
    private var headerAnimation: some View {
        switch place.category {
        case .restaurant:
            // Tallerkenen roterer 360 grader i loop
            Text("🍽")
                .font(.system(size: 60))
                .rotationEffect(.degrees(rotate ? 360 : 0))
                // .repeatForever: kjører kontinuerlig uten stopp
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: rotate)

        case .cafe:
            // Kaffekoppen slipper ut tre "røyk"-ikoner som beveger seg opp og forsvinner
            ZStack {
                Text("☕").font(.system(size: 60))
                ForEach(0..<3) { i in
                    Text("💨") // Røyk
                        .offset(y: steam ? -60 : 10) // Flytter røyk oppover
                        .opacity(steam ? 0 : 1)       // Fader ut mens den stiger
                        .animation(
                            .easeOut(duration: 1)
                                .delay(Double(i) * 0.2) // Starter litt senere for hver røyk
                                .repeatForever(autoreverses: false),
                            value: steam
                        )
                }
            }

        case .hotel:
            //Hotellet spretter opp og ned som en bounce
            Text("🏨")
                .font(.system(size: 60))
                .scaleEffect(bounce ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(), value: bounce)
        }
    }
}


struct StarRowView: View {
    @Binding var rating: Int // 0...5
    var interactive = true   // Hvis true → brukeren kan trykke

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    // Bruker Beacon-oransje farge på fylte stjerner
                    .foregroundStyle(i <= rating ? Color(hex: "#F7853E") : .gray.opacity(0.4))
                    .onTapGesture {
                        guard interactive else { return }
                        // Lagrer valgt rating (oppdaterer bindingen)
                        rating = i
                    }
            }
        }
    }
}
