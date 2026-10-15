#if DEBUG
import Foundation
import SwiftData
import SwiftUI
import InklingCore

/// Debug-only helpers for screenshots and manual testing. Not compiled into Release builds.
///   -demo            fill an empty journal with a month of sample entries
///   -demoReset       delete everything first
///   -demoTab 0|1|2   open on Journal, Insights or Settings
enum DemoData {
    static var launchTab: RootView.Tab? {
        // Launch arguments arrive as strings, so read it as text first.
        let value = UserDefaults.standard.string(forKey: "demoTab").flatMap(Int.init)
        return value.flatMap(RootView.Tab.init(rawValue:))
    }

    @MainActor
    static func applyLaunchArguments(to container: ModelContainer) {
        let defaults = UserDefaults.standard
        let context = container.mainContext
        if defaults.bool(forKey: "demoReset") {
            try? context.delete(model: JournalEntry.self)
        }
        guard defaults.bool(forKey: "demo"),
              ((try? context.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0) == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for sample in samples {
            guard let day = calendar.date(byAdding: .day, value: -sample.daysAgo, to: today),
                  let when = calendar.date(byAdding: .hour, value: sample.hour, to: day) else { continue }
            let entry = JournalEntry(text: sample.text, createdAt: when)
            entry.mood = Mood(rawValue: sample.mood)
            entry.tags = sample.tags
            entry.summary = sample.summary
            entry.insightSource = .appleIntelligence
            entry.analyzedAt = when
            context.insert(entry)
        }
        if let lastYear = calendar.date(byAdding: .year, value: -1, to: today),
           let when = calendar.date(byAdding: .hour, value: 20, to: lastYear) {
            let entry = JournalEntry(text: "First week at the new desk. Everything is unfamiliar, but the team ate lunch together and I stopped feeling like a guest by Friday.", createdAt: when)
            entry.mood = .good
            entry.tags = ["work", "new-start"]
            entry.summary = "A nervous first week at a new job that ended up feeling welcoming."
            entry.insightSource = .appleIntelligence
            entry.analyzedAt = when
            context.insert(entry)
        }
        try? context.save()
    }

    private struct Sample {
        let daysAgo: Int, hour: Int, mood: Int
        let text: String, summary: String
        let tags: [String]
    }

    private static let samples: [Sample] = [
        .init(daysAgo: 0, hour: 8, mood: 4,
              text: "Slow morning, and for once I let it be slow. Coffee on the balcony, no phone, just the street waking up. I think I needed this more than the extra hour of sleep.",
              summary: "A deliberately slow morning that felt restorative.", tags: ["morning", "rest", "calm"]),
        .init(daysAgo: 1, hour: 21, mood: 5,
              text: "The demo went better than I dared hope. Priya asked for the code walkthrough afterwards, which is the nicest thing a reviewer can say. Celebrated with noodles.",
              summary: "A successful project demo that earned praise from a colleague.", tags: ["work", "win", "food"]),
        .init(daysAgo: 2, hour: 22, mood: 3,
              text: "Long day of small meetings. Nothing went wrong, nothing went especially right. Mostly tired. Going to bed early.",
              summary: "An uneventful, tiring day of meetings.", tags: ["work", "tired"]),
        .init(daysAgo: 3, hour: 19, mood: 4,
              text: "Ran 5k along the river before dinner, first time without stopping. Legs hurt, mind feels clear. I should do this every week.",
              summary: "A first non-stop 5k run that left them feeling clear-headed.", tags: ["running", "health"]),
        .init(daysAgo: 4, hour: 20, mood: 2,
              text: "Argued with Dad about the move again. We both said things quickly and meant them less than they sounded. I should call tomorrow.",
              summary: "A tense argument with their father about moving, with a plan to reconcile.", tags: ["family", "moving"]),
        .init(daysAgo: 6, hour: 18, mood: 4,
              text: "Finally finished the bookshelf. It leans slightly to the left and I love it anyway. Spent the evening putting books back in an order only I understand.",
              summary: "Finished building a slightly crooked bookshelf and enjoyed arranging books.", tags: ["home", "making"]),
        .init(daysAgo: 7, hour: 23, mood: 3,
              text: "Couldn't sleep. Mind kept running through tomorrow's to-do list. Wrote it all down at midnight and it looked smaller on paper.",
              summary: "Restless night eased by writing the to-do list down.", tags: ["sleep", "stress"]),
        .init(daysAgo: 9, hour: 17, mood: 5,
              text: "Sunday at the market with Maya. Bought far too many tomatoes, laughed about it for an hour. Days like this are what I want more of.",
              summary: "A joyful market outing with a friend.", tags: ["friends", "weekend", "food"]),
        .init(daysAgo: 10, hour: 21, mood: 4,
              text: "Started the Swift course again, properly this time. Built a tiny app that stores notes. It crashed twice and then it didn't.",
              summary: "Restarted learning Swift and got a small notes app working.", tags: ["learning", "swift"]),
        .init(daysAgo: 12, hour: 22, mood: 2,
              text: "Rough one. Missed the train, spilled coffee on my shirt before the interview, and still managed to be anxious the whole afternoon.",
              summary: "A day of small mishaps and anxiety before an interview.", tags: ["work", "anxiety"]),
        .init(daysAgo: 13, hour: 20, mood: 4,
              text: "The interview went fine after all. They liked the portfolio apps and asked a lot about the receipt scanner. Cautiously optimistic.",
              summary: "An interview that went better than feared, with interest in their apps.", tags: ["work", "apps"]),
        .init(daysAgo: 15, hour: 19, mood: 3,
              text: "Quiet evening, laundry, and a documentary about deep sea creatures. Not productive, but I didn't need to be.",
              summary: "A restful, unproductive evening at home.", tags: ["rest", "home"]),
        .init(daysAgo: 16, hour: 21, mood: 5,
              text: "Surprise call from Arjun after two years. We talked until my phone nearly died. Some friendships just wait for you.",
              summary: "Reconnected with an old friend after two years.", tags: ["friends", "gratitude"]),
        .init(daysAgo: 18, hour: 18, mood: 3,
              text: "Rain all day. Reorganised my desk, cleared the inbox, and made soup. A small, tidy day.",
              summary: "A rainy day spent tidying and cooking.", tags: ["home", "food"]),
        .init(daysAgo: 20, hour: 22, mood: 4,
              text: "Climbed the hill behind the old town for sunset. Everyone else had left by the time the sky turned orange, so I had it to myself.",
              summary: "A solitary sunset hike that felt peaceful.", tags: ["hiking", "calm"]),
        .init(daysAgo: 22, hour: 20, mood: 2,
              text: "Feeling behind on everything. Every list I make grows two new items. I wonder whether it's the work or just how I look at it.",
              summary: "Feeling overwhelmed by growing task lists.", tags: ["stress", "work"]),
        .init(daysAgo: 24, hour: 21, mood: 4,
              text: "Cooked dinner for the flat for the first time. The curry was a bit too hot but everyone had seconds, which feels like a review.",
              summary: "Cooked a well-received dinner for housemates.", tags: ["food", "friends"]),
        .init(daysAgo: 27, hour: 19, mood: 3,
              text: "Back to the gym after a long gap. Light weights, short session. Happy to have started, whatever the numbers say.",
              summary: "Returned to the gym gently after a long break.", tags: ["health", "habits"]),
    ]
}
#endif
