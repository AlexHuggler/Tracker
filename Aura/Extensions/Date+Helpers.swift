import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return Calendar.current.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    var daysInMonth: Int {
        let range = Calendar.current.range(of: .day, in: .month, for: self)
        return range?.count ?? 30
    }

    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var shortDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: other)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return abs(components.day ?? 0)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    static func datesInMonth(of date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = date.startOfMonth
        let daysInMonth = date.daysInMonth

        return (0..<daysInMonth).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfMonth)
        }
    }

    var firstWeekdayOfMonth: Int {
        Calendar.current.component(.weekday, from: startOfMonth)
    }
}
