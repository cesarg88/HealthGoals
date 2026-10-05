import Foundation

struct PatternWindow: Equatable {
    let calendar: Calendar
    let today: Date
    let intervals: [DateInterval]

    init(now: Date, calendar: Calendar) throws {
        let baseline = try BaselineWindow(now: now, calendar: calendar)
        self.calendar = calendar
        today = calendar.startOfDay(for: now)
        intervals = try baseline.intervals.flatMap { block in
            try (0 ..< Constants.daysPerBlock).map { index in
                guard let start = calendar.date(byAdding: .day, value: index, to: block.start),
                      let end = calendar.date(byAdding: .day, value: 1, to: start)
                else { throw Failure.invalidCalendar }
                return DateInterval(start: start, end: end)
            }
        }
    }
}

private extension PatternWindow {
    enum Constants { static let daysPerBlock = 7 }
    enum Failure: Error { case invalidCalendar }
}

struct HistoricalPattern: Equatable {
    let metric: ActivityMetric
    // Monday through Sunday, independent of Calendar.firstWeekday.
    let weekdayAverages: [Double]
    let historicalWeek: Double

    fileprivate init(metric: ActivityMetric, weekdayAverages: [Double], historicalWeek: Double) {
        self.metric = metric
        self.weekdayAverages = weekdayAverages
        self.historicalWeek = historicalWeek
    }

    func cumulativeFraction(at day: Date, calendar: Calendar) -> Double {
        let index = PatternCalculator.mondayIndex(for: day, calendar: calendar)
        return weekdayAverages.prefix(index).reduce(0, +) / historicalWeek
    }
}

enum PatternCalculator {
    static func calculate(
        metric: ActivityMetric,
        dailyTotals: [Double?],
        in window: PatternWindow
    ) -> HistoricalPattern? {
        guard dailyTotals.count == Constants.dayCount, window.intervals.count == Constants.dayCount else { return nil }
        var averages = Array(repeating: 0.0, count: Constants.daysPerWeek)
        var counts = Array(repeating: 0, count: Constants.daysPerWeek)
        for (interval, total) in zip(window.intervals, dailyTotals) {
            guard let total, total.isFinite, total >= 0 else { return nil }
            let index = mondayIndex(for: interval.start, calendar: window.calendar)
            // Divide first to preserve otherwise finite values without overflowing the four observations.
            averages[index] += total / Double(Constants.observationsPerWeekday)
            counts[index] += 1
        }
        let historicalWeek = averages.reduce(0, +)
        guard counts.allSatisfy({ $0 == Constants.observationsPerWeekday }),
              historicalWeek.isFinite, historicalWeek > 0 else { return nil }
        return HistoricalPattern(metric: metric, weekdayAverages: averages, historicalWeek: historicalWeek)
    }

    static func mondayIndex(for date: Date, calendar: Calendar) -> Int {
        (calendar.component(.weekday, from: date) + Constants.mondayOffset) % Constants.daysPerWeek
    }
}

private extension PatternCalculator {
    enum Constants {
        static let observationsPerWeekday = 4
        static let daysPerWeek = 7
        static let dayCount = observationsPerWeekday * daysPerWeek
        static let mondayOffset = 5
    }
}

enum PaceState: String, CaseIterable {
    case completed, ahead, onTrack, belowPace, unknown
}

enum PaceCalculator {
    static func state(
        for progress: WeeklyProgress,
        pattern: HistoricalPattern?,
        day: Date,
        calendar: Calendar
    ) -> PaceState {
        if progress.isCompleted { return .completed }
        guard let pattern, pattern.metric == progress.goal.metric else { return .unknown }
        let expected = Double(progress.goal.value) * pattern.cumulativeFraction(at: day, calendar: calendar)
        let tolerance = Double(progress.goal.value) * Constants.toleranceFraction
        if progress.value > expected + tolerance { return .ahead }
        if progress.value >= expected - tolerance { return .onTrack }
        return .belowPace
    }
}

private extension PaceCalculator {
    enum Constants { static let toleranceFraction = 0.05 }
}
