import Foundation

public enum Tags {
    /// Lowercases, drops a leading `#`, turns spaces into hyphens, removes duplicates and keeps the first
    /// `limit`. Order is preserved so the model's most relevant tag stays first.
    public static func normalize(_ raw: [String], limit: Int = 5) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for item in raw {
            var tag = item.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            while tag.hasPrefix("#") { tag.removeFirst() }
            tag = tag.split(whereSeparator: \.isWhitespace).joined(separator: "-")
            tag = tag.filter { $0.isLetter || $0.isNumber || $0 == "-" }
            guard !tag.isEmpty, seen.insert(tag).inserted else { continue }
            out.append(tag)
            if out.count == limit { break }
        }
        return out
    }

    /// Tags used across entries, most used first. Ties are broken alphabetically so the order is stable.
    public static func ranked(_ lists: [[String]], limit: Int = 8) -> [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for list in lists { for tag in Set(list) { counts[tag, default: 0] += 1 } }
        return counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }
}

/// Offline fallback for devices without Apple Intelligence: the most repeated meaningful words become tags.
public enum KeywordTagger {
    static let stopWords: Set<String> = [
        "the", "and", "a", "an", "to", "of", "in", "on", "at", "for", "with", "was", "were", "is", "are", "am",
        "be", "been", "it", "its", "this", "that", "these", "those", "i", "me", "my", "we", "our", "you", "your",
        "he", "she", "they", "them", "his", "her", "their", "but", "so", "or", "as", "if", "then", "than", "too",
        "very", "just", "really", "also", "not", "no", "had", "has", "have", "do", "did", "does", "from", "by",
        "about", "into", "out", "up", "down", "over", "after", "before", "today", "day", "went", "got", "get",
        "some", "what", "when", "where", "which", "who", "would", "could", "should", "can", "will", "all", "one",
        "ive", "im", "dont", "didnt", "its", "thats", "because", "while", "still", "much", "more", "lot",
    ]

    public static func tags(from text: String, limit: Int = 3) -> [String] {
        var counts: [String: Int] = [:]
        var firstSeen: [String: Int] = [:]
        let words = text.lowercased().split { !($0.isLetter || $0 == "'") }
        for (index, word) in words.enumerated() {
            let w = String(word).replacingOccurrences(of: "'", with: "")
            guard w.count >= 4, !stopWords.contains(w) else { continue }
            counts[w, default: 0] += 1
            firstSeen[w] = firstSeen[w] ?? index
        }
        return counts
            .sorted {
                if $0.value != $1.value { return $0.value > $1.value }
                return firstSeen[$0.key, default: 0] < firstSeen[$1.key, default: 0]
            }
            .prefix(limit)
            .map(\.key)
    }
}
