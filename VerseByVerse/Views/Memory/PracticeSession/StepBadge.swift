//
//  StepBadge.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/5/26.
//

import SwiftUI

/// The pill at the top of an activity that says whether it counts: "Scored"
/// for unaided recall, "Warm-up" or "Retry" for steps that don't.
struct StepBadge: View {
    let step: ActivityStep

    private var label: LocalizedStringKey {
        if step.isScored {
            "Scored"
        } else if step.isRetry {
            "Retry"
        } else {
            "Warm-up"
        }
    }

    var body: some View {
        Text(label)
            .font(.app(.caption, weight: .semibold))
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(step.isScored ? Color.appAccent.opacity(0.15) : Color.secondary.opacity(0.15), in: Capsule())
            .foregroundStyle(step.isScored ? Color.appAccent : Color.secondary)
            .accessibilityAddTraits(.isHeader)
            // VoiceOver still hears which activity this is.
            .accessibilityLabel("\(step.activityType), \(step.isScored ? "scored" : "not scored")")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.md) {
        StepBadge(step: .verbalRecite)
        StepBadge(step: .everyOtherWord(phase: 0))
        StepBadge(step: .everyWord(allowsRetry: true))
        StepBadge(step: .everyWordRetry)
    }
    .environment(\.font, .app())
}
