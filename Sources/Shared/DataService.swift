import Foundation

final class F1DataService: Sendable {
    static let shared = F1DataService()
    // Updated to the verified API endpoint
    private let resultsUrl = URL(string: "https://api.jolpi.ca/ergast/f1/current/last/results.json")!

    private let logoBaseUrl = "https://media.formula1.com/image/upload/c_lfill,w_48/q_auto/v1740000001/common/f1/2026/"
    private let constructorLogoMap: [String: String] = [
        "red_bull": "redbullracing/2026redbullracinglogowhite.webp",
        "red_bull_racing": "redbullracing/2026redbullracinglogowhite.webp",
        "ferrari": "ferrari/2026ferrarilogowhite.webp",
        "scuderia_ferrari": "ferrari/2026ferrarilogowhite.webp",
        "mercedes": "mercedes/2026mercedeslogowhite.webp",
        "mercedes-amg": "mercedes/2026mercedeslogowhite.webp",
        "mclaren": "mclaren/2026mclarenlogowhite.webp",
        "aston_martin": "astonmartin/2026astonmartinlogowhite.webp",
        "alpine": "alpine/2026alpinelogowhite.webp",
        "williams": "williams/2026williamslogowhite.webp",
        "rb": "racingbulls/2026racingbullslogowhite.webp",
        "vcarb": "racingbulls/2026racingbullslogowhite.webp",
        "racing_bulls": "racingbulls/2026racingbullslogowhite.webp",
        "haas": "haasf1team/2026haasf1teamlogowhite.webp",
        "haas_f1_team": "haasf1team/2026haasf1teamlogowhite.webp",
        "sauber": "audi/2026audilogowhite.webp",
        "kick_sauber": "audi/2026audilogowhite.webp",
        "audi": "audi/2026audilogowhite.webp",
        "cadillac": "cadillac/2026cadillaclogowhite.webp"
    ]

    private let trackMapBaseUrl = "https://media.formula1.com/image/upload/f_auto,q_auto/v1677245653/content/dam/fom-website/2018-redesign-assets/circuit-maps/16x9/white/"
    private let circuitMap: [String: String] = [
        "bahrain": "Bahrain.png",
        "jeddah": "Saudi_Arabia.png",
        "albert_park": "Australia.png",
        "suzuka": "Japan.png",
        "shanghai": "China.png",
        "miami": "Miami.png",
        "imola": "Emilia_Romagna.png",
        "monaco": "Monaco.png",
        "villeneuve": "Canada.png",
        "catalunya": "Spain.png",
        "red_bull_ring": "Austria.png",
        "silverstone": "Great_Britain.png",
        "hungaroring": "Hungary.png",
        "spa": "Belgium.png",
        "zandvoort": "Netherlands.png",
        "monza": "Italy.png",
        "baku": "Azerbaijan.png",
        "marina_bay": "Singapore.png",
        "americas": "USA.png",
        "rodriguez": "Mexico.png",
        "interlagos": "Brazil.png",
        "vegas": "Las_Vegas.png",
        "losail": "Qatar.png",
        "yas_marina": "Abu_Dhabi.png"
    ]

    func fetchLatestResults() async throws -> ([RaceEntryData], String, String, Data?) {
        print("Starting F1 results fetch from: \(resultsUrl)")
        do {
            let (data, response) = try await URLSession.shared.data(from: resultsUrl)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("Error: Received non-200 status code")
                    throw NSError(domain: "F1DataService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                }
            }

            print("Data received: \(data.count) bytes")
            let raceResponse = try JSONDecoder().decode(RaceResponse.self, from: data)
            print("Successfully decoded RaceResponse")

            guard let latestRace = raceResponse.mrData.raceTable.races.first else {
                print("No races found in API response")
                return (getMockResults(), "NO DATA", "", nil)
            }
            
            guard let results = latestRace.results else {
                print("No results found for race: \(latestRace.raceName)")
                return (getMockResults(), "NO RESULTS", latestRace.date, nil)
            }

            print("Found \(results.count) results for \(latestRace.raceName)")
            
            // Fetch track map
            let trackMapData = await fetchTrackMapData(for: latestRace.circuit.circuitId)

            let top10 = Array(results.prefix(10))
            
            // Use TaskGroup for parallel logo fetching
            let entries = await withTaskGroup(of: (Int, RaceEntryData).self) { group in
                for (index, result) in top10.enumerated() {
                    let constructorId = result.constructor.constructorId
                    let driverName = result.driver.fullName
                    let position = Int(result.position) ?? 0

                    group.addTask {
                        let logoData = await self.fetchLogoData(for: constructorId)
                        let entry = RaceEntryData(
                            position: position,
                            driverName: driverName,
                            constructorId: constructorId,
                            logoData: logoData
                        )
                        return (index, entry)
                    }
                }
                
                var indexedResults: [(Int, RaceEntryData)] = []
                for await entry in group {
                    indexedResults.append(entry)
                }
                // Sort by original index to maintain position order
                return indexedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
            }

            print("Successfully prepared \(entries.count) entries for widget")
            return (entries, latestRace.raceName, latestRace.date, trackMapData)
        } catch {
            print("Error in fetchLatestResults: \(error.localizedDescription)")
            throw error
        }
    }

    private func fetchTrackMapData(for circuitId: String) async -> Data? {
        guard let filename = circuitMap[circuitId],
              let url = URL(string: trackMapBaseUrl + filename) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Error fetching track map for \(circuitId): \(error)")
            return nil
        }
    }

    private func fetchLogoData(for constructorId: String) async -> Data? {
        guard let filename = constructorLogoMap[constructorId],
              let url = URL(string: logoBaseUrl + filename) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Error fetching logo for \(constructorId): \(error)")
            return nil
        }
    }
    
    func getMockResults() -> [RaceEntryData] {
        let mockDrivers = [
            ("Max Verstappen", "red_bull"),
            ("Lando Norris", "mclaren"),
            ("Charles Leclerc", "ferrari"),
            ("Oscar Piastri", "mclaren"),
            ("Carlos Sainz", "ferrari"),
            ("Lewis Hamilton", "mercedes"),
            ("George Russell", "mercedes"),
            ("Sergio Perez", "red_bull"),
            ("Fernando Alonso", "aston_martin"),
            ("Nico Hulkenberg", "haas")
        ]
        
        return mockDrivers.enumerated().map { index, driverInfo in
            RaceEntryData(
                position: index + 1,
                driverName: driverInfo.0,
                constructorId: driverInfo.1,
                logoData: nil
            )
        }
    }
}
