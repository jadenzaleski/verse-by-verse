//
//  UserPassage.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

struct UserPassage: Identifiable, Equatable {
    let id: Int
    let userId: String
    let book: String
    let startChapter: Int
    let endChapter: Int
    let startVerse: Int
    let endVerse: Int
    let translation: String

    let lastPracticed: Date?
    let nextPractice: Date?
    let stability: Double
    let difficulty: Double
    let state: Int
    let reps: Int
    let lapses: Int
    let scheduledDays: Int
    let elapsedDays: Int

    var selectionKey: BibleSelectionKey {
        BibleSelectionKey(
            translation: translation,
            book: book,
            startChapter: startChapter,
            startVerse: startVerse,
            endChapter: endChapter,
            endVerse: endVerse,
        )
    }

    func verseCount(using bibleStore: BibleStore) -> Int {
        if startChapter == endChapter {
            return endVerse - startVerse + 1
        }
        var total = bibleStore.verseCount(for: book, chapter: startChapter) - startVerse + 1
        for chapter in (startChapter + 1) ..< endChapter {
            total += bibleStore.verseCount(for: book, chapter: chapter)
        }
        total += endVerse
        return total
    }

    var reference: String {
        if startChapter == endChapter {
            if startVerse == endVerse {
                "\(book) \(startChapter):\(startVerse)"
            } else {
                "\(book) \(startChapter):\(startVerse)-\(endVerse)"
            }
        } else {
            "\(book) \(startChapter):\(startVerse)-\(endChapter):\(endVerse)"
        }
    }
}

extension UserPassageReadResponse {
    func toDomain() -> UserPassage {
        UserPassage(
            id: id,
            userId: userId,
            book: book,
            startChapter: startChapter,
            endChapter: endChapter,
            startVerse: startVerse,
            endVerse: endVerse,
            translation: translation,
            lastPracticed: lastPracticed,
            nextPractice: nextPractice,
            stability: stability,
            difficulty: difficulty,
            state: state,
            reps: reps,
            lapses: lapses,
            scheduledDays: scheduledDays,
            elapsedDays: elapsedDays,
        )
    }
}
