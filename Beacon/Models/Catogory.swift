import Foundation

enum Category: String, CaseIterable, Identifiable {
    case restaurant, cafe, hotel
    var id: String { rawValue }
    var titleNO: String {
        switch self {
        case .restaurant: return "Restauranter"
        case .cafe:       return "Kafeer"
        case .hotel:      return "Hoteller"
        }
    }
    // Map til Geoapify categories-parameter (forenklet)
    var geoapifyKey: String {
        switch self {
        case .restaurant: return "catering.restaurant"
        case .cafe:       return "catering.cafe"
        case .hotel:      return "accommodation.hotel"
        }
    }
    var emoji: String {
        switch self {
        case .restaurant: return "🍽"
        case .cafe:       return "☕"
        case .hotel:      return "🏨"
        }
    }
}
