import Foundation

/// Single source of truth for time-windowed impulse-savings math.
///
/// Each view used to re-implement its own `todaySaved / weekSaved / monthSaved`
/// helpers against the shared `ImpulseLog` collection, drifting slightly in the
/// process (Home's "this month" calc was missing the `resisted` filter).
/// Everyone should funnel through here so the hero numbers match across tabs.
nonisolated enum SavingsMath {

    // MARK: - Core

    /// Sum of resisted-impulse amounts in a half-open interval `[start, end)`.
    /// Pass `nil` for either bound to leave it open.
    static func totalResisted(
        from logs: [ImpulseLog],
        since start: Date? = nil,
        until end: Date? = nil
    ) -> Double {
        filtered(logs, since: start, until: end).reduce(0) { $0 + $1.amount }
    }

    static func countResisted(
        from logs: [ImpulseLog],
        since start: Date? = nil,
        until end: Date? = nil
    ) -> Int {
        filtered(logs, since: start, until: end).count
    }

    private static func filtered(
        _ logs: [ImpulseLog],
        since start: Date?,
        until end: Date?
    ) -> [ImpulseLog] {
        logs.filter { log in
            guard log.resisted else { return false }
            if let start, log.date < start { return false }
            if let end, log.date >= end { return false }
            return true
        }
    }

    // MARK: - Rolling windows

    static func today(logs: [ImpulseLog], now: Date = Date()) -> Double {
        let start = Calendar.current.startOfDay(for: now)
        return totalResisted(from: logs, since: start)
    }

    static func lastSevenDays(logs: [ImpulseLog], now: Date = Date()) -> Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return totalResisted(from: logs, since: start)
    }

    static func lastThirtyDays(logs: [ImpulseLog], now: Date = Date()) -> Double {
        let start = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        return totalResisted(from: logs, since: start)
    }

    // MARK: - Calendar months

    static func thisCalendarMonth(logs: [ImpulseLog], now: Date = Date()) -> Double {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return totalResisted(from: logs, since: start)
    }

    static func previousCalendarMonth(logs: [ImpulseLog], now: Date = Date()) -> Double {
        let calendar = Calendar.current
        guard let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) else {
            return 0
        }
        return totalResisted(from: logs, since: lastMonthStart, until: thisMonthStart)
    }

    /// This calendar month's total minus last calendar month's total.
    static func monthOverMonthDelta(logs: [ImpulseLog], now: Date = Date()) -> Double {
        thisCalendarMonth(logs: logs, now: now) - previousCalendarMonth(logs: logs, now: now)
    }
}
