import Foundation
import CoreLocation

struct GeoapifyClient {
    let apiKey: String

    //Responsretur
    struct Response: Decodable {
        let features: [Feature]
        
        struct Feature: Decodable {
            let properties: Properties
            let geometry: Geometry
        }
        
        struct Properties: Decodable {
            let place_id: String
            let name: String?
            let address_line2: String?
            let opening_hours: String?
            let contact: Contact?
            let categories: [String]?
            
            struct Contact: Decodable {
                let phone: String?
            }
        }
        
        struct Geometry: Decodable {
            let coordinates: [Double]
        }
    }

  //Henter steder i nærheten av API
    func nearby(
        center: CLLocationCoordinate2D,
        category: Category,
        radiusMeters: Int = 5000,
        limit: Int = 10,
        textQuery: String? = nil
    ) async throws -> [Place] {
        
        // Setter opp API-endepunktet og query-parametere
        var comps = URLComponents(string: "https://api.geoapify.com/v2/places")!
        comps.queryItems = [
            .init(name: "categories", value: category.geoapifyKey),
            .init(name: "filter", value: "circle:\(center.longitude),\(center.latitude),\(radiusMeters)"),
            .init(name: "limit", value: "\(limit)"),
            .init(name: "apiKey", value: apiKey)
        ]
        
        // Legger til søketekst hvis brukeren har skrevet noe
        if let textQuery, !textQuery.isEmpty {
            comps.queryItems?.append(.init(name: "name", value: textQuery))
        }

        // Utfører HTTP-kallet asynkront
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        
        // Sjekker at responsen fra serveren er OK (statuskode 200)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Dekoder JSON-responsen til Swift-strukturer
        let decoded = try JSONDecoder().decode(Response.self, from: data)

        // Mapper resultatet til en liste med Place-objekter
        return decoded.features.compactMap { f in
            let p = f.properties
            let coords = f.geometry.coordinates
            guard coords.count == 2 else { return nil }
            
            return Place(
                id: p.place_id,
                name: p.name ?? "Uten navn",
                address: p.address_line2 ?? "",
                coordinate: .init(latitude: coords[1], longitude: coords[0]),
                category: category,
                openingHours: p.opening_hours,
                phone: p.contact?.phone
            )
        }
    }
}
