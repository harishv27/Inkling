import Charts
import SwiftData
import SwiftUI
import InklingCore

struct InsightsView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    private var dates: [Date] { entries.map(\.createdAt) }
    private var moodPoints: [DayMood] {
        Trends.dailyMood(entries.compactMap { e in e.mood.map { (e.createdAt, $0.rawValue) } }, days: 30)
    }
    private var weeks: [WeekWords] { Trends.weeklyWords(entries.map { ($0.createdAt, $0.wordCount) }, weeks: 8) }
    private var topTags: [(tag: String, count: Int)] { Tags.ranked(entries.map(\.tags), limit: 10) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    ContentUnavailableView("Nothing to chart yet", systemImage: "chart.xyaxis.line",
                                           description: Text("Write a few entries and your patterns show up here."))
                        .padding(.top, 60)
                } else {
                    VStack(spacing: 16) {
                        statTiles
                        moodChart
                        wordsChart
                        if !topTags.isEmpty { tagsCard }
                    }
                    .padding(Theme.side)
                }
            }
            .background(Theme.background)
            .navigationTitle("Insights")
        }
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            tile(value: "\(Streaks.current(dates))", label: "Day streak", symbol: "flame.fill", color: .orange)
            tile(value: "\(Streaks.longest(dates))", label: "Best streak", symbol: "trophy.fill", color: .yellow)
            tile(value: "\(entries.count)", label: "Entries", symbol: "book.fill", color: .accentColor)
        }
    }

    private func tile(value: String, label: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(value).font(.title.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card()
        .accessibilityElement(children: .combine)
    }

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mood, last 30 days").font(.headline)
                Spacer()
                if let average = Trends.averageMood(moodPoints) {
                    Text("Average \(Mood(clamping: Int(average.rounded())).label)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if moodPoints.count < 2 {
                Text("Add a mood to a few more days to see the trend.")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 30)
            } else {
                Chart(moodPoints) { point in
                    LineMark(x: .value("Day", point.day, unit: .day), y: .value("Mood", point.average))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)
                    PointMark(x: .value("Day", point.day, unit: .day), y: .value("Mood", point.average))
                        .foregroundStyle(Mood(clamping: Int(point.average.rounded())).color)
                        .symbolSize(40)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 3, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel { if let v = value.as(Int.self) { Text(Mood(clamping: v).label) } }
                    }
                }
                .frame(height: 170)
            }
        }
        .padding(16).card()
    }

    private var wordsChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Words per week").font(.headline)
            Chart(weeks) { week in
                BarMark(x: .value("Week", week.weekStart, unit: .weekOfYear), y: .value("Words", week.words))
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
            .frame(height: 140)
        }
        .padding(16).card()
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What you write about").font(.headline)
            FlowLayout {
                ForEach(topTags, id: \.tag) { item in
                    Text("#\(item.tag) · \(item.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.tint.opacity(0.12), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).card()
    }
}
