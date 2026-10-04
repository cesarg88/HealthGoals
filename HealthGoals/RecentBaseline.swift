import Foundation

struct BaselineWindow: Equatable {
    let calendar: Calendar
    let intervals: [DateInterval]

    init(now: Date, calendar: Calendar) throws {
        self.calendar = calendar
        let end = calendar.startOfDay(for: now)
        var intervals: [DateInterval] = []
        for index in (0 ..< Constants.blockCount).reversed() {
            guard let start = calendar.date(byAdding: .day, value: -(index + 1) * Constants.daysPerBlock, to: end),
                  let blockEnd = calendar.date(byAdding: .day, value: -index * Constants.daysPerBlock, to: end)
            else { throw Failure.invalidCalendar }
            intervals.append(DateInterval(start: start, end: blockEnd))
        }
        self.intervals = intervals
    }
}

private extension BaselineWindow {
    enum Constants {
        static let blockCount = 4
        static let daysPerBlock = 7
    }

    enum Failure: Error { case invalidCalendar }
}

struct RecentBaseline: Equatable {
    let metric: ActivityMetric
    let weeklyAverage: Double
}

enum BaselineCalculator {
    static func calculate(metric: ActivityMetric, weeklyTotals: [Double?]) -> RecentBaseline? {
        guard weeklyTotals.count == Constants.blockCount else { return nil }
        let usableTotals = weeklyTotals.compactMap { $0 }
        guard usableTotals.count == Constants.blockCount,
              usableTotals.allSatisfy({ $0.isFinite && $0 >= 0 })
        else { return nil }
        // Divide before adding to avoid overflow from otherwise finite weekly totals.
        let average = usableTotals.reduce(0) { $0 + $1 / Double(Constants.blockCount) }
        guard average.isFinite else { return nil }
        return RecentBaseline(metric: metric, weeklyAverage: average)
    }
}

private extension BaselineCalculator {
    enum Constants {
        static let blockCount = 4
    }
}

enum BaselineState: Equatable {
    case loading
    case available(RecentBaseline)
    case insufficient
    case failed
}
