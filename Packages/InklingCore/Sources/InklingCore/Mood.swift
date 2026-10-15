import Foundation

/// How a day felt, on a five point scale. The raw value is what gets stored and charted.
public enum Mood: Int, CaseIterable, Codable, Sendable {
    case rough = 1, low, okay, good, great

    public var label: String {
        switch self {
        case .rough: "Rough"
        case .low: "Low"
        case .okay: "Okay"
        case .good: "Good"
        case .great: "Great"
        }
    }

    /// Clamps any number onto the scale, so a model that answers 0 or 9 can't break the UI.
    public init(clamping value: Int) {
        self = Mood(rawValue: min(5, max(1, value))) ?? .okay
    }

    /// Maps a sentiment score in -1...1 (Apple's NaturalLanguage range) onto the scale.
    public init(sentiment score: Double) {
        switch score {
        case ..<(-0.6): self = .rough
        case ..<(-0.2): self = .low
        case ..<0.2: self = .okay
        case ..<0.6: self = .good
        default: self = .great
        }
    }
}
