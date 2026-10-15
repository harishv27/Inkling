import Foundation

public enum Prompts {
    public static let all: [String] = [
        "What is one thing that went better than you expected today?",
        "Who made your day a little easier, and how?",
        "What are you putting off, and what is the smallest first step?",
        "Describe a moment today you would like to remember.",
        "What drained your energy today, and what gave it back?",
        "What are you looking forward to this week?",
        "Write about something you learned recently.",
        "What would make tomorrow a good day?",
        "What worry is taking more space than it deserves?",
        "What did you do today only because you wanted to?",
        "Which small habit is helping you most right now?",
        "What would you tell yourself a year ago?",
        "Describe your day in three words, then say why.",
        "What are you grateful for that you usually overlook?",
        "When did you feel most like yourself today?",
        "What is a decision you are avoiding?",
        "What conversation stayed with you?",
        "What did you notice today that you normally miss?",
        "What is one thing you would do differently?",
        "What are you proud of this week, however small?",
        "What does a perfect ordinary day look like for you?",
        "What do you need more of right now? What do you need less of?",
        "Write about a place that makes you feel calm.",
        "What is something you forgave yourself for lately?",
        "What is a goal that has quietly changed?",
        "Who would you like to get back in touch with?",
        "What is your body telling you today?",
        "What did you say yes to that you should have said no to?",
        "What is one thing you are curious about?",
        "How would you like to feel at the end of this week?",
    ]

    /// The same prompt all day, a different one tomorrow, and no repeats for a month.
    public static func forDay(_ date: Date = .now, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }
}
