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

    private var sessionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for session in sessions where session.isCompleted {
            let day = calendar.startOfDay(for: session.startDate)
            counts[day, default: 0] += 1
        }
        return counts
    }

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 7)
    private let monthsToShow = 12

    var body: some View {
        let currentOffset = scrollID ?? 0
        let currentMonth = calendar.date(byAdding: .month, value: currentOffset, to: Date())?
            .formatted(.dateTime.month(.wide).year()) ?? ""

        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Practice History")
                    .font(.app(.title3))
                    .padding(.horizontal)
                Spacer()
                if currentOffset != 0 {
                    Button {
                        withAnimation {
                            scrollID = 0
                        }
                    } label: {
                        Text("Today")
                            .font(.app(.footnote, weight: .semibold))
                            .padding(.trailing)
                    }
                }
            }

            HStack {
                Button {
                    withAnimation { scrollID = currentOffset - 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appAccent)
                }
                .disabled(currentOffset <= -monthsToShow)

                Spacer()
                Text(currentMonth)
                    .font(.app(.body, weight: .semibold))
                Spacer()

                Button {
                    withAnimation { scrollID = currentOffset + 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.appAccent)
                }
                .disabled(currentOffset >= 0)
            }
            .padding(.horizontal)

            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
            LazyVGrid(columns: columns) {
                ForEach(0 ..< 7, id: \.self) { i in Text(dayLabels[i]) }
            }
            .font(.app(.caption, weight: .semibold))
            .padding(.top, AppSpacing.xs)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(-monthsToShow ... 0, id: \.self) { offset in
                        monthGrid(for: offset)
                            .containerRelativeFrame(.horizontal)
                            .id(offset)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let day = selectedDayStart {
                    Text(day, format: .dateTime.weekday(.wide).month().day())
                        .font(.app(.subheadline, weight: .semibold))
                    Text("\(selectedDayCount) Practice \(selectedDayCount == 1 ? "Session" : "Sessions")")
                        .font(.app(.caption))
                }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
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
                let isToday = calendar.isDateInToday(date) && inCurrentMonth

                Circle()
                    .fill(inCurrentMonth ? heatmapColor(for: count) : Color.secondary.opacity(0.05))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        ZStack {
                            Text(date, format: .dateTime.day())
                                .font(.app(.caption, weight: isToday ? .heavy : .medium))
                                .foregroundStyle(inCurrentMonth ? .primary : .tertiary)
                            if isSelected {
                                Circle().stroke(Color.appAccent, lineWidth: 3)
                            }
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture { selectedDate = date }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, AppSpacing.xs)
    }

    private func daysInMonth(for date: Date) -> [Date] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: date),
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)
        else { return [] }

        let offset = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date] = []

        let prevCount = calendar.range(of: .day, in: .month, for: previousMonth)!.count
        if offset > 0 {
            for day in (prevCount - offset + 1) ... prevCount {
                if let currentDay = calendar.date(
                    bySetting: .day, value: day, of: previousMonth,
                ) {
                    days.append(currentDay)
                }
            }
        }
        for day in range {
            if let currentDay = calendar.date(
                byAdding: .day, value: day - 1, to: firstOfMonth,
            ) {
                days.append(currentDay)
            }
        }
        let needed = max(0, 42 - days.count)
        for day in 1 ... max(1, needed) {
            if day > needed { break }
            if let currentDay = calendar.date(bySetting: .day, value: day, of: nextMonth) { days.append(currentDay) }
        }

        return days
    }

    private func heatmapColor(for count: Int) -> Color {
        guard count > 0 else { return Color.primary.opacity(0.05) }
        return Color.appAccent.opacity(min(Double(count) * 0.2 + 0.1, 1.0))
    }
}

#Preview {
    let now = Date()
    let cal = Calendar.current
    let sessions: [PracticeSession] = (0 ..< 80).map { i in
        PracticeSession(
            id: i,
            userId: "u1",
            passageId: 1,
            startDate: cal.date(byAdding: .day, value: -Int.random(in: 0 ..< 180), to: now)!,
            endDate: cal.date(byAdding: .day, value: -Int.random(in: 0 ..< 180), to: now),
            score: 0.8,
            rating: 3,
            scheduledDays: 5,
            elapsedDays: 4,
            state: 1,
        )
    }

    PracticeHistoryCalendar(sessions: sessions)
        .environment(\.font, .app())
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .padding()
}
