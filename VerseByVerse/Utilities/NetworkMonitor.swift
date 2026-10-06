//
//  NetworkMonitor.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/11/26.
//

import Foundation
import Observation

/// Tracks reachability purely from real request outcomes — no separate
/// device-path monitor (an `NWPathMonitor`-based signal was tried first, but
/// it can lag or flat-out disagree with reality, especially in the
/// Simulator, and there's no recovering from two signals that disagree).
/// `APIService` reports every request's outcome via ``report(_:)``,
/// classifying transport failures by `URLError` code so "the device has no
/// network at all" (`.notConnectedToInternet` and friends) is told apart
/// from "reached *some* network, just not our server." A dedicated
/// `/health` probe (``start()``/``refresh()``) establishes the state at
/// launch and on manual refresh; a retry loop runs only while something's
/// actually known to be wrong, and stops the moment any request succeeds.
@Observable
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    enum Status: Equatable {
        case unknown
        case online
        case deviceOffline
        case serverUnreachable
    }

    private(set) var status: Status = .unknown

    var isFullyOnline: Bool {
        status == .online
    }

    private let retryInterval: Duration = .seconds(15)
    private var didStart = false
    private var retryTask: Task<Void, Never>?
    private var inFlightProbe: Task<Status, Never>?
    private let log = AppLog.category("NetworkMonitor")

    private init() {}

    /// Runs one live `/health` check — so startup can await a real answer
    /// instead of showing "unknown" the moment the app appears, since
    /// ordinary Bible-metadata fetches are usually cache hits and never
    /// touch the network at all. Safe to call once; later calls no-op.
    func start() async {
        guard !didStart else { return }
        didStart = true
        await probe()
    }

    /// Forces an immediate `/health` check — e.g. pull-to-refresh. Shares
    /// the same in-flight dedup as everything else.
    @discardableResult
    func refresh() async -> Status {
        await probe()
    }

    /// Called by `APIService` with the classification of every real
    /// request's outcome, so ordinary fetches keep this accurate
    /// without a separate poll. Starts the retry loop on anything but
    /// `.online`, and clears it the moment something succeeds.
    func report(_ outcome: Status) {
        status = outcome
        if outcome == .online {
            retryTask?.cancel()
            retryTask = nil
        } else {
            startRetryLoopIfNeeded()
        }
    }

    private func startRetryLoopIfNeeded() {
        guard retryTask == nil else { return }
        log.debug("Retry loop starting")
        retryTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: retryInterval)
                guard !Task.isCancelled else { break }
                if await probe() == .online { break }
            }
            self?.log.debug("Retry loop stopping")
            self?.retryTask = nil
        }
    }

    /// Pings `/health` directly, classifying the result the same way
    /// `APIService.fetch`'s report hook does. Concurrent callers share one
    /// in-flight request rather than racing, so every caller gets the real
    /// result, never a stale one.
    @discardableResult
    private func probe() async -> Status {
        if let inFlightProbe {
            return await inFlightProbe.value
        }

        let task = Task<Status, Never> {
            do {
                let response: APIResponse<GetHealthResponse> = try await APIService.shared.fetch(
                    endpoint: .getHealth,
                    lookInCache: false,
                    saveToCache: false,
                )
                return response.statusCode == 200 && ["ok", "degraded"].contains(response.body.status)
                    ? .online
                    : .serverUnreachable
            } catch let apiError as APIError {
                return NetworkMonitor.classify(apiError) ?? .serverUnreachable
            } catch {
                return .serverUnreachable
            }
        }
        inFlightProbe = task
        let result = await task.value
        inFlightProbe = nil

        log.debug("Health probe: \(result)")
        status = result
        if result != .online {
            startRetryLoopIfNeeded()
        }
        return result
    }
}

extension NetworkMonitor {
    /// Classifies a failed request — nil for errors that say nothing about
    /// reachability (`.cancelled`, `.unknown`). `.notConnectedToInternet`
    /// (and the cellular-restriction variants) mean the device itself has
    /// no path; any other transport failure still implies *some* network,
    /// just not this host. An `.http` error is only `.online` if the body
    /// actually came from our app — anything sitting in front of it
    /// (reverse proxy, CDN, load balancer) can generate its own non-2xx
    /// response, with any status code, before our app ever sees the
    /// request.
    static func classify(_ error: APIError) -> Status? {
        switch error {
        case let .network(underlying):
            switch underlying.code {
            case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff, .callIsActive:
                .deviceOffline
            default:
                .serverUnreachable
            }
        case let .http(_, _, data):
            isFromOurApp(data) ? .online : .serverUnreachable
        case .decoding, .emptySelection:
            .online
        case .cancelled, .unknown:
            nil
        }
    }

    /// Our FastAPI app always answers with a JSON body — even its error
    /// responses use `{"detail": ...}`. A failure response generated by
    /// whatever sits in front of it (an HTML error page, an empty body,
    /// etc.) never parses as JSON, so this tells "our server answered,
    /// just with an error" apart from "something in front of our server
    /// did," without hardcoding any particular provider's status codes.
    private static func isFromOurApp(_ data: Data?) -> Bool {
        guard let data, !data.isEmpty else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
}
