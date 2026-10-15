import SwiftData
import SwiftUI
import InklingCore

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(InsightEngine.self) private var engine

    private let existing: JournalEntry?
    private let prompt: String?

    @State private var text: String
    @State private var mood: Mood?
    @State private var tags: [String]
    @State private var tagsEdited = false
    @State private var moodEdited = false
    @State private var newTag = ""
    @State private var questions: [String] = []
    @State private var asking = false
    @State private var askFailed = false
    @State private var confirmDelete = false
    @FocusState private var focused: Bool

    init(target: EditorTarget) {
        switch target {
        case .new(let prompt):
            existing = nil
            self.prompt = prompt
            _text = State(initialValue: "")
            _mood = State(initialValue: nil)
            _tags = State(initialValue: [])
        case .existing(let entry):
            existing = entry
            prompt = nil
            _text = State(initialValue: entry.text)
            _mood = State(initialValue: entry.mood)
            _tags = State(initialValue: entry.tags)
        }
    }

    private var words: Int { TextStats.wordCount(text) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let prompt, existing == nil {
                        Text(prompt)
                            .font(.system(.callout, design: .serif)).italic()
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: $text)
                            .font(.system(.body, design: .serif))
                            .lineSpacing(4)
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .frame(minHeight: 200)
                            .focused($focused)
                            .overlay(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text("Start writing…").foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                                }
                            }
                        Text("\(words) \(words == 1 ? "word" : "words")")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(12)
                    .card()
                    moodPicker
                    tagEditor
                    if let summary = existing?.summary, !summary.isEmpty, existing?.text == text {
                        summaryCard(summary)
                    }
                    reflectionSection
                    if existing != nil {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete entry", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                }
                .padding(Theme.side)
            }
            .background(Theme.background)
            .navigationTitle((existing?.createdAt ?? .now).formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: save).fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let existing { context.delete(existing) }
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(!text.isEmpty && text != existing?.text)
        .onAppear { if existing == nil { focused = true } }
    }

    // MARK: Pieces

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How did it feel?").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(Mood.allCases, id: \.self) { option in
                    Button {
                        mood = (mood == option) ? nil : option
                        moodEdited = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.symbol).font(.title3).frame(height: 26)
                            Text(option.label).font(.caption2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .foregroundStyle(mood == option ? Color.white : option.color)
                        .background(mood == option ? option.color : option.color.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.label)
                    .accessibilityAddTraits(mood == option ? .isSelected : [])
                }
            }
            if mood == nil && existing == nil {
                Text("Leave it empty and Inkling will suggest one.").font(.caption).foregroundStyle(.tertiary)
            }
        }
    }

    private var tagEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            FlowLayout {
                ForEach(tags, id: \.self) { tag in
                    Button { tags.removeAll { $0 == tag }; tagsEdited = true } label: {
                        HStack(spacing: 4) { Text("#\(tag)"); Image(systemName: "xmark").font(.system(size: 9, weight: .bold)) }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove tag \(tag)")
                }
                TextField("Add tag", text: $newTag)
                    .font(.caption)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .frame(width: 80)
                    .onSubmit(addTag)
            }
        }
    }

    private func summaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(existing?.insightSource == .appleIntelligence ? "Summary · Apple Intelligence" : "Summary · on-device",
                  systemImage: existing?.insightSource == .appleIntelligence ? "sparkles" : "text.alignleft")
                .font(.footnote.weight(.semibold)).foregroundStyle(.tint)
            Text(summary).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card()
    }

    @ViewBuilder private var reflectionSection: some View {
        if engine.isAIAvailable && words >= 20 {
            VStack(alignment: .leading, spacing: 10) {
                Button { Task { await ask() } } label: {
                    HStack {
                        Label(questions.isEmpty ? "Ask me something" : "Ask again", systemImage: "sparkles")
                        if asking { ProgressView().controlSize(.small) }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(asking)
                ForEach(questions, id: \.self) { question in
                    Text(question)
                        .font(.system(.callout, design: .serif))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .card()
                }
                if askFailed {
                    Text("Couldn't think of a question just now. Try again in a moment.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Actions

    private func addTag() {
        tags = Tags.normalize(tags + [newTag])
        newTag = ""
        tagsEdited = true
    }

    private func ask() async {
        asking = true
        askFailed = false
        defer { asking = false }
        do { questions = try await engine.reflections(for: text) } catch { askFailed = true }
    }

    private func save() {
        if !newTag.isEmpty { addTag() }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry: JournalEntry
        if let existing {
            entry = existing
            if entry.text != trimmed { entry.text = trimmed; entry.updatedAt = .now }
        } else {
            entry = JournalEntry(text: trimmed)
            context.insert(entry)
        }
        if moodEdited { entry.mood = mood; entry.moodIsManual = mood != nil }
        if tagsEdited { entry.tags = tags; entry.tagsAreManual = true }
        try? context.save()
        engine.analyze(entry, in: context)
        dismiss()
    }
}
