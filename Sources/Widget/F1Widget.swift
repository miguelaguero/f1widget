import WidgetKit
import SwiftUI
#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

struct SimpleEntry: TimelineEntry {
    let date: Date
    let raceName: String
    let circuitName: String
    let raceDate: String
    let results: [RaceEntryData]
    let trackMapData: Data?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let (results, raceName, circuitName, raceDate, trackMapData) = (try? await F1DataService.shared.fetchLatestResults()) ?? (F1DataService.shared.getMockResults(), "LATEST RACE", "Circuit Name", "", nil)
            let entry = SimpleEntry(date: Date(), raceName: raceName, circuitName: circuitName, raceDate: raceDate, results: results, trackMapData: trackMapData)
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct F1WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if family == .systemSmall {
            VStack(alignment: .center, spacing: 2) {
                Spacer(minLength: 0)
                
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 34))
                
                Spacer(minLength: 0)
                
                if let winner = entry.results.first {
                    let names = winner.driverName.uppercased().components(separatedBy: " ")
                    VStack(spacing: 0) {
                        Text("WINNER")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                        
                        VStack(spacing: -3) {
                            if names.count >= 2 {
                                Text(names[0])
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.3)
                                Text(names.dropFirst().joined(separator: " "))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.3)
                            } else {
                                Text(winner.driverName.uppercased())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.3)
                            }
                        }
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                } else {
                    Text("No data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
                
                Text(entry.circuitName.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.bottom, 4)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(Color.clear, for: .widget)
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            F1WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1Race Widget")
        .description("Displays latest race results and track map.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct F1Widget_Previews: PreviewProvider {
    static var previews: some View {
        let dummyResults = F1DataService.shared.getMockResults()
        let dummyEntry = SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", circuitName: "Circuit de Monaco", raceDate: "2024-05-26", results: dummyResults, trackMapData: nil)
        
        Group {
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
        }
    }
}
