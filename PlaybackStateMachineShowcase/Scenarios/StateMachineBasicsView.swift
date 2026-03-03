import PlaybackStateMachine
import SwiftUI

struct StateMachineBasicsView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            stateCard
            Divider()
            controlGrid
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("State Machine Basics")
        .scenarioScreen(.stateMachineBasics)
    }

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current State")
                .font(.headline)

            Text(viewModel.statePath)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Text(viewModel.machine.state.label)
                .font(.body.monospaced())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                caseBadge("idle", active: viewModel.machine.state.is(\.idle))
                caseBadge("loading", active: viewModel.machine.state.is(\.loading))
                caseBadge("session", active: viewModel.machine.state.is(\.session))
                caseBadge("failed", active: viewModel.machine.state.is(\.failed))
            }

            if let sessionPath = viewModel.sessionPath {
                HStack(spacing: 8) {
                    Text("session phase:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(sessionPath)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }

    private func caseBadge(_ label: String, active: Bool) -> some View {
        Text(label)
            .font(.caption.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(active ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(active ? .green : .secondary)
            .clipShape(Capsule())
    }

    private var controlGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Intents")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("Drive intents in sequence and compare state path vs generated label output.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                intentButton("selectMedia", intent: .selectMedia(id: "ep-001"))
                intentButton("startSession", intent: .startSession)
                intentButton("play", intent: .play)
                intentButton("pause", intent: .pause)
                intentButton("stop", intent: .stop)
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

    var statePath: String {
        switch machine.state {
        case .idle:
            return ".idle"
        case .loading:
            return ".loading"
        case .session:
            return ".session"
        case .failed:
            return ".failed"
        }
    }

    var sessionPath: String? {
        switch machine.state {
        case let .session(.playing(mediaID)):
            return ".session(.playing(mediaID: \(mediaID)))"
        case let .session(.paused(mediaID)):
            return ".session(.paused(mediaID: \(mediaID)))"
        case let .session(.buffering(mediaID)):
            return ".session(.buffering(mediaID: \(mediaID)))"
        default:
            return nil
        }
    }

    func sendIntent(_ intent: VODPlaybackMachine.Intent) {
        traceStore.append(category: .intent, label: "send(\(intent))")

        let transition = machine.send(intent)
        transition
            .ifAllowed { state in
                traceStore.append(
                    category: .transitionAllowed,
                    label: transition.summary,
                    detail: "New state: \(state)"
                )
            }
            .ifDenied { context in
                traceStore.append(
                    category: .transitionDenied,
                    label: transition.summary,
                    detail: "\(context.intent) from \(context.state)"
                )
            }
    }

    func reset() {
        machine = VODPlaybackMachine(initialState: .idle)
        traceStore.reset()
        traceStore.append(category: .info, label: "State reset to .idle")
    }
}
