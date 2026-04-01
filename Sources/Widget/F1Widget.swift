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
        Group {
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
                                        .colorInvert(colorScheme == .dark && (winner.constructorId.contains("mercedes") || winner.constructorId.contains("audi") || winner.constructorId.contains("cadillac") || winner.constructorId.contains("aston_martin")))
                                    #elseif canImport(UIKit)
                                    Image(uiImage: platformImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .colorInvert(colorScheme == .dark && (winner.constructorId.contains("mercedes") || winner.constructorId.contains("audi") || winner.constructorId.contains("cadillac") || winner.constructorId.contains("aston_martin")))
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
                VStack(spacing: 0) {
                    // Centered Header for all larger widgets
                    VStack(alignment: .center, spacing: 2) {
                        Text(entry.raceName.uppercased())
                            .font(.system(family == .systemSmall ? .title3 : .title2, design: .rounded))
                            .fontWeight(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(entry.circuitName.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
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
                                                .colorInvert(colorScheme == .dark && (result.constructorId.contains("mercedes") || result.constructorId.contains("audi") || result.constructorId.contains("cadillac") || result.constructorId.contains("aston_martin")))
                                            #elseif canImport(UIKit)
                                            Image(uiImage: platformImage)
                                                .resizable()
                                                .scaledToFit()
                                                .colorInvert(colorScheme == .dark && (result.constructorId.contains("mercedes") || result.constructorId.contains("audi") || result.constructorId.contains("cadillac") || result.constructorId.contains("aston_martin")))
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(Color.clear, for: .widget)
            }
        }
        .widgetURL(URL(string: "https://f1cosmos.com"))
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

extension View {
    @ViewBuilder
    func colorInvert(_ shouldInvert: Bool) -> some View {
        if shouldInvert {
            self.colorInvert()
        } else {
            self
        }
    }
}

struct F1Widget: Widget {
    let kind: String = "F1RaceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectRaceIntent.self, provider: Provider()) { entry in
            F1WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1 Widget")
        .description("Displays latest race results and track map.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

// MARK: - Standings Widget

struct StandingsEntry: TimelineEntry {
    let date: Date
    let standings: [DriverStandingData]
}

struct StandingsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StandingsEntry {
        StandingsEntry(date: Date(), standings: F1DataService.shared.getMockStandings())
    }

    func getSnapshot(in context: Context, completion: @escaping (StandingsEntry) -> ()) {
        let entry = StandingsEntry(date: Date(), standings: F1DataService.shared.getMockStandings())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StandingsEntry>) -> ()) {
        Task {
            let standings = (try? await F1DataService.shared.fetchDriverStandings()) ?? F1DataService.shared.getMockStandings()
            let entry = StandingsEntry(date: Date(), standings: standings)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(3600 * 6)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct StandingsWidgetEntryView : View {
    var entry: StandingsProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Text("DRIVER STANDINGS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .padding(.top, 12)
                .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    standingsHeading()
                    standingsColumn(Array(entry.standings.prefix(11)))
                }
                VStack(alignment: .leading, spacing: 4) {
                    standingsHeading()
                    standingsColumn(Array(entry.standings.dropFirst(11).prefix(11)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.clear, for: .widget)
        .widgetURL(URL(string: "https://f1cosmos.com"))
    }

    @ViewBuilder
    private func standingsHeading() -> some View {
        HStack(spacing: 6) {
            Text("POS")
                .frame(width: 22, alignment: .leading)
            Text("DRIVER")
            Spacer()
            Text("PTS")
        }
        .font(.system(size: 8, weight: .bold, design: .monospaced))
        .foregroundColor(.secondary)
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func standingsColumn(_ standings: [DriverStandingData]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(standings) { standing in
                HStack(spacing: 6) {
                    Text("\(standing.position)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: 22, alignment: .leading)
                        .foregroundColor(.secondary)

                    ZStack {
                        if let logoData = standing.logoData, let platformImage = PlatformImage(data: logoData) {
                            #if canImport(AppKit)
                            Image(nsImage: platformImage)
                                .resizable()
                                .scaledToFit()
                                .colorInvert(colorScheme == .dark && (standing.constructorId.contains("mercedes") || standing.constructorId.contains("audi") || standing.constructorId.contains("cadillac") || standing.constructorId.contains("aston_martin")))
                            #elseif canImport(UIKit)
                            Image(uiImage: platformImage)
                                .resizable()
                                .scaledToFit()
                                .colorInvert(colorScheme == .dark && (standing.constructorId.contains("mercedes") || standing.constructorId.contains("audi") || standing.constructorId.contains("cadillac") || standing.constructorId.contains("aston_martin")))
                            #endif
                        } else {
                            Circle()
                                .fill(Color(hex: standing.constructorColor))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(width: 16, height: 16)

                    Text(standing.driverName)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(standing.points)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct StandingsWidget: Widget {
    let kind: String = "F1StandingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StandingsProvider()) { entry in
            StandingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1 Driver Standings")
        .description("Current Formula 1 driver standings.")
        .supportedFamilies([.systemExtraLarge])
    }
}

// MARK: - Constructor Standings Widget

struct ConstructorStandingsEntry: TimelineEntry {
    let date: Date
    let standings: [ConstructorStandingData]
}

struct ConstructorStandingsProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConstructorStandingsEntry {
        ConstructorStandingsEntry(date: Date(), standings: F1DataService.shared.getMockConstructorStandings())
    }

    func getSnapshot(in context: Context, completion: @escaping (ConstructorStandingsEntry) -> ()) {
        let entry = ConstructorStandingsEntry(date: Date(), standings: F1DataService.shared.getMockConstructorStandings())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConstructorStandingsEntry>) -> ()) {
        Task {
            let standings = (try? await F1DataService.shared.fetchConstructorStandings()) ?? F1DataService.shared.getMockConstructorStandings()
            let entry = ConstructorStandingsEntry(date: Date(), standings: standings)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(3600 * 6)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct ConstructorStandingsWidgetEntryView : View {
    var entry: ConstructorStandingsProvider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Text("CONSTRUCTOR STANDINGS")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("POS")
                        .frame(width: 20, alignment: .leading)
                    Text("CONSTRUCTOR")
                    Spacer()
                    Text("PTS")
                }
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 2)

                ForEach(entry.standings.prefix(11)) { standing in
                    HStack(spacing: 8) {
                        Text("\(standing.position)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .frame(width: 20, alignment: .leading)
                            .foregroundColor(.secondary)

                        ZStack {
                            if let logoData = standing.logoData, let platformImage = PlatformImage(data: logoData) {
                                #if canImport(AppKit)
                                Image(nsImage: platformImage)
                                    .resizable()
                                    .scaledToFit()
                                    .colorInvert(colorScheme == .dark && (standing.constructorId.contains("mercedes") || standing.constructorId.contains("audi") || standing.constructorId.contains("cadillac") || standing.constructorId.contains("aston_martin")))
                                #elseif canImport(UIKit)
                                Image(uiImage: platformImage)
                                    .resizable()
                                    .scaledToFit()
                                    .colorInvert(colorScheme == .dark && (standing.constructorId.contains("mercedes") || standing.constructorId.contains("audi") || standing.constructorId.contains("cadillac") || standing.constructorId.contains("aston_martin")))
                                #endif
                            } else {
                                Circle()
                                    .fill(Color(hex: standing.constructorColor))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .frame(width: 16, height: 16)

                        Text(standing.constructorName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(standing.points)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.clear, for: .widget)
        .widgetURL(URL(string: "https://f1cosmos.com"))
    }
}

struct ConstructorStandingsWidget: Widget {
    let kind: String = "F1ConstructorStandingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConstructorStandingsProvider()) { entry in
            ConstructorStandingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1 Constructor Standings")
        .description("Current Formula 1 constructor standings.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Widget Bundle

#if !IS_APP
@main
#endif
struct F1Widgets: WidgetBundle {
    var body: some Widget {
        F1Widget()
        StandingsWidget()
        ConstructorStandingsWidget()
    }
}

// MARK: - Previews

struct F1Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            F1WidgetEntryView(entry: SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil, configuration: SelectRaceIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            StandingsWidgetEntryView(entry: StandingsEntry(date: Date(), standings: F1DataService.shared.getMockStandings()))
                .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
        }
    }
}
