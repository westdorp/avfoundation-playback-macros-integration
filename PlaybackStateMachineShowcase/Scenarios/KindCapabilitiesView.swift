import PlaybackStateMachine
import SwiftUI

struct KindCapabilitiesView: View {
    @State private var selectedKind: KindOption = .vod
    @State private var selectedAdType: PlaybackAdType = .midroll

    var body: some View {
        VStack(spacing: 0) {
            Picker("Kind", selection: $selectedKind) {
                ForEach(KindOption.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedKind == .ad {
                Picker("Ad Type", selection: $selectedAdType) {
                    ForEach(PlaybackAdType.allCases, id: \.self) { adType in
                        Text(adType.description).tag(adType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            capabilityCard(for: selectedKind.playbackKind(adType: selectedAdType))

            if selectedKind == .ad, selectedAdType == .sgai {
                Text("SGAI remains ad-role playback: finite duration, no seeking, and no live-edge controls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .navigationTitle("Kind Capabilities")
        .scenarioScreen(.kindCapabilities)
    }

    private func capabilityCard(for kind: PlaybackKind) -> some View {
        let caps = kind.capabilities

        return VStack(alignment: .leading, spacing: 12) {
            Text(kind.description)
                .font(.title2.monospaced().bold())

            Divider()

            capabilityRow("Seeking", detail: caps.seeking.description, available: caps.supportsSeeking)
            capabilityRow("Finite Duration", detail: caps.duration.description, available: caps.supportsFiniteDuration)
            capabilityRow("Live Edge", detail: caps.liveEdge.description, available: caps.supportsLiveEdge)
            capabilityRow(
                "Content Role",
                detail: caps.contentRole.description,
                available: true,
                icon: contentRoleIcon(for: caps)
            )

            if let adType = caps.adType {
                capabilityRow("Ad Type", detail: adType.description, available: true)
            }
        }
        .padding()
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func capabilityRow(
        _ label: String,
        detail: String,
        available: Bool,
        icon: String? = nil
    ) -> some View {
        HStack {
            Image(systemName: available ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(available ? .green : .secondary)

            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.subheadline.bold())

            Spacer()

            Text(detail)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func contentRoleIcon(for capabilities: PlaybackKindCapabilities) -> String {
        if capabilities.isAdKind {
            return "megaphone.fill"
        }
        return "play.tv.fill"
    }
}

private enum KindOption: Int, CaseIterable, Identifiable, Hashable {
    case vod
    case live
    case liveDVR
    case ad

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .vod: "VOD"
        case .live: "Live"
        case .liveDVR: "Live DVR"
        case .ad: "Ad"
        }
    }

    func playbackKind(adType: PlaybackAdType) -> PlaybackKind {
        switch self {
        case .vod: .vod
        case .live: .live
        case .liveDVR: .liveDVR
        case .ad: .ad(adType)
        }
    }
}
