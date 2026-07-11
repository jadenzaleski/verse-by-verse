//
//  NetworkMonitor.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 7/11/26.
//

import Network
import Observation

/// Tracks two independent things: whether the device has a network path at
/// all (`isDeviceOnline`, pushed instantly by `NWPathMonitor`) and whether
/// the VBV API actually answers (`serverStatus`). Distinguishing the two
/// lets the UI tell "you're offline" apart from "we can't reach our server."
///
/// Server reachability is event-driven, not blindly polled: `APIService`
/// reports every real request's outcome via ``reportSuccess()``/
/// ``reportFailure()``, so an ordinary Bible fetch confirms reachability
/// just as well as a dedicated check. A 30s retry loop only runs while
/// something is actually known to be wrong — it stops the moment a request
/// (organic or retry) succeeds.
@Observable
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    enum ServerStatus {
        case unknown
        case reachable
        case unreachable
    }

    private(set) var isDeviceOnline = true
    private(set) var serverStatus: ServerStatus = .unknown

    /// True only when the device has a path *and* the server has answered.
    var isFullyOnline: Bool {
        isDeviceOnline && serverStatus == .reachable
    }

    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.verse-by-verse.network-monitor")
    private let retryInterval: Duration = .seconds(15)
    private var didStart = false
    private var retryTask: Task<Void, Never>?
    private var inFlightProbe: Task<Bool, Never>?
    private let log = AppLog.category("NetworkMonitor")

    private init() {
        // The weak capture must live on the inner `Task` closure, not this
        // outer one — capturing a weak `self` on the outer closure and then
        // referencing it from the nested concurrently-executing `Task` is
        // what Swift 6 flags as a captured-var race.
        pathMonitor.pathUpdateHandler = { path in
            Task { @MainActor [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        pathMonitor.start(queue: pathQueue)
    }

    /// Runs one live `/health` check — so startup can await a real answer
    /// instead of showing "unknown" the moment the app appears, since
    /// ordinary Bible-metadata fetches are usually cache hits and never
    /// touch the network at all. Safe to call once; later calls no-op.
    func start() async {
        guard !didStart else { return }
        didStart = true
        let reachable = await probe()
        if !reachable {
            startRetryLoopIfNeeded()
        }
    }

    /// Called by `APIService` when a real request reaches the server at all
    /// — 2xx, or even an HTTP error response, since either way something
    /// answered. Confirms reachability and stops any active retry loop.
    func reportSuccess() {
        serverStatus = .reachable
        retryTask?.cancel()
        retryTask = nil
    }

    /// Called by `APIService` when a real request fails at the transport
    /// level (couldn't reach the host at all — not an HTTP error response).
    /// Marks the server unreachable and starts retrying every 30s until a
    /// probe succeeds again.
    func reportFailure() {
        serverStatus = .unreachable
        startRetryLoopIfNeeded()
    }

    private func startRetryLoopIfNeeded() {
        guard retryTask == nil else { return }
        retryTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: self.retryInterval)
                guard !Task.isCancelled else { break }
                if await self.probe() { break }
            }
            self?.retryTask = nil
        }
    }

    private func handlePathUpdate(_ path: NWPath) {
        let wasOnline = isDeviceOnline
        isDeviceOnline = path.status == .satisfied
        log.debug("Device path \(isDeviceOnline ? "satisfied" : "unsatisfied")")

        if isDeviceOnline, !wasOnline {
            // Regained the device network — don't wait for the retry loop
            // to find out if the server's reachable too.
            Task {
                if !(await probe()) {
                    startRetryLoopIfNeeded()
                }
            }
        } else if !isDeviceOnline {
            serverStatus = .unreachable
        }
    }

    /// Pings `/health` directly (bypassing the `APIService.fetch` report
    /// hook via `HealthService`'s own cache-bypassing call). Skipped when
    /// the device has no path at all. Concurrent callers share one
    /// in-flight request rather than racing, so every caller gets the real
    /// result, never a stale one.
    @discardableResult
    private func probe() async -> Bool {
        guard isDeviceOnline else {
            serverStatus = .unreachable
            return false
        }

        if let inFlightProbe {
            return await inFlightProbe.value
        }

        let task = Task<Bool, Never> {
            (try? await APIService.shared.getHealth()) ?? false
        }
        inFlightProbe = task
        let reachable = await task.value
        inFlightProbe = nil

        log.debug("Health probe: \(reachable ? "reachable" : "unreachable")")
        serverStatus = reachable ? .reachable : .unreachable
        return reachable
    }
}
