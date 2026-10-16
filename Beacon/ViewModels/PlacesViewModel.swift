import SwiftUI
import Combine
import CoreLocation
import SwiftData

// ViewModel som håndterer dataflyten mellom Geoapify API og brukergrensesnittet.
@MainActor
final class PlacesViewModel: ObservableObject {
    // Lagrede verdier (AppStorage)
    // AppStorage husker siste posisjon og radius mellom appstarter
    @AppStorage("center_lat") var centerLat: Double = 59.9111
    @AppStorage("center_lon") var centerLon: Double = 10.7503
    @AppStorage("radius_km") var radiusKm: Double = 5.0

    // Publiserte verdier (UI oppdateres automatisk)
    @Published var category: Category = .restaurant
    @Published var places: [Place] = []      // Steder hentet fra Geoapify
    @Published var isLoading = false         // Viser ProgressView
    @Published var error: String?            // Feilmeldinger til UI
    @Published var query: String = ""        // Søkestreng fra bruker
    @Published var showList = false          // Bytte mellom kart og liste

    // Interne verdier
    private let client: GeoapifyClient
    private var cancellables = Set<AnyCancellable>()

    // Init
    init(client: GeoapifyClient) {
        self.client = client

        // Automatisk API-kall når søketeksten endres
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.fetch() }
            .store(in: &cancellables)

        // Automatisk oppdatering når kategori endres
        $category
            .sink { [weak self] _ in self?.fetch() }
            .store(in: &cancellables)
    }

    // Kartets sentrum (med fallback til Oslo)
    var center: CLLocationCoordinate2D {
        // Hvis lagrede verdier er (0,0) → bruk Oslo sentrum
        if centerLat == 0 && centerLon == 0 {
            return CLLocationCoordinate2D(latitude: 59.9111, longitude: 10.7503)
        }
        return CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
    }

    // Oppdaterer sentrum – men lagrer ikke ugyldige koordinater
    func updateCenter(_ c: CLLocationCoordinate2D) {
        guard c.latitude != 0 && c.longitude != 0 else { return }
        centerLat = c.latitude
        centerLon = c.longitude
    }

    // Henter steder fra API
    func fetch(limit: Int = 10) {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                // API-kall for å hente steder i nærheten av valgt posisjon
                let result = try await client.nearby(
                    center: center,
                    category: category,
                    radiusMeters: Int(radiusKm * 1000),
                    limit: limit,
                    textQuery: query
                )

                places = result
                print("✅ Fikk \(places.count) steder fra Geoapify.")
                error = nil
            } catch {
                print("❌ Feil ved henting av steder:", error.localizedDescription)
                self.error = "Klarte ikke å hente steder. Prøv igjen senere."
            }
        }
    }
}

// Sorteringsalternativer
extension PlacesViewModel {
    enum Sort {
        case distance       // Etter avstand fra brukeren
        case alphabetical   // Etter navn
        case rating         // Etter vurdering
    }
}
