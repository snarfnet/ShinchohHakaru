import SwiftUI

@main
struct ShinchohHakaruApp: App {
    @StateObject private var measureManager = MeasureManager()
    @StateObject private var adMob = AdMobManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(measureManager)
                .onAppear { adMob.configure() }
        }
    }
}
