import PlaybackStateMachine
import SwiftUI

struct FullOrchestrationView: View {
    @State private var viewModel = FullOrchestrationViewModel()

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            Divider()
            controlPanel
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Full Orchestration")
        .scenarioScreen(.fullOrchestration)
    }

    private var statusBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(viewModel.compositeState.activeSurface.description)
                    .font(.caption.monospaced())
                Spacer()
                Text(PlaybackCompositeStrategyRouter.activeRoute(in: viewModel.compositeState).description)
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                stateLabel("VOD", state: viewModel.vodMachine.state.label)
                if let adMachine = viewModel.adMachine {
                    stateLabel("Ad", state: adMachine.state.label)
                }
            }

            HStack(spacing: 4) {
                Text("Surfaces:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(viewModel.compositeState.allSurfaces, id: \.id) { surface in
                    Text(surface.id)
                        .font(.caption2.monospaced())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.fill.quaternary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }

    private func stateLabel(_ machine: String, state: String) -> some View {
        HStack(spacing: 4) {
            Text(machine)
                .font(.caption2.bold())
            Text(state)
                .font(.caption2.monospaced())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.fill.quaternary)
        .clipShape(Capsule())
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Playback")
                .font(.subheadline.bold())
            HStack(spacing: 8) {
                Button("Start VOD") { viewModel.startVOD() }
                Button("Play") { viewModel.playVOD() }
                Button("Pause") { viewModel.pauseVOD() }
                Button("Stop") { viewModel.stopVOD() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Divider()

            Text("Simulate")
                .font(.subheadline.bold())
            HStack(spacing: 8) {
                if viewModel.isAdBreakRunning {
                    Button("Cancel Ad Break") { viewModel.cancelAdBreak() }
                        .tint(.orange)
                } else {
                    Button("Ad Break") { viewModel.simulateAdBreak() }
                        .tint(.orange)
                }
                Button("Stall") { viewModel.simulateStall() }
                    .tint(.yellow)
                Button("Error") { viewModel.simulateError() }
                    .tint(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text("Ad break flow is asynchronous and cancellation-safe; trace output shows both paths.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

@Observable
@MainActor
final class FullOrchestrationViewModel {
    let vodMachine = VODPlaybackMachine(initialState: .idle)
    var adMachine: AdPlaybackMachine?
    var compositeState: PlaybackCompositeState
    let traceStore = TraceStore()
    private var adBreakTask: Task<Void, Never>?
    private var shouldResumeAfterAdBreakCancellation = true
    private let adBreakPause: @Sendable () async throws -> Void
    private let makeAdID: @Sendable () -> String

    var isAdBreakRunning: Bool {
        adBreakTask != nil
    }

    init(
        adBreakPause: @escaping @Sendable () async throws -> Void = {
            try await Task.sleep(for: .seconds(1))
        },
        makeAdID: @escaping @Sendable () -> String = {
            "midroll-\(String(UUID().uuidString.prefix(4)))"
        }
    ) {
        compositeState = PlaybackCompositeState(activeSurface: .content(id: "vod-main"))
        self.adBreakPause = adBreakPause
        self.makeAdID = makeAdID
    }

    isolated deinit {
        adBreakTask?.cancel()
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
        // Clean up ad machine if present
        if adMachine != nil {
            adMachine = nil
            traceStore.append(category: .info, label: "Ad machine deallocated")
        }
    }

    func simulateAdBreak() {
        guard adBreakTask == nil else { return }

        shouldResumeAfterAdBreakCancellation = true
        let adID = makeAdID()
        adBreakTask = Task { [weak self] in
            guard let self else { return }
            await self.runAdBreakSimulation(adID: adID)
        }
    }

    func cancelAdBreak(resumePlayback: Bool = true) {
        guard let adBreakTask else { return }
        shouldResumeAfterAdBreakCancellation = resumePlayback
        traceStore.append(category: .info, label: "Cancelling ad break")
        adBreakTask.cancel()
    }

    func simulateStall() {
        traceStore.append(category: .event, label: "Playback stalled")
        let fromState = String(describing: vodMachine.state)
        switch vodMachine.send(event: .playbackStalled) {
        case let .valid(transition):
            logVODTransition(transition, label: "playbackStalled event")
        case .invalid:
            let toState = String(describing: vodMachine.state)
            if fromState == toState {
                traceStore.append(category: .info, label: "playbackStalled event routed (state unchanged)")
            } else {
                traceStore.append(
                    category: .info,
                    label: "playbackStalled event routed",
                    detail: "\(fromState) -> \(toState)"
                )
            }
        }

        // Classify the stall
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
            detail: "4 consecutive ticks → network stall"
        )

        // Analytics
        let signals = PlaybackStrategies.vodAnalytics()
            .signals(for: .stallClassified(stallClass), context: PlaybackKindContext())
        for signal in signals {
            traceStore.append(category: .info, label: "Analytics: \(signal)")
        }
    }

    func simulateError() {
        traceStore.append(category: .diagnosticEvent, label: "Playback error injected")
        let fromState = String(describing: vodMachine.state)
        let analyticsEvent = vodMachine.send(event: .playbackError(.networkUnavailable)).fold(
            onValid: { transition in
                logVODTransition(transition, label: "playbackError event")
                return transition.fold(
                    onAllowed: { toState in
                        PlaybackAnalyticsEvent.transitionAllowed(
                            from: fromState,
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
                let toState = String(describing: vodMachine.state)
                if fromState == toState {
                    traceStore.append(category: .info, label: "playbackError event routed (state unchanged)")
                } else {
                    traceStore.append(
                        category: .info,
                        label: "playbackError event routed",
                        detail: "\(fromState) -> \(toState)"
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

    // MARK: - Helpers

    private func runAdBreakSimulation(adID: String) async {
        defer {
            adBreakTask = nil
        }

        traceStore.append(category: .info, label: "Mid-roll ad break started")
        logVODTransition(vodMachine.send(.pause), label: "pause (for ad)")

        let adSurface = PlaybackSurface.ad(id: adID, type: .midroll)
        let machine = AdPlaybackMachine(initialState: .idle)
        adMachine = machine

        applyCompositeEvent(.registerSurface(adSurface))
        applyCompositeEvent(.activateSurface(id: adID))

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
            cleanupAdBreak(adID: adID, resumePlayback: shouldResumeAfterAdBreakCancellation)
            let outcomeLabel = shouldResumeAfterAdBreakCancellation
                ? "Ad break cancelled, VOD resumed"
                : "Ad break cancelled"
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

    private func cleanupAdBreak(adID: String, resumePlayback: Bool) {
        if compositeState.activeSurface.id != "vod-main" {
            applyCompositeEvent(.activateSurface(id: "vod-main"))
        }

        if compositeState.surface(id: adID) != nil {
            applyCompositeEvent(.unregisterSurface(id: adID))
        }

        if resumePlayback {
            logVODTransition(vodMachine.send(.play), label: "resume VOD")
        }

        if adMachine != nil {
            adMachine = nil
            traceStore.append(category: .info, label: "Ad machine deallocated")
        }

        shouldResumeAfterAdBreakCancellation = true
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
            }
        }
    }
}
