import SwiftUI

@main
struct TimelineApp: App {
    @State private var store = CalendarStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
