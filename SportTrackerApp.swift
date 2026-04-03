import SwiftUI
import ConnectIQ

@main
struct SportTrackerApp: App {
    init() {
        // initialize(withUrlScheme:uiOverrideDelegate:) is a void call that
        // registers the URL scheme used by Garmin Connect for callbacks.
        ConnectIQ.sharedInstance().initialize(withUrlScheme: "sporttracker", uiOverrideDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    ConnectIQ.sharedInstance().handleOpenURL(url, fromSourceApplication: nil)
                }
        }
    }
}
