import CoreLocation
import Combine

// Håndterer brukerens posisjon og autorisasjon (CoreLocation)
final class LocationManager: NSObject, ObservableObject {
    // Publiserte variabler gjør at SwiftUI automatisk oppdaterer visningen
    @Published var authorization: CLAuthorizationStatus   // Status for tilgang
    @Published var location: CLLocation?                  // Siste kjente posisjon

    private let manager = CLLocationManager()             // Apple sin lokasjonsbehandler

    override init() {
        self.authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self                           // Setter denne klassen som delegat
        manager.desiredAccuracy = kCLLocationAccuracyBest  // Best mulig nøyaktighet
    }

    // Ber brukeren gi tillatelse til å bruke posisjon når appen er i bruk
    func request() {
        manager.requestWhenInUseAuthorization()
    }

    // Ber om én enkelt posisjonsoppdatering (brukes når GPS-knappen trykkes)
    func locateOnce() {
        manager.requestLocation()
    }
}


extension LocationManager: CLLocationManagerDelegate {
    // Kalles automatisk når brukerens tillatelse endres
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        // Hvis tilgang er gitt → hent posisjon umiddelbart
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.requestLocation()
        }
    }

    // Kalles når en ny posisjon mottas fra CoreLocation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            // Oppdaterer på hovedtråden slik at SwiftUI reagerer korrekt
            DispatchQueue.main.async {
                self.location = loc
            }
        }
    }

    // Kalles dersom det oppstår en feil ved henting av posisjon
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
