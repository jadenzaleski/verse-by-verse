//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @AppStorage(.displayName) private var displayName = ""
    @Query private var passages: [Passage]
    @Query private var verses: [Verse]
    @Query private var sessions: [PracticeSession]
    private let log = AppLog.category("HomeView")

    @State private var practicePassage: Passage?
    @State private var practiceVerse: Verse?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Good night"
        }
    }

    private var duePassages: [Passage] {
        let now = Date()
        return passages
            .filter { $0.isDue(at: now) }
            .sorted {
                ($0.nextPractice ?? .distantPast, $0.reference) < ($1.nextPractice ?? .distantPast, $1.reference)
            }
    }

    /// Standalone verses that are due — verses inside passages are practiced
    /// through their passage instead.
    private var dueVerses: [Verse] {
        let now = Date()
        return verses
            .filter { $0.addedDirectly && $0.isDue(at: now) }
            .sorted {
                ($0.nextPractice ?? .distantPast, $0.reference) < ($1.nextPractice ?? .distantPast, $1.reference)
            }
    }

    private var weeklyCompletion: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return Array(repeating: false, count: 7)
        }
        return (0 ..< 7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek), day <= today else {
                return false
            }
            return sessions.contains {
                $0.isCompleted && calendar.isDate($0.startDate, inSameDayAs: day)
            }
        }
    }

    private var currentStreak: Int {
        PracticeStats.currentStreak(from: sessions)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if !networkMonitor.isFullyOnline {
                    NetworkWidget(issue: networkMonitor.isDeviceOnline ? .serverUnreachable : .deviceOffline)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                StreakWidget(completed: weeklyCompletion, streakCount: currentStreak)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                upNextSection
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                PracticeHistoryCalendar(sessions: sessions)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .padding(.horizontal)
        }
        .sheet(item: $practicePassage) { passage in
            SessionView(passage: passage)
        }
        .sheet(item: $practiceVerse) { verse in
            SessionView(verse: verse)
        }
        .navigationTitle("Home")
        .toolbarTitleDisplayMode(.large)
        .navigationSubtitle(displayName.isEmpty ? "\(greeting)!" : "\(greeting) \(displayName)!")
    }

    // MARK: - Up Next

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Up Next")
                .font(.app(.title3))
                .padding(.horizontal)
                .padding(.top)

            if passages.isEmpty, verses.isEmpty {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("No passages yet")
                            .font(.app(.body, weight: .semibold))
                        Text("Add one in the Memory tab to get started.")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else if duePassages.isEmpty, dueVerses.isEmpty {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("All caught up!")
                            .font(.app(.body, weight: .semibold))
                        Text("No passages due for review.")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upNextItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().padding(.horizontal)
                        }
                        Button {
                            switch item {
                            case let .passage(passage): practicePassage = passage
                            case let .verse(verse): practiceVerse = verse
                            }
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(item.reference)
                                        .font(.app(.body, weight: .semibold))
                                    Text(badgeText(isNew: item.isNew, nextPractice: item.nextPractice))
                                        .font(.app(.caption))
                                        .foregroundStyle(badgeColor(isNew: item.isNew, nextPractice: item.nextPractice))
                                }
                                Spacer()
                                Text("Practice")
                                    .font(.app(.subheadline, weight: .semibold))
                                    .padding(.horizontal, AppSpacing.lg)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(Color.appAccent, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, AppSpacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, AppSpacing.xs)
            }
        }
    }

    // MARK: - Up Next items

    private enum UpNextItem: Identifiable {
        case passage(Passage)
        case verse(Verse)

        var id: PersistentIdentifier {
            switch self {
            case let .passage(passage): passage.persistentModelID
            case let .verse(verse): verse.persistentModelID
            }
        }

        var reference: String {
            switch self {
            case let .passage(passage): passage.reference
            case let .verse(verse): verse.reference
            }
        }

        var isNew: Bool {
            switch self {
            case let .passage(passage): passage.isNew
            case let .verse(verse): verse.isNew
            }
        }

        var nextPractice: Date? {
            switch self {
            case let .passage(passage): passage.nextPractice
            case let .verse(verse): verse.nextPractice
            }
        }
    }

    private var upNextItems: [UpNextItem] {
        let items = duePassages.map(UpNextItem.passage) + dueVerses.map(UpNextItem.verse)
        return items.sorted {
            ($0.nextPractice ?? .distantPast, $0.reference) < ($1.nextPractice ?? .distantPast, $1.reference)
        }
    }

    // MARK: - Helpers

    private func badgeText(isNew: Bool, nextPractice: Date?) -> String {
        if isNew { return "New" }
        let days = Int(Date().timeIntervalSince(nextPractice ?? Date()) / 86400)
        return days < 1 ? "Due today" : "\(days)d overdue"
    }

    private func badgeColor(isNew: Bool, nextPractice: Date?) -> Color {
        if isNew { return .appAccent }
        let days = Int(Date().timeIntervalSince(nextPractice ?? Date()) / 86400)
        return days < 1 ? .orange : .red
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(PreviewData.container)
            .environment(\.font, .app())
            .environment(NetworkMonitor.shared)
    }
}
