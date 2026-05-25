//
//  StudySetStore.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/24/26.
//

import Observation
import SwiftUI

@Observable
final class StudySetStore: Store {
    static let shared = StudySetStore()

    var state: DataState = .idle
    var lastError: APIError?

    private(set) var sets: [StudySet] = []

    private init() {}
}
