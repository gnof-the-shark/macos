import SwiftUI
import ConnectIQ

@main
struct GarminPhotoApp: App {
    init() {
        // initialize(withUrlScheme:uiOverrideDelegate:) is a void call that
        // registers the URL scheme used by Garmin Connect for callbacks.
        ConnectIQ.sharedInstance().initialize(withUrlScheme: "garminphoto", uiOverrideDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
