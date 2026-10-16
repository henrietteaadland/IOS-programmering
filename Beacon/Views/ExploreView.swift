import SwiftUI
import MapKit
import SwiftData

struct ExploreView: View {
    @StateObject var vm: PlacesViewModel           // ViewModel som henter data fra Geoapify API
    @StateObject var loc = LocationManager()       // Håndterer brukerens posisjon (CoreLocation)
    @Environment(\.modelContext) private var context
    @Query private var favorites: [Favorite]       // SwiftData: lagrede favoritter
    @Query private var ratings: [Rating]           // SwiftData: lagrede ratinger

    // Standard kartposisjon: Oslo sentrum
    @State private var mapPos: MapCameraPosition = .region(
        MKCoordinateRegion(center: .init(latitude: 59.9111, longitude: 10.7503),
                           span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08))
    )

    @State private var showLocationAlert = false
    @State private var showOnlyFavorites = false   // Filter for bare favorittsteder
    @State private var sortMode: PlacesViewModel.Sort = .distance // Sorteringsvalg

    var body: some View {
        ZStack(alignment: .top) {
            mapOrList        // Kart eller liste
            overlayControls  // Kontrollpanel øverst
        }
        .onAppear {
            // Sjekker om vi har en gyldig lagret posisjon – hvis ikke: Oslo
            let defaultCenter = CLLocationCoordinate2D(latitude: 59.9111, longitude: 10.7503)
            let current = (vm.center.latitude == 0 && vm.center.longitude == 0) ? defaultCenter : vm.center
            
            // Setter startposisjon og henter data
            mapPos = .region(MKCoordinateRegion(center: current,
                                                span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)))
            vm.fetch()
        }
        // Når brukeren gir posisjonstillatelse
        .onChange(of: loc.authorization) { _, newAuth in
            if newAuth == .authorizedWhenInUse || newAuth == .authorizedAlways {
                loc.locateOnce()
            }
        }
        // Når posisjonen faktisk endres → flytt kartet og hent nye data
        .onChange(of: loc.location) { _, newLocation in
            guard let c = newLocation?.coordinate else { return }
            withAnimation {
                mapPos = .region(MKCoordinateRegion(center: c,
                                                    span: .init(latitudeDelta: 0.06, longitudeDelta: 0.06)))
            }
            vm.updateCenter(c)
            vm.fetch()
        }
        // Når radius endres → oppdater API-søk
        .onChange(of: vm.radiusKm) { _, _ in
            vm.fetch()
        }
        // Zoom automatisk inn når nye steder lastes
        .onChange(of: vm.places) { _, newPlaces in
            guard let first = newPlaces.first else { return }
            withAnimation {
                mapPos = .region(MKCoordinateRegion(center: first.coordinate,
                                                    span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)))
            }
        }
        // Varsel hvis posisjon er avslått
        .alert("Posisjon er avslått",
               isPresented: $showLocationAlert,
               actions: { Button("OK", role: .cancel) {} },
               message: { Text("Skru på posisjonstilgang i Innstillinger for å bruke GPS-knappen.") })
    }

    // Kart eller liste
    @ViewBuilder
    private var mapOrList: some View {
        // Filtrerer basert på favoritter
        let filtered = showOnlyFavorites
            ? vm.places.filter { p in favorites.contains(where: { $0.placeId == p.id }) }
            : vm.places

        // Sorterer basert på valgt sorteringsmodus
        let sorted: [Place] = {
            switch sortMode {
            case .alphabetical:
                return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .rating:
                return filtered.sorted { avg(for: $0.id) > avg(for: $1.id) }
            case .distance:
                let center = CLLocation(latitude: vm.center.latitude, longitude: vm.center.longitude)
                func dist(_ p: Place) -> CLLocationDistance {
                    CLLocation(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)
                        .distance(from: center)
                }
                return filtered.sorted { dist($0) < dist($1) }
            }
        }()

        // Listevisning
        if vm.showList {
            PlacesListView(places: sorted)
                .refreshable { vm.fetch() }     // Dra ned for å hente nye data
                .padding(.top, 280)             // Hindrer at listen havner bak kontrollpanelet
        } else {
            // Kartvisning
            Map(position: $mapPos) {
                // Brukerens posisjon
                if let user = loc.location?.coordinate {
                    Annotation("Meg", coordinate: user) {
                        ZStack {
                            Circle().fill(.white).frame(width: 14, height: 14)
                            Circle().fill(.blue).frame(width: 10, height: 10)
                        }
                        .shadow(radius: 2)
                    }
                }

                // Steder hentet fra Geoapify
                ForEach(sorted) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        VStack(spacing: 2) {
                            Text(place.category.emoji)
                            Circle()
                                .fill(Color(hex: "#FF9B52"))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            // Oppdaterer sentrum når kartet panoreres
            .onMapCameraChange { ctx in vm.updateCenter(ctx.region.center) }
            // GPS-knapp nederst til høyre
            .overlay(alignment: .bottomTrailing) {
                Button {
                    switch loc.authorization {
                    case .notDetermined:
                        loc.request()
                    case .denied, .restricted:
                        showLocationAlert = true
                    case .authorizedWhenInUse, .authorizedAlways:
                        loc.locateOnce()
                    @unknown default:
                        break
                    }
                } label: {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 28))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding()
            }
        }
    }

    // Kontrollpanel (filtrering, radius, sortering)
    private var overlayControls: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Kategori", selection: $vm.category) {
                    ForEach(Category.allCases) { c in
                        Text(c.titleNO).tag(c)
                    }
                }
                .pickerStyle(.segmented)

                Button("Hent steder") { vm.fetch() }
                    .buttonStyle(.borderedProminent)
            }

            HStack {
                TextField("Søk etter sted...", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                Toggle("Liste", isOn: $vm.showList).labelsHidden()
                Button("Nullstill") {
                    vm.category = .restaurant
                    vm.radiusKm = 5
                    vm.query = ""
                    sortMode = .distance
                    showOnlyFavorites = false
                    vm.fetch()
                }
                .font(.caption)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }

            HStack {
                Text("Radius: \(Int(vm.radiusKm)) km")
                Slider(value: $vm.radiusKm, in: 1...10, step: 1)
            }

            HStack {
                Picker("Sorter etter", selection: $sortMode) {
                    Text("Avstand").tag(PlacesViewModel.Sort.distance)
                    Text("Alfabetisk").tag(PlacesViewModel.Sort.alphabetical)
                    Text("Rating").tag(PlacesViewModel.Sort.rating)
                }
                .pickerStyle(.menu)

                Toggle("Bare favoritter", isOn: $showOnlyFavorites)
                    .font(.caption)
            }

            if vm.isLoading {
                ProgressView().padding(.top, 4)
            }

            if let e = vm.error {
                Text(e)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding()
        .frame(maxHeight: 270)
    }

    // Beregner gjennomsnittsrating
    func avg(for placeId: String) -> Double {
        let vals = ratings.filter { $0.placeId == placeId }.map { Double($0.value) }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
}
