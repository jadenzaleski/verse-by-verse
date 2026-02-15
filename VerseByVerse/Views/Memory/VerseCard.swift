//
//  VerseCard.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 2/8/26.
//

import SwiftUI

struct VerseCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("John 3:16")
                    .font(.app(weight: .semibold))
                Spacer()
                Text("ESV")
                    .environment(\.font, .app(.caption))
            }
            Text("For God so loved the world that he gave is only son, that "
                + "whoever believe in him shall not perish but have eternal life.")
                .lineLimit(2)
                .font(.app(.subheadline))

            ProgressView(value: 0.50)
                .progressViewStyle(.linear)
            HStack {
                Text("Every 3 days")
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
    VerseCard()
        .padding()
        .environment(\.font, .app())
}
