import SwiftData
import Foundation

@Model
final class Favorite {
    @Attribute(.unique) var placeId: String
    var name: String
    var address: String

    init(placeId: String, name: String, address: String) {
        self.placeId = placeId
        self.name = name
        self.address = address
    }
}
