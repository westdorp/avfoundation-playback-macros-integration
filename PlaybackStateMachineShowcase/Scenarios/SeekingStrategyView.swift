import PlaybackStateMachine
import SwiftUI

struct SeekingStrategyView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            decisionCard
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Seeking Strategy")
        .scenarioScreen(.seekingStrategy)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Kind", selection: $viewModel.selectedKind) {
                Text("VOD").tag(SeekKind.vod)
                Text("Live DVR").tag(SeekKind.liveDVR)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text("Target: \(viewModel.targetValue, specifier: "%.1f")s")
                    .font(.subheadline.monospaced())
                Slider(value: $viewModel.targetValue, in: 0...300, step: 1)
            }

            if viewModel.selectedKind == .liveDVR {
                Toggle("Use seekable range (0–300s)", isOn: $viewModel.useSeekableRange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Live edge tolerance: \(viewModel.toleranceValue, specifier: "%.1f")s")
                        .font(.subheadline.monospaced())
                    Slider(value: $viewModel.toleranceValue, in: 0...30, step: 0.5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tolerance Inspector")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("Distance to edge: \(viewModel.liveEdgeDistance, specifier: "%.1f")s")
                        .font(.caption.monospaced())
                    Text(viewModel.liveDVRSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 8) {
                    Button("Near Edge Example") {
                        viewModel.applyNearEdgeExample()
                    }
                    Button("Far From Edge Example") {
                        viewModel.applyFarEdgeExample()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Text("VOD normalization clamps into the seekable range when provided and always returns `.seek(to:)`.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Evaluate") {
                viewModel.evaluate()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var decisionCard: some View {
        Group {
            if let decision = viewModel.lastDecision {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decision")
                        .font(.headline)
                    Text(decision.description)
                        .font(.body.monospaced())
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(decisionColor(decision).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
        }
    }

    private func decisionColor(_ decision: PlaybackSeekDecision) -> Color {
        switch decision {
        case .seek: .blue
        case .seekToLiveEdge: .green
        }
    }
}

private enum SeekKind: Hashable {
    case vod
    case liveDVR
}

@Observable
@MainActor
private final class ViewModel {
    var selectedKind: SeekKind = .vod
    var targetValue: Double = 60
    var useSeekableRange: Bool = true
    var toleranceValue: Double = 10
    var lastDecision: PlaybackSeekDecision?
    let traceStore = TraceStore()

    var liveEdgeDistance: Double {
        max(0, 300 - targetValue)
    }

    var liveDVRSummary: String {
        if liveEdgeDistance <= toleranceValue {
            return "Within tolerance: strategy should prefer `.seekToLiveEdge`."
        }
        return "Outside tolerance: strategy should emit `.seek(to:)`."
    }

    func applyNearEdgeExample() {
        selectedKind = .liveDVR
        useSeekableRange = true
        toleranceValue = 10
        targetValue = 295
        evaluate()
    }

    func applyFarEdgeExample() {
        selectedKind = .liveDVR
        useSeekableRange = true
        toleranceValue = 10
        targetValue = 120
        evaluate()
    }

    func evaluate() {
        guard let target = PlaybackPositionSeconds(targetValue) else {
            traceStore.append(category: .info, label: "Invalid target", detail: "Must be finite and non-negative")
            return
        }

        let decision: PlaybackSeekDecision
        switch selectedKind {
        case .vod:
            let strategy = PlaybackStrategies.vodSeeking()
            let request = PlaybackSeekRequest(target: target)
            decision = strategy.seekDecision(for: request, context: PlaybackKindContext())
            traceStore.append(
                category: .strategyDecision,
                label: "VOD seek → \(decision)",
                detail: "target: \(target)"
            )

        case .liveDVR:
            let strategy = PlaybackStrategies.liveDVRSeeking(
                liveEdgeToleranceSeconds: toleranceValue
            )
            let seekableRange: ClosedRange<PlaybackPositionSeconds>?
            if useSeekableRange {
                guard let upperBound = PlaybackPositionSeconds(300) else {
                    traceStore.append(
                        category: .info,
                        label: "Invalid seekable range upper bound",
                        detail: "300s must be finite and non-negative"
                    )
                    return
                }
                seekableRange = PlaybackPositionSeconds.zero...upperBound
            } else {
                seekableRange = nil
            }
            let request = PlaybackSeekRequest(target: target, seekableRange: seekableRange)
            decision = strategy.seekDecision(for: request, context: PlaybackKindContext())
            traceStore.append(
                category: .strategyDecision,
                label: "LiveDVR seek → \(decision)",
                detail: "target: \(target), tolerance: \(toleranceValue)s"
            )
        }

        lastDecision = decision
    }
}
