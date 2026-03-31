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

    private let constructorColorMap: [String: String] = [
        "red_bull": "#3671C6",
        "red_bull_racing": "#3671C6",
        "ferrari": "#E80020",
        "scuderia_ferrari": "#E80020",
        "mercedes": "#27F4D2",
        "mercedes-amg": "#27F4D2",
        "mclaren": "#FF8000",
        "aston_martin": "#229971",
        "alpine": "#0093CC",
        "williams": "#64C4FF",
        "rb": "#6692FF",
        "vcarb": "#6692FF",
        "racing_bulls": "#6692FF",
        "haas": "#B6BABD",
        "haas_f1_team": "#B6BABD",
        "sauber": "#52E252",
        "kick_sauber": "#52E252",
        "audi": "#52E252",
        "cadillac": "#ADABAC"
    ]

    // Using verified F1 CDN pattern for headshots
    private let driverPhotoUrlMap: [String: String] = [
        "verstappen": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/M/MAXVER01_Max_Verstappen/maxver01.png.transform/2col/image.png",
        "leclerc": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/C/CHALEC01_Charles_Leclerc/chalec01.png.transform/2col/image.png",
        "norris": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LANNOR01_Lando_Norris/lannor01.png.transform/2col/image.png",
        "sainz": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/C/CARSAI01_Carlos_Sainz/carsai01.png.transform/2col/image.png",
        "hamilton": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LEWHAM01_Lewis_Hamilton/lewham01.png.transform/2col/image.png",
        "russell": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/G/GEORUS01_George_Russell/georus01.png.transform/2col/image.png",
        "piastri": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/O/OSCPIA01_Oscar_Piastri/oscpia01.png.transform/2col/image.png",
        "perez": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/S/SERPER01_Sergio_Perez/serper01.png.transform/2col/image.png",
        "alonso": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/F/FERALO01_Fernando_Alonso/feralo01.png.transform/2col/image.png",
        "stroll": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LANSTR01_Lance_Stroll/lanstr01.png.transform/2col/image.png",
        "hulkenberg": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/N/NICHUL01_Nico_Hulkenberg/nichul01.png.transform/2col/image.png",
        "tsunoda": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/Y/YUKTSU01_Yuki_Tsunoda/yuktsu01.png.transform/2col/image.png",
        "albon": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/A/ALEALB01_Alexander_Albon/alealb01.png.transform/2col/image.png",
        "gasly": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/P/PIEGAS01_Pierre_Gasly/piegas01.png.transform/2col/image.png",
        "ocon": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/E/ESTOCO01_Esteban_Ocon/estoco01.png.transform/2col/image.png",
        "magnussen": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/K/KEVMAG01_Kevin_Magnussen/kevmag01.png.transform/2col/image.png",
        "bottas": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/V/VALBOT01_Valtteri_Bottas/valbot01.png.transform/2col/image.png",
        "zhou": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/G/GUAZHO01_Zhou_Guanyu/guazho01.png.transform/2col/image.png",
        "sargeant": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LOGSAR01_Logan_Sargeant/logsar01.png.transform/2col/image.png",
        "ricciardo": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/D/DANRIC01_Daniel_Ricciardo/danric01.png.transform/2col/image.png",
        "bearman": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/O/OLIBEA01_Oliver_Bearman/olibea01.png.transform/2col/image.png",
        "lawson": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LIALAW01_Liam_Lawson/lialaw01.png.transform/2col/image.png",
        "antonelli": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/K/ANDANT01_Kimi_Antonelli/andant01.png.transform/2col/image.png",
        "bortoleto": "https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/G/GABBOR01_Gabriel_Bortoleto/gabbor01.png.transform/2col/image.png"
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

    func fetchLatestResults() async throws -> ([RaceEntryData], String, String, String, Data?) {
        do {
            let (data, _) = try await URLSession.shared.data(from: resultsUrl)
            let raceResponse = try JSONDecoder().decode(RaceResponse.self, from: data)

            guard let latestRace = raceResponse.mrData.raceTable.races.first else {
                return (getMockResults(), "NO DATA", "NO CIRCUIT", "", nil)
            }
            
            guard let results = latestRace.results else {
                return (getMockResults(), "NO RESULTS", latestRace.circuit.circuitName, latestRace.date, nil)
            }

            let trackMapData = await fetchTrackMapData(for: latestRace.circuit.circuitId)
            let top10 = Array(results.prefix(10))
            
            let entries = await withTaskGroup(of: (Int, RaceEntryData).self) { group in
                for (index, result) in top10.enumerated() {
                    let constructorId = result.constructor.constructorId
                    let constructorName = result.constructor.name
                    let driverName = result.driver.fullName
                    let driverId = result.driver.driverId
                    let position = Int(result.position) ?? 0

                    group.addTask {
                        let logoData = await self.fetchLogoData(for: constructorId)
                        let driverPhotoData = await self.fetchDriverPhotoData(for: driverId)
                        let constructorColor = self.constructorColorMap[constructorId] ?? "#888888"
                        
                        let entry = RaceEntryData(
                            position: position,
                            driverName: driverName,
                            driverId: driverId,
                            constructorId: constructorId,
                            constructorName: constructorName,
                            constructorColor: constructorColor,
                            logoData: logoData,
                            driverPhotoData: driverPhotoData
                        )
                        return (index, entry)
                    }
                }
                
                var indexedResults: [(Int, RaceEntryData)] = []
                for await entry in group {
                    indexedResults.append(entry)
                }
                return indexedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
            }

            return (entries, latestRace.raceName, latestRace.circuit.circuitName, latestRace.date, trackMapData)
        } catch {
            return (getMockResults(), "LATEST RACE", "Circuit Name", "", nil)
        }
    }

    private func fetchDriverPhotoData(for driverId: String) async -> Data? {
        guard let urlString = driverPhotoUrlMap[driverId] else { return nil }
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                return data
            }
        } catch {
            print("Error fetching driver photo: \(error)")
        }
        return nil
    }

    func getTrackMapUrl(for circuitId: String) -> URL? {
        guard let filename = circuitMap[circuitId] else { return nil }
        let baseUrl = "https://media.formula1.com/image/upload/f_auto,q_auto/v1677245653/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/"
        return URL(string: baseUrl + filename)
    }

    private func fetchTrackMapData(for circuitId: String) async -> Data? {
        guard let filename = circuitMap[circuitId] else { return nil }
        let baseUrls = [
            "https://media.formula1.com/image/upload/f_auto,q_auto/v1677245653/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/",
            "https://media.formula1.com/image/upload/f_auto,c_limit,q_auto,w_1320/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/"
        ]

        for baseUrl in baseUrls {
            guard let url = URL(string: baseUrl + filename) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    return data
                }
            } catch {}
        }
        return nil
    }

    private func fetchLogoData(for constructorId: String) async -> Data? {
        guard let baseFilename = constructorLogoMap[constructorId] else { return nil }
        let urlString = logoBaseUrl + baseFilename + "logo.webp"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }
    
    func getMockResults() -> [RaceEntryData] {
        let mockDrivers = [
            ("Max Verstappen", "verstappen", "red_bull", "Red Bull Racing"),
            ("Lando Norris", "norris", "mclaren", "McLaren"),
            ("Charles Leclerc", "leclerc", "ferrari", "Ferrari")
        ]
        
        return mockDrivers.enumerated().map { index, info in
            RaceEntryData(
                position: index + 1,
                driverName: info.0,
                driverId: info.1,
                constructorId: info.2,
                constructorName: info.3,
                constructorColor: constructorColorMap[info.2] ?? "#888888",
                logoData: nil,
                driverPhotoData: nil
            )
        }
    }
}
