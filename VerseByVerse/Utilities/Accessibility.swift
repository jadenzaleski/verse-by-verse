//
//  Accessibility.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/9/26.
//

import SwiftUI

enum VoiceOver {
    typealias Priority = AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute.AnnouncementPriority

    /// Speaks `message` through VoiceOver (a no-op when it's off). Use `.high`
    /// for things the user must not miss, which can cut off other speech, and
    /// `.low` for confirmations that can yield to it.
    static func announce(_ message: String, priority: Priority = .default) {
        var text = AttributedString(message)
        text.accessibilitySpeechAnnouncementPriority = priority
        AccessibilityNotification.Announcement(text).post()
    }
}
