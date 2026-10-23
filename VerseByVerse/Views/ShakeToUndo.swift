//
//  ShakeToUndo.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/20/26.
//

import SwiftData
import SwiftUI
import UIKit

extension View {
    /// Makes shake (and ⌘Z with a hardware keyboard) undo the model context's
    /// most recent change — see `Deletion.swift` for the operations that leave
    /// an undoable change behind.
    ///
    /// Two pieces are needed. The context must record into the *window's*
    /// undo manager, since that is the one UIKit's shake alert drives; and
    /// something must be first responder to receive the motion event, which a
    /// SwiftUI hierarchy never is on its own.
    func supportsShakeToUndo() -> some View {
        modifier(ShakeToUndoModifier())
    }
}

private struct ShakeToUndoModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

    func body(content: Content) -> some View {
        content
            .background(ShakeResponder())
            .onChange(of: undoManager, initial: true) { _, manager in
                // A small stack bounds the memory the manager retains.
                manager?.levelsOfUndo = 5
                modelContext.undoManager = manager
            }
    }
}

/// Invisible first responder that receives shake events and lets UIKit's
/// default handling present the "Undo <action>" alert from the window's
/// undo manager. Reclaims first responder whenever something else (a text
/// field, a dismissed sheet) may have taken it.
private struct ShakeResponder: UIViewControllerRepresentable {
    final class Controller: UIViewController {
        override var canBecomeFirstResponder: Bool {
            true
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            let center = NotificationCenter.default
            for name in [UIResponder.keyboardDidHideNotification, UIApplication.didBecomeActiveNotification] {
                center.addObserver(self, selector: #selector(reclaimFirstResponder), name: name, object: nil)
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        @objc private func reclaimFirstResponder() {
            guard view.window != nil, !isFirstResponder else { return }
            becomeFirstResponder()
        }
    }

    func makeUIViewController(context _: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_: Controller, context _: Context) {}
}
