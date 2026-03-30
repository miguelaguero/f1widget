import Foundation

final class F1DataService: Sendable {
    static let shared = F1DataService()
    // Updated to the verified API endpoint
    private let resultsUrl = URL(string: "https://api.jolpi.ca/ergast/f1/current/last/results.json")!

    private let logoBaseUrl = "https://media.formula1.com/image/upload/c_lfill,w_48/q_auto/v1740000001/common/f1/2026/"
    private let constructorLogoMap: [String: String] = [
        "red_bull": "redbullracing/2026redbullracing",
        "red_bull_racing": "redbullracing/2026redbullracing",
        "ferrari": "ferrari/2026ferrari",
        "scuderia_ferrari": "ferrari/2026ferrari",
        "mercedes": "mercedes/2026mercedes",
        "mercedes-amg": "mercedes/2026mercedes",
        "mclaren": "mclaren/2026mclaren",
        "aston_martin": "astonmartin/2026astonmartin",
        "alpine": "alpine/2026alpine",
        "williams": "williams/2026williams",
        "rb": "racingbulls/2026racingbulls",
        "vcarb": "racingbulls/2026racingbulls",
        "racing_bulls": "racingbulls/2026racingbulls",
        "haas": "haasf1team/2026haasf1team",
        "haas_f1_team": "haasf1team/2026haasf1team",
        "sauber": "audi/2026audi",
        "kick_sauber": "audi/2026audi",
        "audi": "audi/2026audi",
        "cadillac": "cadillac/2026cadillac"
    ]

    private let circuitMap: [String: String] = [
        "bahrain": "Bahrain_Circuit.png",
        "jeddah": "Saudi_Arabia_Circuit.png",
        "albert_park": "Australia_Circuit.png",
        "suzuka": "Japan_Circuit.png",
        "shanghai": "China_Circuit.png",
        "miami": "Miami_Circuit.png",
        "imola": "Emilia_Romagna_Circuit.png",
        "monaco": "Monaco_Circuit.png",
        "villeneuve": "Canada_Circuit.png",
        "catalunya": "Spain_Circuit.png",
        "red_bull_ring": "Austria_Circuit.png",
        "silverstone": "Great_Britain_Circuit.png",
        "hungaroring": "Hungary_Circuit.png",
        "spa": "Belgium_Circuit.png",
        "zandvoort": "Netherlands_Circuit.png",
        "monza": "Italy_Circuit.png",
        "baku": "Azerbaijan_Circuit.png",
        "marina_bay": "Singapore_Circuit.png",
        "americas": "USA_Circuit.png",
        "rodriguez": "Mexico_Circuit.png",
        "interlagos": "Brazil_Circuit.png",
        "vegas": "Las_Vegas_Circuit.png",
        "losail": "Qatar_Circuit.png",
        "yas_marina": "Abu_Dhabi_Circuit.png"
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

    func getTrackMapUrl(for circuitId: String) -> URL? {
        guard let filename = circuitMap[circuitId] else { return nil }
        let baseUrl = "https://media.formula1.com/image/upload/f_auto,q_auto/v1677245653/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/"
        return URL(string: baseUrl + filename)
    }

    private func fetchTrackMapData(for circuitId: String) async -> Data? {
        guard let filename = circuitMap[circuitId] else {
            print("No track map mapping for circuitId: \(circuitId)")
            return nil
        }

        // Try different URL patterns
        let baseUrls = [
            "https://media.formula1.com/image/upload/f_auto,q_auto/v1677245653/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/",
            "https://media.formula1.com/image/upload/f_auto,c_limit,q_auto,w_1320/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/",
            "https://media.formula1.com/image/upload/v1/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/"
        ]

        for baseUrl in baseUrls {
            guard let url = URL(string: baseUrl + filename) else { continue }
            print("Attempting to fetch track map from: \(url)")
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Successfully fetched track map from: \(url)")
                    return data
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Failed to fetch track map (Status \(code)) from: \(url)")
                }
            } catch {
                print("Error fetching track map from \(url): \(error.localizedDescription)")
            }
        }

        print("All track map fetch attempts failed for circuitId: \(circuitId)")
        return nil
    }

    private func fetchLogoData(for constructorId: String) async -> Data? {
        guard let baseFilename = constructorLogoMap[constructorId] else {
            return nil
        }
        
        let urlString = logoBaseUrl + baseFilename + "logo.webp"
        
        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Error fetching original logo for \(constructorId): \(error)")
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
