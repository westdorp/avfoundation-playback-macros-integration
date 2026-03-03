import Foundation
import Observation
import PlaybackStateMachine

@Observable
@MainActor
final class FullOrchestrationViewModel {
    let vodMachine = VODPlaybackMachine(initialState: .idle)
    var compositeState: PlaybackCompositeState
    let traceStore = TraceStore()

    private enum AdBreakPhase {
        case idle
        case running(AdBreakSession)
    }

    private final class AdBreakSession {
        let adID: AdID
        let machine: AdPlaybackMachine
        let task: Task<Void, Never>
        var resumePlaybackOnCancellation: Bool

        init(
            adID: AdID,
            machine: AdPlaybackMachine,
            task: Task<Void, Never>,
            resumePlaybackOnCancellation: Bool
        ) {
            self.adID = adID
            self.machine = machine
            self.task = task
            self.resumePlaybackOnCancellation = resumePlaybackOnCancellation
        }
    }

    private static let primarySurfaceID: SurfaceID = "vod-main"

    private var adBreakPhase: AdBreakPhase = .idle
    private let adBreakPause: @Sendable () async throws -> Void
    private let makeAdID: @Sendable () -> AdID

    var adMachine: AdPlaybackMachine? {
        guard case let .running(session) = adBreakPhase else {
            return nil
        }
        return session.machine
    }

    var isAdBreakRunning: Bool {
        if case .running = adBreakPhase {
            return true
        }
        return false
    }

    init(
        adBreakPause: @escaping @Sendable () async throws -> Void = {
            try await Task.sleep(for: .seconds(1))
        },
        makeAdID: @escaping @Sendable () -> AdID = {
            AdID("midroll-\(String(UUID().uuidString.prefix(4)))") ?? "midroll-fallback"
        }
    ) {
        compositeState = PlaybackCompositeState(activeSurface: .content(id: Self.primarySurfaceID.rawValue))
        self.adBreakPause = adBreakPause
        self.makeAdID = makeAdID
    }

    isolated deinit {
        if case let .running(session) = adBreakPhase {
            session.task.cancel()
        }
    }

    func startVOD() {
        logVODTransition(vodMachine.send(.selectMedia(id: "episode-001")), label: "selectMedia")
        logVODTransition(vodMachine.send(.startSession), label: "startSession")
    }

    func playVOD() {
        logVODTransition(vodMachine.send(.play), label: "play")
    }

    func pauseVOD() {
        logVODTransition(vodMachine.send(.pause), label: "pause")
    }

    func stopVOD() {
        cancelAdBreak(resumePlayback: false)
        logVODTransition(vodMachine.send(.stop), label: "stop")
    }

    func simulateAdBreak() {
        guard case .idle = adBreakPhase else {
            return
        }

        let adID = makeAdID()
        let machine = AdPlaybackMachine(initialState: .idle)
        let task = Task { [weak self] in
            guard let self else {
                return
            }
            await self.runAdBreakSimulation(adID: adID, machine: machine)
        }

        adBreakPhase = .running(
            AdBreakSession(
                adID: adID,
                machine: machine,
                task: task,
                resumePlaybackOnCancellation: true
            )
        )
    }

    func cancelAdBreak(resumePlayback: Bool = true) {
        guard case let .running(session) = adBreakPhase else {
            return
        }

        session.resumePlaybackOnCancellation = resumePlayback
        traceStore.append(category: .info, label: "Cancelling ad break")
        session.task.cancel()
    }

    func simulateStall() {
        traceStore.append(category: .event, label: "Playback stalled")
        let fromState = vodMachine.state
        switch vodMachine.send(event: .playbackStalled) {
        case let .valid(transition):
            logVODTransition(transition, label: "playbackStalled event")
        case .invalid:
            let toState = vodMachine.state
            if fromState == toState {
                traceStore.append(category: .info, label: "playbackStalled event routed (state unchanged)")
            } else {
                traceStore.append(
                    category: .info,
                    label: "playbackStalled event routed",
                    detail: "\(String(describing: fromState)) -> \(String(describing: toState))"
                )
            }
        }

        let observation = PlaybackStallObservation(
            bufferingDecision: .buffering(reason: .rebuffering),
            consecutiveBufferingTicks: 4,
            isSeeking: false,
            hasPlaybackError: false
        )
        let stallClass = PlaybackStrategies.vodStall()
            .classifyStall(from: observation, context: PlaybackKindContext())
        traceStore.append(
            category: .strategyDecision,
            label: "Stall classified: \(stallClass)",
            detail: "4 consecutive ticks -> network stall"
        )

        let signals = PlaybackStrategies.vodAnalytics()
            .signals(for: .stallClassified(stallClass), context: PlaybackKindContext())
        for signal in signals {
            traceStore.append(category: .info, label: "Analytics: \(signal)")
        }
    }

