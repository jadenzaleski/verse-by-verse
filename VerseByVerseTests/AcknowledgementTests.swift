//
//  AcknowledgementTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 11/25/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// The bundled licenses must actually ship: a renamed or unbundled file
/// would leave a component's notice out of the app.
@Suite("Acknowledgements") @MainActor
struct AcknowledgementTests {
    @Test func `every acknowledgement's license text is bundled`() {
        for item in Acknowledgement.all {
            let text = item.licenseText
            #expect(text?.isEmpty == false, "\(item.licenseFile).txt missing from the bundle")
            #expect(text?.contains("Copyright") == true, "\(item.licenseFile).txt has no copyright line")
        }
    }

    @Test func `github links are detected by host`() {
        let byName = Dictionary(uniqueKeysWithValues: Acknowledgement.all.map { ($0.name, $0) })
        #expect(byName["swift-fsrs"]?.isGitHub == true)
        #expect(byName["Montserrat"]?.isGitHub == true)
        #expect(byName["Lucide"]?.isGitHub == false)
    }

    @Test func `license files are unique`() {
        let files = Acknowledgement.all.map(\.licenseFile)
        #expect(Set(files).count == files.count)
    }
}
