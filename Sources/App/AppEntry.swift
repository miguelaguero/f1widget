import SwiftUI

@main
struct F1WidgetApp: App {
    @State private var results: [Race] = []
    @State private var isLoading = false

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "flag.checkered")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.red)
                    
                    Text("F1 Results")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Refresh") {
                            Task { await fetchHistory() }
                        }
                    }
                }
                .padding(.bottom)

                if results.isEmpty {
                    VStack {
                        Text("Add the widget to your Notification Center or Desktop to see results.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(results, id: \.round) { race in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(race.raceName)
                                    .font(.headline)
                                Text(race.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let winner = race.results?.first {
                                    Text("Winner: \(winner.driver.fullName)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            Spacer()
                            if let url = F1DataService.shared.getTrackMapUrl(for: race.circuit.circuitId) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 45)
                                        .padding(4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(4)
                                } placeholder: {
                                    Color.gray.opacity(0.1)
                                        .frame(width: 80, height: 45)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(width: 500, height: 450)
            .padding()
            .onAppear {
                Task { await fetchHistory() }
            }
        }
    }

    private func fetchHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "https://api.jolpi.ca/ergast/f1/current/results.json")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RaceResponse.self, from: data)
            self.results = Array(response.mrData.raceTable.races.reversed())
        } catch {
            print("History fetch failed: \(error)")
        }
    }
}
