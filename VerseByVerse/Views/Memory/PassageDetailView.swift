//
//  PassageDetailView.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/4/26.
//

import SwiftUI

struct PassageDetailView: View {
    let passage: UserPassage
    var body: some View {
        VStack {
            HStack {
                Text(passage.reference)
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
//                let sessions: [PracticeSession] = [
//                    PracticeSession(id: 1, userId: "u1", passageId: passageID,
//                                    startDate: calendar.date(byAdding: .day, value: -12, to: now)!,
//                                    endDate: calendar.date(byAdding: .day, value: -12, to: now)!.addingTimeInterval(300),
//                                    score: 0.85, rating: 4, scheduledDays: 2, elapsedDays: 1, state: 1),
//                    PracticeSession(id: 2, userId: "u1", passageId: passageID,
//                                    startDate: calendar.date(byAdding: .day, value: -9, to: now)!,
//                                    endDate: calendar.date(byAdding: .day, value: -9, to: now)!.addingTimeInterval(300),
//                                    score: 0.92, rating: 5, scheduledDays: 5, elapsedDays: 3, state: 1),
//                    PracticeSession(id: 3, userId: "u1", passageId: passageID,
//                                    startDate: calendar.date(byAdding: .day, value: -4, to: now)!,
//                                    endDate: calendar.date(byAdding: .day, value: -4, to: now)!.addingTimeInterval(300),
//                                    score: 0.70, rating: 2, scheduledDays: 4, elapsedDays: 5, state: 1),
//                    PracticeSession(id: 4, userId: "u1", passageId: passageID,
//                                    startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
//                                    endDate: calendar.date(byAdding: .day, value: -1, to: now)!.addingTimeInterval(300),
//                                    score: 0.95, rating: 5, scheduledDays: 10, elapsedDays: 3, state: 1),
//                ]
//                PassageMemoryScoreChart(sessions: sessions)
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
    PassageDetailView(passage: UserPassage(id: 1,
                                             userId: "test",
                                             book: "John",
                                             startChapter: 1,
                                             endChapter: 2,
                                             startVerse: 3,
                                             endVerse: 4,
                                             translation: "KJV",
                                             lastPracticed: nil,
                                             nextPractice: nil,
                                             stability: 1.0,
                                             difficulty: 1.0,
                                             state: 1,
                                             reps: 1,
                                             lapses: 1,
                                             scheduledDays: 1,
                                             elapsedDays: 1))
        .environment(\.font, .app())
}
