//
//  SessionCompleteView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/3/26.
//

import SwiftUI

/// The screen shown when a practice session finishes: the score, the next
/// review date, and Done. Presentation only; `SessionView` has already saved
/// the session by the time this appears.
struct SessionCompleteView: View {
    let nextReview: Date?
    let correct: Int
    let total: Int
    /// Called once Done has finished its work; the parent dismisses the session.
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()

            Image(systemName: isPerfect ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(isPerfect ? .yellow : .green)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.sm) {
                Text("Session Complete!")
                    .font(.app(.title2, weight: .semibold))

                if total > 0 {
                    Text("\(correct) of \(total) correct")
                        .font(.app(.title3))
                        .foregroundStyle(scoreColor)
                }

                Text(scoreMessage)
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)

                if let nextReview {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                        Text("Next review: \(nextReview.formatted(.dateTime.month(.abbreviated).day().year()))")
                    }
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                }
            }

            Button("Done") {
                // After a finished session, ask once whether to remind them.
                // The system prompt only appears if iOS has never been asked.
                Task {
                    await NotificationScheduler.shared.offerRemindersAfterSession()
                    onDone()
                }
            }
            .buttonStyle(.primary)
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private var isPerfect: Bool {
        correct == total
    }

    private var scoreMessage: String {
        guard total > 0 else { return "Good work!" }
        let pct = Double(correct) / Double(total)
        switch pct {
        case 1.0...: return "Perfect recall!"
        case 0.7...: return "Great job!"
        case 0.5...: return "Keep it up!"
        default: return "Practice makes perfect."
        }
    }

    private var scoreColor: Color {
        guard total > 0 else { return .secondary }
        let pct = Double(correct) / Double(total)
        if pct >= 0.8 {
            return .green
        }
        if pct >= 0.5 {
            return .orange
        }
        return .red
    }
}

#Preview {
    SessionCompleteView(
        nextReview: Calendar.current.date(byAdding: .day, value: 3, to: .now),
        correct: 9,
        total: 10,
        onDone: {},
    )
}
