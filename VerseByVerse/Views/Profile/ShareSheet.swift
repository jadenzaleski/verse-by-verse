//
//  ShareSheet.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 11/2/26.
//

import UIKit

private let log = AppLog.category("ShareSheet")

/// Presents the system share sheet for a file from code.
///
/// `ShareLink` can't report a tap, so a row that needs to show progress
/// ("Preparing…") while the share sheet loads presents the UIKit controller
/// itself.
enum ShareSheet {
    private static let presentationGrace: TimeInterval = 1.5

    /// Presents the share sheet for `url` over the frontmost view controller.
    /// `onPresented` runs once the sheet should be on screen (immediately if
    /// there is nothing to present over).
    ///
    /// UIKit reports the presentation as finished before the system's share
    /// content has drawn, which can take a few seconds the first time after a
    /// launch. The callback is held for a short grace period so a spinner
    /// doesn't vanish into a blank gap.
    @MainActor
    static func present(_ url: URL, onPresented: @escaping () -> Void) {
        guard let top = topViewController() else {
            log.error("No view controller to present the share sheet over")
            onPresented()
            return
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // Required if the app ever runs in a popover-style environment
        // (iPhone app on iPad); ignored on iPhone.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(controller, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + presentationGrace) {
                onPresented()
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
