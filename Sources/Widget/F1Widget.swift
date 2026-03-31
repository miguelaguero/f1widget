import WidgetKit
import SwiftUI
import AppIntents

#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

// MARK: - App Intents

struct RaceEntity: AppEntity {
    var id: String // season + round
    
    @Property(title: "Race Name")
    var raceName: String
    
    @Property(title: "Circuit Name")
    var circuitName: String
    
    init(id: String, raceName: String, circuitName: String) {
        self.id = id
        self.raceName = raceName
        self.circuitName = circuitName
    }
    
    init() {
        self.id = ""
        self.raceName = ""
        self.circuitName = ""
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Race"
    static var defaultQuery = RaceQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(raceName)", subtitle: "\(circuitName)")
    }
}

struct RaceQuery: EntityQuery {
    func entities(for identifiers: [RaceEntity.ID]) async throws -> [RaceEntity] {
        let allRaces = try? await F1DataService.shared.fetchAllRaces()
        return (allRaces ?? []).map { race in
            RaceEntity(id: "\(race.season)-\(race.round)", raceName: race.raceName, circuitName: race.circuit.circuitName)
        }.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [RaceEntity] {
        let allRaces = try? await F1DataService.shared.fetchAllRaces()
        return (allRaces ?? []).map { race in
            RaceEntity(id: "\(race.season)-\(race.round)", raceName: race.raceName, circuitName: race.circuit.circuitName)
        }
    }
    
    func entities(matching string: String) async throws -> [RaceEntity] {
        let allRaces = try? await F1DataService.shared.fetchAllRaces()
        return (allRaces ?? []).map { race in
            RaceEntity(id: "\(race.season)-\(race.round)", raceName: race.raceName, circuitName: race.circuit.circuitName)
        }.filter { $0.raceName.localizedCaseInsensitiveContains(string) || $0.circuitName.localizedCaseInsensitiveContains(string) }
    }
}

struct SelectRaceIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Race"
    static var description = IntentDescription("Select which race to display.")
    
    @Parameter(title: "Race")
    var race: RaceEntity?
    
    init(race: RaceEntity) {
        self.race = race
    }
    
    init() {}
}

// MARK: - Widget Core

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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let raceName: String
    let circuitName: String
    let raceDate: String
    let results: [RaceEntryData]
    let trackMapData: Data?
    let configuration: SelectRaceIntent
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil, configuration: SelectRaceIntent())
    }

    func snapshot(for configuration: SelectRaceIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil, configuration: configuration)
    }

    func timeline(for configuration: SelectRaceIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (results, raceName, circuitName, raceDate, trackMapData): ([RaceEntryData], String, String, String, Data?)
        
        if let race = configuration.race {
            let idParts = race.id.components(separatedBy: "-")
            if idParts.count == 2 {
                let season = idParts[0]
                let round = idParts[1]
                (results, raceName, circuitName, raceDate, trackMapData) = (try? await F1DataService.shared.fetchResults(for: season, round: round)) ?? (F1DataService.shared.getMockResults(), "LATEST RACE", "Circuit Name", "", nil)
            } else {
                (results, raceName, circuitName, raceDate, trackMapData) = (try? await F1DataService.shared.fetchLatestResults()) ?? (F1DataService.shared.getMockResults(), "LATEST RACE", "Circuit Name", "", nil)
            }
        } else {
            (results, raceName, circuitName, raceDate, trackMapData) = (try? await F1DataService.shared.fetchLatestResults()) ?? (F1DataService.shared.getMockResults(), "LATEST RACE", "Circuit Name", "", nil)
        }
        
        let entry = SimpleEntry(date: Date(), raceName: raceName, circuitName: circuitName, raceDate: raceDate, results: results, trackMapData: trackMapData, configuration: configuration)
        
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct F1WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if family == .systemSmall {
            VStack(alignment: .center, spacing: 0) {
                if let winner = entry.results.first {
                    if let photoData = winner.driverPhotoData, let platformImage = PlatformImage(data: photoData) {
                        #if canImport(AppKit)
                        Image(nsImage: platformImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .padding(.top, 8)
                        #elseif canImport(UIKit)
                        Image(uiImage: platformImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .padding(.top, 8)
                        #endif
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(height: 80)
                            .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 0)
                    
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            if let logoData = winner.logoData, let platformImage = PlatformImage(data: logoData) {
                                #if canImport(AppKit)
                                Image(nsImage: platformImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                #elseif canImport(UIKit)
                                Image(uiImage: platformImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                #endif
                            }
                            
                            Text(winner.constructorName.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        let names = winner.driverName.uppercased().components(separatedBy: " ")
                        VStack(spacing: -4) {
                            if names.count >= 2 {
                                Text(names[0])
                                Text(names.dropFirst().joined(separator: " "))
                            } else {
                                Text(winner.driverName.uppercased())
                            }
                        }
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    .padding(.bottom, 8)
                    
                    Text(entry.circuitName.uppercased())
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)
                } else {
                    Text("No data")
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                if let winner = entry.results.first {
                    ZStack {
                        Color(hex: winner.constructorColor)
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }
                } else {
                    Color.gray
                }
            }
        } else {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.raceName.uppercased())
                            .font(.system(family == .systemSmall ? .title3 : .title2, design: .rounded))
                            .fontWeight(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.bottom, 4)
                    .padding(.top, 16)

                    ForEach(Array(entry.results.prefix(maxItems))) { result in
                        HStack(spacing: 8) {
                            Text("\(result.position)")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .frame(width: 22, alignment: .leading)

                            ZStack {
                                if let logoData = result.logoData, let platformImage = PlatformImage(data: logoData) {
                                    #if canImport(AppKit)
                                    Image(nsImage: platformImage)
                                        .resizable()
                                        .scaledToFit()
                                    #elseif canImport(UIKit)
                                    Image(uiImage: platformImage)
                                        .resizable()
                                        .scaledToFit()
                                    #endif
                                } else {
                                    Image(systemName: "flag.checkered")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.secondary)
                                }

                            }
                            .frame(width: 24, height: 24)

                            Text(result.driverName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    if entry.results.isEmpty {
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: (family == .systemExtraLarge) ? 220 : .infinity, alignment: .leading)
                
                // Map only for Extra Large
                if family == .systemExtraLarge {
                    VStack {
                        if let trackMapData = entry.trackMapData, let platformImage = PlatformImage(data: trackMapData) {
                            #if canImport(AppKit)
                            Image(nsImage: platformImage)
                                .resizable()
                                .scaledToFit()
                            #elseif canImport(UIKit)
                            Image(uiImage: platformImage)
                                .resizable()
                                .scaledToFit()
                            #endif
                        } else {
                            // Placeholder when map is missing
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Map not available")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(Color.clear, for: .widget)
        }
    }

    private var maxItems: Int {
        switch family {
        case .systemSmall: return 0
        case .systemMedium: return 3
        case .systemLarge: return 10
        case .systemExtraLarge: return 12
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 1
        @unknown default: return 5
        }
    }
}

#if !IS_APP
@main
#endif
struct F1Widget: Widget {
    let kind: String = "F1RaceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRaceIntent.self, provider: Provider()) { entry in
            F1WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1Race Widget")
        .description("Displays latest race results and track map.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct F1Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            F1WidgetEntryView(entry: SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil, configuration: SelectRaceIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}
