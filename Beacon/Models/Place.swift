import Foundation
import CoreLocation

struct Place: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let category: Category
    let openingHours: String?
    let phone: String?

    // Custom Equatable (sammenligner id og koordinater)
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    // Hashable for bruk i ForEach og Set
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}
