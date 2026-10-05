import Foundation

struct WeeklyGoal: Equatable {
    let metric: ActivityMetric
    let value: Int

    init?(metric: ActivityMetric, value: Int) {
        guard value > 0 else { return nil }
        self.metric = metric
        self.value = value
    }
}

enum GoalEngine {
    static func propose(from baseline: RecentBaseline) -> WeeklyGoal? {
        let average = baseline.weeklyAverage
        guard average.isFinite, average > 0 else { return nil }
        let candidate = average * Constants.growthFactor
        let increment = baseline.metric == .steps ? Constants.stepsIncrement : Constants.energyIncrement
        var value = (candidate / increment).rounded() * increment
        if value <= average { value = candidate.rounded(.down) + 1 }
        guard value.isFinite, value > average, value > 0, value < Double(Int.max) else { return nil }
        return WeeklyGoal(metric: baseline.metric, value: Int(value))
    }
}

private extension GoalEngine {
    enum Constants {
        static let growthFactor = 1.05
        static let stepsIncrement = 100.0
        static let energyIncrement = 10.0
    }
}

struct ActiveWeek: Equatable {
    let interval: DateInterval
    let queryEnd: Date
    let daysRemaining: Int
    let timeZone: TimeZone

    init(now: Date, calendar: Calendar) throws {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = Constants.monday
        guard let week = mondayCalendar.dateInterval(of: .weekOfYear, for: now),
              let days = mondayCalendar.dateComponents([.day], from: mondayCalendar.startOfDay(for: now), to: week.end)
              .day,
              days > 0
        else { throw Failure.invalidCalendar }
        interval = week
        queryEnd = now
        daysRemaining = days
        timeZone = calendar.timeZone
    }
}

private extension ActiveWeek {
    enum Constants { static let monday = 2 }
    enum Failure: Error { case invalidCalendar }
}

struct WeeklyProgress: Equatable {
    let goal: WeeklyGoal
    let value: Double
    let week: ActiveWeek
    let queriedAt: Date

    var gap: Double {
        max(0, Double(goal.value) - value)
    }

    var isCompleted: Bool {
        value >= Double(goal.value)
    }
}

enum WeeklyProgressState: Equatable {
    case loading
    case available(WeeklyProgress)
    case insufficient
    case failed
}
