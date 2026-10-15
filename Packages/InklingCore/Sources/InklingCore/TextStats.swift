import Foundation

public enum TextStats {
    /// Words separated by any whitespace or newline. Punctuation on its own is not a word.
    public static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace)
            .filter { $0.contains(where: { $0.isLetter || $0.isNumber }) }
            .count
    }

    /// At 200 words a minute, never less than one minute for a non-empty entry.
    public static func readingMinutes(_ text: String) -> Int {
        let words = wordCount(text)
        return words == 0 ? 0 : max(1, Int((Double(words) / 200).rounded()))
    }

    /// First non-empty line, trimmed and cut at `limit` characters. Used as the entry's title in lists.
    public static func title(_ text: String, limit: Int = 60) -> String {
        let line = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
        guard line.count > limit else { return line }
        return String(line.prefix(limit)).trimmingCharacters(in: .whitespaces) + "…"
    }
}
