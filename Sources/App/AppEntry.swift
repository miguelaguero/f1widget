//killall NotificationCenter
//killall chronod 
import SwiftUI

@main
struct F1WidgetApp: App {
    private let liveURL = URL(string: "https://f1cosmos.com/dashboard/live")!

    var body: some Scene {
        WindowGroup {
            WebView(url: liveURL)
                .frame(minWidth: 800, minHeight: 600)
                .onOpenURL { url in
                    print("Opened with URL: \(url)")
                }
        }
    }
}
