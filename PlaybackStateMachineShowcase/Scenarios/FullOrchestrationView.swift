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
                stateLabel(for: "VOD", state: viewModel.vodMachine.state.label)
                if let adMachine = viewModel.adMachine {
                    stateLabel(for: "Ad", state: adMachine.state.label)
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

    private func stateLabel(for machine: String, state: String) -> some View {
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
