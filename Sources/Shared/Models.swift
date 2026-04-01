import Foundation
import SwiftUI

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

// MARK: - Standings Models

struct StandingsResponse: Codable {
    let mrData: StandingsMRData

    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct StandingsMRData: Codable {
    let standingsTable: StandingsTable

    enum CodingKeys: String, CodingKey {
        case standingsTable = "StandingsTable"
    }
}

struct StandingsTable: Codable {
    let standingsLists: [StandingsList]

    enum CodingKeys: String, CodingKey {
        case standingsLists = "StandingsLists"
    }
}

struct StandingsList: Codable {
    let season: String
    let round: String
    let driverStandings: [DriverStanding]

    enum CodingKeys: String, CodingKey {
        case season, round
        case driverStandings = "DriverStandings"
    }
}

struct DriverStanding: Codable {
    let position: String
    let points: String
    let wins: String
    let driver: Driver
    let constructors: [Constructor]

    enum CodingKeys: String, CodingKey {
        case position, points, wins
        case driver = "Driver"
        case constructors = "Constructors"
    }
}

struct ConstructorStanding: Codable {
    let position: String
    let points: String
    let wins: String
    let constructor: Constructor

    enum CodingKeys: String, CodingKey {
        case position, points, wins
        case constructor = "Constructor"
    }
}

// MARK: - Constructor Standings Response

struct ConstructorStandingsResponse: Codable {
    let mrData: ConstructorStandingsMRData

    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

struct ConstructorStandingsMRData: Codable {
    let standingsTable: ConstructorStandingsTable

    enum CodingKeys: String, CodingKey {
        case standingsTable = "StandingsTable"
    }
}

struct ConstructorStandingsTable: Codable {
    let standingsLists: [ConstructorStandingsList]

    enum CodingKeys: String, CodingKey {
        case standingsLists = "StandingsLists"
    }
}

struct ConstructorStandingsList: Codable {
    let season: String
    let round: String
    let constructorStandings: [ConstructorStanding]

    enum CodingKeys: String, CodingKey {
        case season, round
        case constructorStandings = "ConstructorStandings"
    }
}

struct DriverStandingData: Identifiable {
    let id = UUID()
    let position: Int
    let driverName: String
    let driverId: String
    let constructorId: String
    let constructorName: String
    let constructorColor: String
    let points: String
    let logoData: Data?
}

struct ConstructorStandingData: Identifiable {
    let id = UUID()
    let position: Int
    let constructorId: String
    let constructorName: String
    let constructorColor: String
    let points: String
    let logoData: Data?
}

struct RaceEntryData: Identifiable {
    let id = UUID()
    let position: Int
    let driverName: String
    let driverId: String
    let constructorId: String
    let constructorName: String
    let constructorColor: String
    let logoData: Data?
    let driverPhotoData: Data?
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
