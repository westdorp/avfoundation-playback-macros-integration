import PlaybackStateMachine
import SwiftUI

struct TransitionGuardrailsView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            stateCard
            Divider()
            controlGroups
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Transition Guardrails")
        .scenarioScreen(.transitionGuardrails)
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

    private var controlGroups: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Intent Paths")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Compare denied context details against valid transition traces.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Try Invalid", systemImage: "xmark.circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    intentButton("startSession", intent: .startSession)
                    intentButton("play", intent: .play)
                    intentButton("pause", intent: .pause)
                    intentButton("resumeFromBuffering", intent: .resumeFromBuffering)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Valid Path", systemImage: "checkmark.circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    intentButton("selectMedia", intent: .selectMedia(id: "ep-001"))
                    intentButton("startSession", intent: .startSession)
                    intentButton("stop", intent: .stop)
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
}

@Observable
@MainActor
private final class ViewModel {
    var machine = VODPlaybackMachine(initialState: .idle)
    let traceStore = TraceStore()

    func sendIntent(_ intent: VODPlaybackMachine.Intent) {
        traceStore.append(category: .intent, label: "send(\(intent))")

        let transition = machine.send(intent)
        let label = transition.fold(
            onAllowed: { _ in transition.summary },
            onDenied: { ctx in "denied: \(ctx.intent) from \(ctx.state)" }
        )
        let category: TraceCategory = transition.isAllowed ? .transitionAllowed : .transitionDenied
        traceStore.append(
            category: category,
            label: label,
            detail: transition.outcomeDetails
        )
    }

    func reset() {
        machine = VODPlaybackMachine(initialState: .idle)
        traceStore.reset()
        traceStore.append(category: .info, label: "State reset to .idle")
    }
}
