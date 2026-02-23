import PlaybackStateMachine
import SwiftUI

struct EventRoutingView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            stateCard
            Divider()
            controls
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Event Routing")
        .scenarioScreen(.eventRouting)
    }

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current State")
                .font(.headline)
            Text(viewModel.machine.state.label)
                .font(.body.monospaced())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Routing Controls")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Setup direct intents first, then send external events to observe routed behavior.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Intents")
                        .font(.subheadline.bold())
                    intentButton("selectMedia", intent: .selectMedia(id: "ep-001"))
                    intentButton("startSession", intent: .startSession)
                    intentButton("play", intent: .play)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("External Events")
                        .font(.subheadline.bold())
                    eventButton("bufferingCompleted", event: .bufferingCompleted)
                    eventButton("playbackStalled", event: .playbackStalled)
                    eventButton("playbackError(.network)", event: .playbackError(.networkUnavailable))
                }
            }
        }
        .padding()
    }

    private func intentButton(_ label: String, intent: VODPlaybackMachine.Intent) -> some View {
        Button(label) {
            viewModel.sendIntent(intent)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func eventButton(_ label: String, event: VODPlaybackMachine.Event) -> some View {
        Button(label) {
            viewModel.sendEvent(event)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
}

@Observable
@MainActor
private final class ViewModel {
    var machine = VODPlaybackMachine(initialState: .idle)
    let traceStore = TraceStore()

    func sendIntent(_ intent: VODPlaybackMachine.Intent) {
        traceStore.append(category: .intent, label: "send(\(intent))")
        logTransition(machine.send(intent))
    }

    func sendEvent(_ event: VODPlaybackMachine.Event) {
        traceStore.append(category: .event, label: "send(event: \(event))")
        let fromState = String(describing: machine.state)
        switch machine.send(event: event) {
        case let .valid(transition):
            logTransition(transition)
        case .invalid:
            let toState = String(describing: machine.state)
            if fromState == toState {
                traceStore.append(category: .info, label: "Event routed internally (state unchanged)")
            } else {
                traceStore.append(
                    category: .info,
                    label: "Event routed internally",
                    detail: "\(fromState) -> \(toState)"
                )
            }
        }
    }

    private func logTransition(_ transition: VODPlaybackMachine.Transition) {
        let category: TraceCategory = transition.isAllowed ? .transitionAllowed : .transitionDenied
        traceStore.append(
            category: category,
            label: transition.summary,
            detail: transition.outcomeDetails
        )
    }

    func reset() {
        machine = VODPlaybackMachine(initialState: .idle)
        traceStore.reset()
        traceStore.append(category: .info, label: "State reset to .idle")
    }
}
