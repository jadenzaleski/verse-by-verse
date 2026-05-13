//
//  PassageCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/8/26.
//

import SwiftUI

struct PassageCard: View {
    @State private var progress: Double = 4
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("John 3:16")
                    .font(.app(weight: .semibold))
                Spacer()
                Text("ESV")
                    .environment(\.font, .app(.caption))
            }

            Text("For God so loved the world that he gave his only son, that "
                + "whoever believes in him shall not perish but have eternal life.")
                .lineLimit(2)
                .font(.app(.subheadline))

            SegmentedProgressBar(
                totalSegments: 10,
                completedSegments: Int(progress),
            )

            HStack {
                Text("Due in 3 days")
                Spacer()
                Text("3 days ago")
            }
            .environment(\.font, .app(.caption))
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    PassageCard()
        .padding()
        .environment(\.font, .app())
}
