//
//  FUMSReporter.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/10/26.
//

import Foundation

/// Reports scripture displays to API.Bible's Fair Use Management System.
///
/// The Bible proxy returns a `fumsToken` with every licensed passage; the
/// license requires reporting it each time that text is shown to a user,
/// including when it was served from a cache. Call `report(tokens:)` when a
/// screen presents scripture. Reporting is anonymous (random per-install
/// device id, per-launch session id, no user id) and fire-and-forget: it can
/// never fail or delay the UI.
/// See https://docs.api.bible/guides/fair-use/#how-to-report-fums-manually
final class FUMSReporter: Sendable {
    static let shared = FUMSReporter(
        deviceId: persistedDeviceId(in: .standard),
        sessionId: UUID().uuidString,
        send: sendBeacon,
    )

    private static let endpoint = "https://fums.api.bible/f3"
    private static let log = AppLog.category("FUMS")

    private let deviceId: String
    private let sessionId: String
    private let send: @Sendable (URL) async -> Void

    /// - Parameter send: Performs the beacon request. Injectable so tests can
    ///   observe URLs without touching the network.
    init(deviceId: String, sessionId: String, send: @escaping @Sendable (URL) async -> Void) {
        self.deviceId = deviceId
        self.sessionId = sessionId
        self.send = send
    }

    /// Fires one beacon covering every non-blank token and returns
    /// immediately. Callers ignore the result; the returned task exists so
    /// tests can wait for the send. Returns `nil` when there is nothing to report
    /// (e.g. public-domain translations, which carry no tokens).
    @discardableResult
    func report(tokens: [String]) -> Task<Void, Never>? {
        let tokens = tokens.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !tokens.isEmpty, let url = url(for: tokens) else { return nil }
        return Task { [send] in await send(url) }
    }

    private func url(for tokens: [String]) -> URL? {
        var components = URLComponents(string: Self.endpoint)
        // `URLQueryItem` leaves `+`, `&` and `=` literal in values; encode them
        // by hand so a token can't be misread as query syntax.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        }
        let items =
            [("dId", deviceId), ("sId", sessionId)] + tokens.map { ("t", $0) }
        components?.percentEncodedQuery = items
            .map { "\($0.0)=\(encode($0.1))" }
            .joined(separator: "&")
        return components?.url
    }

    /// A random, anonymous id created on first use and kept for the life of
    /// the install. FUMS only needs "one device"; it must not identify the person.
    static func persistedDeviceId(in defaults: UserDefaults) -> String {
        let key = StorageKeys.fumsDeviceId.rawValue
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: key)
        return created
    }

    /// The real beacon. Release builds ignore the outcome entirely; Debug, Local
    /// and Beta builds log what FUMS answered so reporting can be verified by
    /// eye (Beta logs are exportable from the Developer screen). Logged at
    /// `.info` because Beta's minimum level is info.
    @Sendable
    private static func sendBeacon(_ url: URL) async {
        #if DEBUG || BETA
            let count = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.filter { $0.name == "t" }.count ?? 0
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                log.info("FUMS beacon -> HTTP \(status) (\(count) token(s))")
            } catch {
                log.info("FUMS beacon failed (\(count) token(s)): \(error.localizedDescription)")
            }
        #else
            _ = try? await URLSession.shared.data(from: url)
        #endif
    }
}
