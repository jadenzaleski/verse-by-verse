//
//  PracticeCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/13/26.
//

import SwiftUI

struct PracticeCard: View {
    @Binding var showPractice: Bool
    let nextPracticeDate: Date?
    let isNew: Bool

    private var dueDateText: String {
        guard let next = nextPracticeDate else {
            return isNew ? "New" : "Ready to practice"
        }

        // Normalize to the current moment
        let now = Date()

        // Compute difference components between now and the next practice date
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: next)
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        // If it's overdue (next is in the past), compute how overdue it is
        if next < now {
            let overdueComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: next, to: now)
            let oDays = overdueComponents.day ?? 0
            let oHours = overdueComponents.hour ?? 0
            let oMinutes = overdueComponents.minute ?? 0

            if oDays > 0 {
                return "Overdue by \(oDays) day\(oDays == 1 ? "" : "s")"
            } else if oHours > 0 {
                return "Overdue by \(oHours) hour\(oHours == 1 ? "" : "s")"
            } else if oMinutes > 0 {
                return "Overdue by \(oMinutes) minute\(oMinutes == 1 ? "" : "s")"
            } else {
                return "Due now"
            }
        }

        // If due today or in the future
        if days == 0 {
            if hours > 0 {
                return "Due in \(hours) hour\(hours == 1 ? "" : "s")"
            } else if minutes > 0 {
                return "Due in \(minutes) minute\(minutes == 1 ? "" : "s")"
            } else {
                return "Due now"
            }
        } else {
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        }
    }

    private var dueDateColor: Color {
        guard let next = nextPracticeDate else {
            return isNew ? .appAccent : .green
        }

        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: next),
        ).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Practice")
                .font(.app(.title2))

            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(dueDateColor)
                    .frame(width: 8, height: 8)
                Text(dueDateText)
                    .font(.app(.subheadline))
                    .foregroundStyle(dueDateColor)
            }

            Button {
                showPractice = true
            } label: {
                Text("Start Practice")
                    .font(.app(.body, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppRadius.md)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: AppRadius.md))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            if let next = nextPracticeDate {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "calendar")
                    Text("Next review: \(next.formatted(.dateTime.month(.abbreviated).minute().hour().day().year()))")
                }
                .font(.app(.caption))
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

#Preview {
    PracticeCard(showPractice: .constant(false),
                 nextPracticeDate: PreviewData.samplePassage.nextPractice,
                 isNew: PreviewData.samplePassage.isNew)
}
