import SwiftData
import Foundation

@Model
final class Rating {
    @Attribute(.unique) var id: UUID = UUID()
    var placeId: String
    var value: Int         // 1...5
    var createdAt: Date

    init(placeId: String, value: Int, createdAt: Date = .now) {
        self.placeId = placeId
        self.value = value
        self.createdAt = createdAt
    }
}

