import Foundation

/// A fixed calendar so tests give the same answer in every time zone and on every day.
let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    c.firstWeekday = 2
    return c
}()

func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}
