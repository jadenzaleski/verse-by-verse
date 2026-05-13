//
//  PassageDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import SwiftUI

struct PassageDetailView: View {
    let passageID: Int
    var body: some View {
        VStack {
            HStack {
                Text("John 3:16-4:18")
                    .font(.app(.title))
                Spacer()
            }
            VStack {
                HStack {
                    Text("Memory Score")
                        .font(.app(.title2))
                    Spacer()
                    Button {
                        print("show help")
                    } label: {
                        Text("?")
                    }
                }
                SegmentedProgressBar(totalSegments: 10, completedSegments: 5, height: 25)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

            VStack {
                HStack {
                    Text("History")
                        .font(.app(.title2))
                    Spacer()
                }

                let now = Date()
                let calendar = Calendar.current
                let sessions: [PracticeSession] = [
                    PracticeSession(id: 1,
                                    date: calendar.date(byAdding: .day, value: -12, to: now)!,
                                    score: 0.85, stability: 2.5),
                    PracticeSession(id: 2,
                                    date: calendar.date(byAdding: .day, value: -9, to: now)!, score: 0.92,
                                    stability: 5.8),
                    PracticeSession(id: 3,
                                    date: calendar.date(byAdding: .day, value: -4, to: now)!, score: 0.70,
                                    stability: 4.2),
                    PracticeSession(id: 4,
                                    date: calendar.date(byAdding: .day, value: -1, to: now)!, score: 0.95,
                                    stability: 10.5),
                ]
                PassageMemoryScoreChart(sessions: sessions)
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

            VStack {
                HStack {
                    Text("Practice")
                        .font(.app(.title2))
                    Spacer()
                }
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))

            VStack {
                HStack {
                    Text("Passage")
                        .font(.app(.title2))
                    Spacer()
                }
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 10)
    }
}

#Preview {
    PassageDetailView(passageID: 1)
        .environment(\.font, .app())
}
