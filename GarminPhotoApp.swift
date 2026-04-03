import SwiftUI
import ConnectIQ

@main
struct GarminPhotoApp: App {
    init() {
        // initialize(withUrlScheme:uiOverrideDelegate:) enregistre le schéma URL
        // utilisé par Garmin Connect pour les callbacks.
        ConnectIQ.sharedInstance().initialize(withUrlScheme: "garminphoto", uiOverrideDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
