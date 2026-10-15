import SwiftData
import SwiftUI

@main
struct InklingApp: App {
    @State private var engine = InsightEngine()
    @State private var lock = AppLock()

    private let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: JournalEntry.self)
            #if DEBUG
            DemoData.applyLaunchArguments(to: container)
            #endif
            return container
        } catch {
            fatalError("Could not open the journal database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(engine)
                .environment(lock)
        }
        .modelContainer(container)
    }
}
