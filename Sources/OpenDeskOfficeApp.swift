import SwiftUI

@main
struct OpenDeskOfficeApp: App {
    @StateObject private var store = LocalDocumentStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}