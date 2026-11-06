//
//  SessionPreviewView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/6/26.
//

import SwiftUI

/// An outline of the session ahead, shown before the first activity: one
/// linked step per activity, each marked as scored or warm-up. It's the same
/// for every session, new material or not. The session clock and progress
/// only start when the user taps Start.
struct SessionPreviewView: View {
    let steps: [ActivityStep]
    let onStart: () -> Void

    private struct Row: Identifiable {
        /// Position in the plan; the plan is fixed for the preview's lifetime.
        let id: Int
        let step: ActivityStep
    }

    /// The plan, plus the retry that follows Every Word when a word is missed.
    private var rows: [Row] {
        let hasRetry = steps.contains { step in
            if case .everyWord(allowsRetry: true) = step {
                true
            } else {
                false
            }
        }
        let outline = hasRetry ? steps + [.everyWordRetry] : steps
        return outline.enumerated().map { Row(id: $0.offset, step: $0.element) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Overview")
                            .font(.app(.title2, weight: .semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text("Only scored steps count toward your result.")
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(rows) { row in
                            stepRow(row, isLast: row.id == rows.count - 1)
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Start", action: onStart)
                .buttonStyle(.primary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
        }
    }

    private func stepRow(_ row: Row, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(spacing: 0) {
                Label(row.step.outlineTitle, systemImage: row.step.outlineSymbol)
                    .labelStyle(.iconOnly)
                    .font(.app(.title3))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(row.step.isScored ? Color.appAccent : Color.secondary)
                    .accessibilityHidden(true)
                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(row.step.outlineTitle)
                        .font(.app(.headline))
                    Text(row.step.outlineTag)
                        .font(.app(.caption2, weight: .semibold))
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(
                            row.step.isScored ? Color.appAccent.opacity(0.15) : Color.secondary.opacity(0.15),
                            in: Capsule(),
                        )
                        .foregroundStyle(row.step.isScored ? Color.appAccent : Color.secondary)
                }
                Text(row.step.outlineDetail)
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : AppSpacing.xl)
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    SessionPreviewView(steps: ActivityStep.standardPlan, onStart: {})
        .environment(\.font, .app())
}
