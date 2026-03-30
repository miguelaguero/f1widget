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
    let raceDate: String
    let results: [RaceEntryData]
    let trackMapData: Data?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", raceDate: "2024-05-26", results: F1DataService.shared.getMockResults(), trackMapData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let (results, raceName, raceDate, trackMapData) = (try? await F1DataService.shared.fetchLatestResults()) ?? (F1DataService.shared.getMockResults(), "LATEST RACE", "", nil)
            let entry = SimpleEntry(date: Date(), raceName: raceName, raceDate: raceDate, results: results, trackMapData: trackMapData)
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct F1WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.raceName.uppercased())
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if !entry.raceDate.isEmpty {
                        Text(entry.raceDate)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 2)

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
                                Image(systemName: "car.fill")
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
            
            if family == .systemLarge, let trackMapData = entry.trackMapData, let platformImage = PlatformImage(data: trackMapData) {
                VStack {
                    Spacer()
                    #if canImport(AppKit)
                    Image(nsImage: platformImage)
                        .resizable()
                        .scaledToFit()
                        .renderingMode(Image.TemplateRenderingMode.template)
                        .foregroundColor(.primary)
                        .opacity(0.8)
                    #elseif canImport(UIKit)
                    Image(uiImage: platformImage)
                        .resizable()
                        .scaledToFit()
                        .renderingMode(Image.TemplateRenderingMode.template)
                        .foregroundColor(.primary)
                        .opacity(0.8)
                    #endif
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(Color.clear, for: .widget)
    }

    private var maxItems: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 5
        case .systemLarge: return 10
        case .systemExtraLarge: return 10
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return 1
        @unknown default: return 5
        }
    }
}

#if !IS_APP
@main
#endif
struct F1Widget: Widget {
    let kind: String = "F1Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            F1WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("F1 Race Results")
        .description("Displays top 10 results of the most recent F1 race.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct F1Widget_Previews: PreviewProvider {
    static var previews: some View {
        let dummyResults = F1DataService.shared.getMockResults()
        let dummyEntry = SimpleEntry(date: Date(), raceName: "MONACO GRAND PRIX", raceDate: "2024-05-26", results: dummyResults, trackMapData: nil)
        
        Group {
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            F1WidgetEntryView(entry: dummyEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
