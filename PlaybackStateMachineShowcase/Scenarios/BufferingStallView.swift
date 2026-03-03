import PlaybackStateMachine
import SwiftUI

struct BufferingStallView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            resultCards
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Buffering & Stall")
        .scenarioScreen(.bufferingStall)
        .onAppear {
            viewModel.evaluate()
        }
        .onChange(of: viewModel.inputSignature) {
            viewModel.evaluate()
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buffering Inputs")
                .font(.headline)

            Toggle("isLikelyToKeepUp", isOn: $viewModel.isLikelyToKeepUp)
            Toggle("isBufferEmpty", isOn: $viewModel.isBufferEmpty)
            Toggle("isWaitingForData", isOn: $viewModel.isWaitingForData)

            Divider()

            Text("Stall Inputs")
                .font(.headline)

            Stepper(
                "Consecutive buffering ticks: \(viewModel.consecutiveTicks)",
                value: $viewModel.consecutiveTicks,
                in: 0...20
            )
            Toggle("isSeeking", isOn: $viewModel.isSeeking)
            Toggle("hasPlaybackError", isOn: $viewModel.hasPlaybackError)

            Text("Results refresh automatically as inputs change.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var resultCards: some View {
        HStack(alignment: .top, spacing: 12) {
            if let buffering = viewModel.lastBufferingDecision {
                resultCard(title: "Buffering", value: buffering.description, color: bufferingColor(buffering))
            }
            if let stall = viewModel.lastStallClass {
                resultCard(title: "Stall Class", value: stall.description, color: stallColor(stall))
            }
        }
        .padding()
    }

    private func resultCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospaced())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func bufferingColor(_ decision: PlaybackBufferingDecision) -> Color {
        switch decision {
        case .ready: .green
        case .buffering: .yellow
        }
    }

    private func stallColor(_ stallClass: PlaybackStallClass) -> Color {
        switch stallClass {
        case .none: .green
        case .transient: .yellow
        case .network: .orange
        case .playerError: .red
        }
    }
}

@Observable
@MainActor
private final class ViewModel {
    struct InputSignature: Equatable {
        var isLikelyToKeepUp: Bool
        var isBufferEmpty: Bool
        var isWaitingForData: Bool
        var consecutiveTicks: Int
        var isSeeking: Bool
        var hasPlaybackError: Bool
    }

    var isLikelyToKeepUp = true
    var isBufferEmpty = false
    var isWaitingForData = false
    var consecutiveTicks = 0
    var isSeeking = false
    var hasPlaybackError = false

    var lastBufferingDecision: PlaybackBufferingDecision?
    var lastStallClass: PlaybackStallClass?
    let traceStore = TraceStore()

    var inputSignature: InputSignature {
        InputSignature(
            isLikelyToKeepUp: isLikelyToKeepUp,
            isBufferEmpty: isBufferEmpty,
            isWaitingForData: isWaitingForData,
            consecutiveTicks: consecutiveTicks,
            isSeeking: isSeeking,
            hasPlaybackError: hasPlaybackError
        )
    }

    func evaluate() {
        let snapshot = PlaybackBufferingSnapshot(
            isLikelyToKeepUp: isLikelyToKeepUp,
            isBufferEmpty: isBufferEmpty,
            isWaitingForData: isWaitingForData
        )

        let bufferingStrategy = PlaybackStrategies.vodBuffering()
        let bufferingDecision = bufferingStrategy.bufferingDecision(
            for: snapshot,
            context: PlaybackKindContext()
        )
        lastBufferingDecision = bufferingDecision

        traceStore.append(
            category: .strategyDecision,
            label: "Buffering → \(bufferingDecision)",
            detail: "keepUp=\(isLikelyToKeepUp) empty=\(isBufferEmpty) waiting=\(isWaitingForData)"
        )

        let observation = PlaybackStallObservation(
            bufferingDecision: bufferingDecision,
            consecutiveBufferingTicks: consecutiveTicks,
            isSeeking: isSeeking,
            hasPlaybackError: hasPlaybackError
        )

        let stallStrategy = PlaybackStrategies.vodStall(networkStallThresholdTicks: 3)
        let stallClass = stallStrategy.classifyStall(from: observation, context: PlaybackKindContext())
        lastStallClass = stallClass

        traceStore.append(
            category: .strategyDecision,
            label: "Stall → \(stallClass)",
            detail: "ticks=\(consecutiveTicks) seeking=\(isSeeking) error=\(hasPlaybackError)"
        )
    }
}
