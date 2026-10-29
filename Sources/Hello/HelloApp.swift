import SwiftUI

@main
struct HelloApp: App {
    @State private var store = CalendarStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
