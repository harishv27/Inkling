import AppIntents
import Observation

/// Lets an App Intent ask the running app to open the editor.
@MainActor @Observable
final class Router {
    static let shared = Router()
    var composeRequested = false
}

struct NewEntryIntent: AppIntent {
    static let title: LocalizedStringResource = "New Journal Entry"
    static let description = IntentDescription("Opens Inkling on a blank entry.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Router.shared.composeRequested = true
        return .result()
    }
}

struct InklingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NewEntryIntent(),
            phrases: [
                "New entry in \(.applicationName)",
                "Write in \(.applicationName)",
                "Open a new page in \(.applicationName)",
            ],
            shortTitle: "New Entry",
            systemImageName: "square.and.pencil"
        )
    }
}
