import Foundation

struct RaceResponse: Codable {
    let mrData: MRData

    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct MRData: Codable {
    let raceTable: RaceTable

    enum CodingKeys: String, CodingKey {
        case raceTable = "RaceTable"
    }
}

struct RaceTable: Codable {
    let races: [Race]

    enum CodingKeys: String, CodingKey {
        case races = "Races"
    }
}

struct Race: Codable {
    let season: String
    let round: String
    let raceName: String
    let date: String
    let circuit: Circuit
    let results: [RaceResult]?

    enum CodingKeys: String, CodingKey {
        case season, round, raceName, date
        case circuit = "Circuit"
        case results = "Results"
    }
}

struct Circuit: Codable {
    let circuitId: String
    let circuitName: String
    let location: Location

    enum CodingKeys: String, CodingKey {
        case circuitId, circuitName
        case location = "Location"
    }
}

struct Location: Codable {
    let lat: String
    let long: String
    let locality: String
    let country: String
}

struct RaceResult: Codable {
    let position: String
    let driver: Driver
    let constructor: Constructor

    enum CodingKeys: String, CodingKey {
        case position
        case driver = "Driver"
        case constructor = "Constructor"
    }
}

struct Driver: Codable {
    let driverId: String
    let code: String?
    let givenName: String
    let familyName: String

    var displayName: String {
        if let code = code {
            return code
        }
        return familyName
    }

    var fullName: String {
        return "\(givenName) \(familyName)"
    }
}

struct Constructor: Codable {
    let constructorId: String
    let name: String
}

struct RaceEntryData: Identifiable {
    let id = UUID()
    let position: Int
    let driverName: String
    let constructorId: String
    let logoData: Data?
}
