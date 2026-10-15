import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppLock.self) private var lock
    @Environment(InsightEngine.self) private var engine
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 21 * 60
    @State private var tab = Tab.journal

    enum Tab: Int { case journal, insights, settings }

    var body: some View {
        TabView(selection: $tab) {
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(Tab.journal)
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(Tab.insights)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .overlay {
            // Also covers the app-switcher snapshot, so a locked journal never shows in the multitasking view.
            if lock.isEnabled && (lock.isLocked || scenePhase != .active) {
                LockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: lock.isLocked)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: lock.lockIfNeeded()
            case .active:
                engine.refresh()
                Task { await lock.unlock() }
                if reminderOn { Task { await Reminders.schedule(minutesAfterMidnight: reminderMinutes) } }
            default: break
            }
        }
        .task {
            #if DEBUG
            if let demoTab = DemoData.launchTab { tab = demoTab }
            #endif
            await lock.unlock()
        }
    }
}

private struct LockView: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ZStack {
            Rectangle().fill(.background).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill").font(.system(size: 40)).foregroundStyle(.tint)
                Text("Inkling is locked").font(.title3.weight(.semibold))
                if lock.isLocked {
                    Button("Unlock") { Task { await lock.unlock() } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
        }
    }
}
