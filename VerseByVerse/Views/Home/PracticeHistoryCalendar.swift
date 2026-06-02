import SwiftUI

struct PracticeHistoryCalendar: View {
    let sessions: [PracticeSession]
    @State private var scrollID: Int? = 0
    @State private var selectedDate: Date?

    private var selectedDayStart: Date? {
        guard let selectedDate else { return nil }
        return calendar.startOfDay(for: selectedDate)
    }

    private var selectedDayCount: Int {
        guard let day = selectedDayStart else { return 0 }
        return sessionsByDay[day] ?? 0
    }

    private var selectedDayFormatted: String {
        guard let date = selectedDayStart else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        var result = formatter.string(from: date)
        let day = calendar.component(.day, from: date)
        let suffix = switch day {
        case 11, 12, 13: "th"
        default:
            switch day % 10 {
            case 1: "st"
            case 2: "nd"
            case 3: "rd"
            default: "th"
            }
        }
        result = result.replacingOccurrences(of: "\\b\\d+\\b", with: "\(day)\(suffix)", options: .regularExpression)
        return result
    }

    private let calendar = Calendar.current
    private static let daySpacing: CGFloat = 10
    private let columns = Array(repeating: GridItem(.flexible(), spacing: daySpacing), count: 7)
    private let monthsToShow = 12 // Show last year

    private var sessionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for session in sessions where session.isCompleted {
            let startOfDay = calendar.startOfDay(for: session.startDate)
            counts[startOfDay, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        let currentMonth = calendar.date(
            byAdding: .month, value: scrollID ?? 0,
            to: Date())?.formatted(.dateTime.month(.wide).year()
            ) ?? ""

        VStack(alignment: .leading, spacing: 15) {
            Text("Practice History")
                .font(.app(.title))
                .padding(.horizontal)
            HStack {
                Button {
                    withAnimation {
                        scrollID = (scrollID ?? 0) - 1
                    }
                } label: {
                    Image("lucide.chevron.left")
                        .foregroundStyle(.secondary)
                }
                .disabled(scrollID == -monthsToShow)

                Spacer()
                Text(currentMonth)
                    .font(.app(.body, weight: .semibold))
                Spacer()

                Button {
                    withAnimation {
                        scrollID = (scrollID ?? 0) + 1
                    }
                } label: {
                    Image("lucide.chevron.left")
                        .rotationEffect(Angle(degrees: 180))
                        .foregroundStyle(.secondary)
                }
                .disabled(scrollID == 0)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns) {
                Text("S")
                Text("M")
                Text("T")
                Text("W")
                Text("T")
                Text("F")
                Text("S")
            }
            .font(.app(.caption, weight: .semibold))
            .padding(.top, 5)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(-monthsToShow ... 0, id: \.self) { offset in
                        monthGrid(for: offset)
                            .containerRelativeFrame(.horizontal)
                            .id(offset)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID)

            VStack(alignment: .leading) {
                Text(selectedDayStart ?? .now, format: .dateTime.month().day().year())
                Text("\(selectedDayCount) Practice \(selectedDayCount == 1 ? "Session" : "Sessions")")
            }
            .font(.app(.subheadline))
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical)
        .onAppear {
            scrollID = 0
            selectedDate = Date()
        }
    }

    @ViewBuilder
    private func monthGrid(for offset: Int) -> some View {
        let monthDate = calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        let days = daysInMonth(for: monthDate)

        LazyVGrid(columns: columns) {
            ForEach(days.indices, id: \.self) { index in
                let date = days[index]
                let count = sessionsByDay[calendar.startOfDay(for: date)] ?? 0
                let isSelected = selectedDayStart == calendar.startOfDay(for: date)
                let inCurrentMonth = calendar.isDate(date, equalTo: monthDate, toGranularity: .month)
                let fontWeight = (calendar.isDateInToday(date) && inCurrentMonth) ? Font.Weight.heavy : Font.Weight.medium

                Circle()
                    .fill(inCurrentMonth ? heatmapColor(for: count) : Color.secondary.opacity(0.05))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        ZStack {
                            Text(date, format: .dateTime.day())
                                .font(.app(.caption, weight: fontWeight))
                                .foregroundStyle(inCurrentMonth ? .primary : .tertiary)
                            if isSelected {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 3)
                            }
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture {
                        selectedDate = date
                    }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }

    private func daysInMonth(for date: Date) -> [Date] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: date),
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = firstWeekday - 1 // 0 for Sunday

        var days: [Date] = []

        // Leading days from previous month
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
        if offset > 0 {
            let startDay = daysInPreviousMonth - offset + 1
            for day in startDay ... daysInPreviousMonth {
                if let date = calendar.date(bySetting: .day, value: day, of: previousMonth) {
                    days.append(date)
                }
            }
        }

        // Current month days
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Trailing days from next month to fill 42 cells
        let needed = max(0, 42 - days.count)
        if needed > 0 {
            for day in 1 ... needed {
                if let date = calendar.date(bySetting: .day, value: day, of: nextMonth) {
                    days.append(date)
                }
            }
        }

        return days
    }

    private func heatmapColor(for count: Int) -> Color {
        if count == 0 {
            return Color.primary.opacity(0.05)
        }
        let opacity = min(Double(count * 2) * 0.1, 1.0)
        return Color.accentColor.opacity(opacity)
    }
}

#Preview {
    let now = Date()
    let calendar = Calendar.current
    let sessions: [PracticeSession] = (0 ..< 300).map { i in
        PracticeSession(
            id: i,
            userId: "u1",
            passageId: 1,
            startDate: calendar.date(byAdding: .day, value: -Int.random(in: 0 ..< 365), to: now)!,
            endDate: nil,
            score: 0.8,
            rating: 3,
            scheduledDays: 5,
            elapsedDays: 4,
            state: 1,
        )
    }

    PracticeHistoryCalendar(sessions: sessions)
        .environment(\.font, .app())
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .padding()
}