    func simulateError() {
        traceStore.append(category: .diagnosticEvent, label: "Playback error injected")
        let fromState = vodMachine.state
        let analyticsEvent = vodMachine.send(event: .playbackError(.networkUnavailable)).fold(
            onValid: { transition in
                logVODTransition(transition, label: "playbackError event")
                return transition.fold(
                    onAllowed: { toState in
                        PlaybackAnalyticsEvent.transitionAllowed(
                            from: String(describing: fromState),
                            to: String(describing: toState),
                            intent: "fail"
                        )
                    },
                    onDenied: { denied in
                        PlaybackAnalyticsEvent.transitionDenied(
                            state: String(describing: denied.state),
                            intent: String(describing: denied.intent)
                        )
                    }
                )
            },
            onInvalid: { _ in
                let toState = vodMachine.state
                if fromState == toState {
                    traceStore.append(category: .info, label: "playbackError event routed (state unchanged)")
                } else {
                    traceStore.append(
                        category: .info,
                        label: "playbackError event routed",
                        detail: "\(String(describing: fromState)) -> \(String(describing: toState))"
                    )
                }
                return .intentSent(intent: "event.playbackError(.networkUnavailable)")
            }
        )

        let signals = PlaybackStrategies.vodAnalytics()
            .signals(for: analyticsEvent, context: PlaybackKindContext())
        for signal in signals {
            traceStore.append(category: .info, label: "Analytics: \(signal)")
        }
    }

    private func runAdBreakSimulation(adID: AdID, machine: AdPlaybackMachine) async {
        defer {
            endAdBreakSession(for: adID)
        }

        traceStore.append(category: .info, label: "Mid-roll ad break started")
        logVODTransition(vodMachine.send(.pause), label: "pause (for ad)")

        let adSurface = PlaybackSurface.ad(id: adID.rawValue, type: .midroll)
        applyCompositeEvent(.registerSurface(adSurface))
        applyCompositeEvent(.activateSurface(id: adID.rawValue))

        logAdTransition(machine.send(.startAd(id: adID, type: .midroll)), label: "startAd")
        logAdTransition(machine.send(.play), label: "ad play")

        do {
            traceStore.append(category: .info, label: "Ad playback running")
            try Task.checkCancellation()
            try await adBreakPause()
            try Task.checkCancellation()

            logAdTransition(machine.send(.complete), label: "ad complete")
            cleanupAdBreak(adID: adID, resumePlayback: true)
            traceStore.append(category: .info, label: "Ad break completed, VOD resumed")
        } catch is CancellationError {
            let shouldResume = cancellationResumeBehavior(for: adID)
            cleanupAdBreak(adID: adID, resumePlayback: shouldResume)
            let outcomeLabel = shouldResume ? "Ad break cancelled, VOD resumed" : "Ad break cancelled"
            traceStore.append(category: .info, label: outcomeLabel)
        } catch {
            cleanupAdBreak(adID: adID, resumePlayback: true)
            traceStore.append(
                category: .diagnosticEvent,
                label: "Ad break simulation failed",
                detail: String(describing: error)
            )
        }
    }

    private func cancellationResumeBehavior(for adID: AdID) -> Bool {
        guard case let .running(session) = adBreakPhase, session.adID == adID else {
            return true
        }
        return session.resumePlaybackOnCancellation
    }

    private func cleanupAdBreak(adID: AdID, resumePlayback: Bool) {
        if compositeState.activeSurface.id != Self.primarySurfaceID.rawValue {
            applyCompositeEvent(.activateSurface(id: Self.primarySurfaceID.rawValue))
        }

        if compositeState.surface(id: adID.rawValue) != nil {
            applyCompositeEvent(.unregisterSurface(id: adID.rawValue))
        }

        if resumePlayback {
            logVODTransition(vodMachine.send(.play), label: "resume VOD")
        }
    }

    private func endAdBreakSession(for adID: AdID) {
        guard case let .running(session) = adBreakPhase, session.adID == adID else {
            return
        }
        adBreakPhase = .idle
        traceStore.append(category: .info, label: "Ad machine deallocated")
    }

    private func logVODTransition(_ transition: VODPlaybackMachine.Transition, label: String) {
        traceStore.append(category: .intent, label: "VOD.\(label)")
        let category: TraceCategory = transition.isAllowed ? .transitionAllowed : .transitionDenied
        traceStore.append(category: category, label: transition.summary)
    }

    private func logAdTransition(_ transition: AdPlaybackMachine.Transition, label: String) {
        traceStore.append(category: .intent, label: "Ad.\(label)")
        let category: TraceCategory = transition.isAllowed ? .transitionAllowed : .transitionDenied
        traceStore.append(category: category, label: transition.summary)
    }

    private func applyCompositeEvent(_ event: PlaybackCompositeEvent) {
        traceStore.append(category: .compositeEvent, label: "\(event)")
        let transition = PlaybackCompositeReducer.apply(event, to: compositeState)
        switch transition {
        case let .allowed(newState):
            compositeState = newState
            traceStore.append(category: .compositeEvent, label: "allowed", detail: "active: \(newState.activeSurface.id)")
        case .denied:
            if let reason = transition.deniedReason {
                traceStore.append(category: .compositeDenied, label: "denied: \(reason)")
            } else {
                traceStore.append(category: .compositeDenied, label: "denied: unknown reason")
            }
        }
    }
}
