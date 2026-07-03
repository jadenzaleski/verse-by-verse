//
//  HomeView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/25/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(PassageStore.self) private var passageStore
    @Environment(PracticeStore.self) private var practiceStore
    private let log = AppLog.category("HomeView")

    @State private var practicePassage: UserPassage?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Good night"
        }
    }

    private var duePassages: [UserPassage] {
        let now = Date()
        let overdue = passageStore.userPassages
            .filter { $0.nextPractice != nil && $0.nextPractice! <= now }
            .sorted { ($0.nextPractice ?? now) < ($1.nextPractice ?? now) }
        let new = passageStore.userPassages
            .filter { $0.reps == 0 && $0.nextPractice == nil }
        return overdue + new
    }

    private var weeklyCompletion: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0 ..< 7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            guard day <= today else { return false }
            return practiceStore.sessions.contains {
                $0.isCompleted && calendar.isDate($0.startDate, inSameDayAs: day)
            }
        }
    }

    private var currentStreak: Int {
        PracticeStats.currentStreak(from: practiceStore.sessions)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                StreakWidget(completed: weeklyCompletion, streakCount: currentStreak)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                upNextSection
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                PracticeHistoryCalendar(sessions: practiceStore.sessions)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal)
        }
        .refreshable {
            log.debug("refreshed")
            await userStore.loadUser(lookInCache: false)
            await passageStore.loadMyPassages()
            await practiceStore.loadMyPracticeSessions()
        }
        .task {
            if passageStore.userPassages.isEmpty {
                await passageStore.loadMyPassages()
            }
            if practiceStore.sessions.isEmpty {
                await practiceStore.loadMyPracticeSessions()
            }
        }
        .sheet(item: $practicePassage) { passage in
            SessionView(passage: passage)
        }
        .navigationTitle("Home")
        .toolbarTitleDisplayMode(.large)
        .navigationSubtitle("\(greeting) \(userStore.currentUser?.firstName ?? "")!")
    }

    // MARK: - Up Next

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Up Next")
                .font(.app(.title3))
                .padding(.horizontal)
                .padding(.top)

            if passageStore.state == .loading, passageStore.userPassages.isEmpty {
                HStack {
                    ProgressView()
                        .padding(.trailing, 4)
                    Text("Loading passages…")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            } else if passageStore.userPassages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No passages yet")
                            .font(.app(.body, weight: .semibold))
                        Text("Add one in the Memory tab to get started.")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else if duePassages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
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
                    ForEach(Array(duePassages.enumerated()), id: \.element.id) { index, passage in
                        if index > 0 {
                            Divider().padding(.horizontal)
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(passage.reference)
                                    .font(.app(.body, weight: .semibold))
                                Text(badgeText(for: passage))
                                    .font(.app(.caption))
                                    .foregroundStyle(badgeColor(for: passage))
                            }
                            Spacer()
                            Button {
                                practicePassage = passage
                            } label: {
                                Text("Practice")
                                    .font(.app(.subheadline, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.accentColor, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { practicePassage = passage }
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Helpers

    private func badgeText(for passage: UserPassage) -> String {
        if passage.reps == 0 { return "New" }
        let days = Int(Date().timeIntervalSince(passage.nextPractice ?? Date()) / 86400)
        return days < 1 ? "Due today" : "\(days)d overdue"
    }

    private func badgeColor(for passage: UserPassage) -> Color {
        if passage.reps == 0 { return .accentColor }
        let days = Int(Date().timeIntervalSince(passage.nextPractice ?? Date()) / 86400)
        return days < 1 ? .orange : .red
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(\.font, .app())
            .environment(UserStore.shared)
            .environment(PassageStore.shared)
            .environment(PracticeStore.shared)
    }
}
