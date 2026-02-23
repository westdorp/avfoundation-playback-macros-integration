import PlaybackStateMachine
import SwiftUI

struct CompositeStateView: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            activeSurfaceCard
            Divider()
            surfaceList
            Divider()
            TraceTimelineView(entries: viewModel.traceStore.entries)
        }
        .navigationTitle("Composite State")
        .scenarioScreen(.compositeState)
    }

    private var activeSurfaceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Surface")
                .font(.headline)

            let active = viewModel.compositeState.activeSurface
            HStack {
                Text(active.description)
                    .font(.body.monospaced())
                Spacer()
                Text(PlaybackCompositeStrategyRouter.activeRoute(in: viewModel.compositeState).description)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(8)
            .background(.fill.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }

    private var surfaceList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Surfaces (\(viewModel.compositeState.allSurfaces.count))")
                    .font(.headline)
                Spacer()
                registerMenu
            }

            Text("Removing the active surface is intentionally denied to keep composite invariants valid.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(viewModel.compositeState.allSurfaces, id: \.id) { surface in
                surfaceRow(surface)
            }
        }
        .padding()
    }

    private var registerMenu: some View {
        Menu("Register") {
            Button("Live") {
                viewModel.registerSurface(.live(id: "live-\(UUID().uuidString.prefix(4))"))
            }
            Button("Content (VOD)") {
                viewModel.registerSurface(.content(id: "vod-\(UUID().uuidString.prefix(4))"))
            }
            Button("Ad (midroll)") {
                viewModel.registerSurface(.ad(id: "ad-\(UUID().uuidString.prefix(4))", type: .midroll))
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func surfaceRow(_ surface: PlaybackSurface) -> some View {
        let isActive = surface.id == viewModel.compositeState.activeSurface.id
        return HStack {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
            Text(surface.description)
                .font(.caption.monospaced())
                .lineLimit(1)
            Spacer()
            if !isActive {
                Button("Activate") {
                    viewModel.activateSurface(id: surface.id)
                }
                .controlSize(.mini)
                Button("Remove") {
                    viewModel.removeSurface(id: surface.id)
                }
                .controlSize(.mini)
                .tint(.red)
            } else {
                Text("active")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Button("Remove") {
                    viewModel.removeSurface(id: surface.id)
                }
                .controlSize(.mini)
                .tint(.orange)
            }
        }
        .padding(6)
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

@Observable
@MainActor
private final class ViewModel {
    var compositeState: PlaybackCompositeState
    let traceStore = TraceStore()

    init() {
        compositeState = PlaybackCompositeState(activeSurface: .content(id: "vod-main"))
    }

    func registerSurface(_ surface: PlaybackSurface) {
        let event = PlaybackCompositeEvent.registerSurface(surface)
        applyEvent(event)
    }

    func activateSurface(id: String) {
        applyEvent(.activateSurface(id: id))
    }

    func removeSurface(id: String) {
        applyEvent(.unregisterSurface(id: id))
    }

    private func applyEvent(_ event: PlaybackCompositeEvent) {
        traceStore.append(category: .compositeEvent, label: "\(event)")

        let transition = PlaybackCompositeReducer.apply(event, to: compositeState)
        switch transition {
        case let .allowed(newState):
            compositeState = newState
            traceStore.append(
                category: .compositeEvent,
                label: "allowed",
                detail: "surfaces: \(newState.surfaceIDs), active: \(newState.activeSurface.id)"
            )
        case .denied:
            guard let reason = transition.deniedReason else {
                return
            }
            traceStore.append(
                category: .compositeDenied,
                label: "denied: \(reason)",
                detail: "event: \(event), active: \(compositeState.activeSurface.id)"
            )
        }
    }
}
