import Foundation

public enum Search {
    /// Every word of the query must appear somewhere in the text or tags, ignoring case and accents.
    /// An empty query matches everything.
    public static func matches(query: String, text: String, tags: [String] = []) -> Bool {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return true }
        let haystack = ([text] + tags).joined(separator: " ")
        return words.allSatisfy {
            haystack.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
