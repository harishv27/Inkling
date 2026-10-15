import SwiftData
import SwiftUI
import CoreTransferable
import InklingCore

struct SettingsView: View {
    @Environment(AppLock.self) private var lock
    @Environment(InsightEngine.self) private var engine
    @Query(sort: \JournalEntry.createdAt) private var entries: [JournalEntry]
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 21 * 60
    @State private var lockFailed = false
    @State private var notificationsDenied = false

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderMinutes = (parts.hour ?? 21) * 60 + (parts.minute ?? 0)
            Task { await Reminders.schedule(minutesAfterMidnight: reminderMinutes) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        Image(systemName: engine.isAIAvailable ? "checkmark.seal.fill" : "info.circle")
                            .foregroundStyle(engine.isAIAvailable ? .green : .secondary)
                    } label: {
                        Text(engine.statusTitle)
                    }
                } header: { Text("Summaries") } footer: { Text(engine.statusDetail) }

                Section {
                    Toggle("Lock with Face ID", isOn: Binding(
                        get: { lock.isEnabled },
                        set: { on in Task { lockFailed = !(await lock.setEnabled(on)) } }
                    ))
                } header: { Text("Privacy") } footer: {
                    Text(lockFailed ? "Couldn't turn the lock on. Make sure this iPhone has a passcode set."
                         : "Locks the journal whenever you leave the app. There is no account and nothing is uploaded.")
                }

                Section {
                    Toggle("Daily reminder", isOn: Binding(
                        get: { reminderOn },
                        set: { on in Task { await setReminder(on) } }
                    ))
                    if reminderOn {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: { Text("Reminder") } footer: {
                    Text(notificationsDenied ? "Notifications are off for Inkling. Turn them on in the Settings app."
                         : "Each reminder carries that day's writing prompt.")
                }

                Section {
                    ShareLink(item: JournalExport(markdown: MarkdownExporter.export(entries.map(\.exportEntry))),
                              preview: SharePreview("Inkling journal.md")) {
                        Label("Export as Markdown", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                } header: { Text("Your data") } footer: {
                    Text("A plain text file you can open anywhere. \(entries.count) \(entries.count == 1 ? "entry" : "entries") on this iPhone.")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func setReminder(_ on: Bool) async {
        notificationsDenied = false
        if on {
            guard await Reminders.requestPermission() else { notificationsDenied = true; return }
            reminderOn = true
            await Reminders.schedule(minutesAfterMidnight: reminderMinutes)
        } else {
            reminderOn = false
            Reminders.cancel()
        }
    }
}

struct JournalExport: Transferable {
    let markdown: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { export in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Inkling journal.md")
            try export.markdown.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
