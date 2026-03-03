import AVFoundation
import CoreMedia
import PlaybackDiagnostics
import PlaybackState

/// Minimal macro usage examples kept in the showcase target so developers can
/// inspect generated observer and diagnostics surfaces alongside scenario views.
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
@PlaybackState
@MainActor
final class ShowcasePlaybackObserver {
    let player: AVPlayer

    /// Demonstrates observing top-level AVPlayer transport state.
    @Observed("timeControlStatus")
    private var timeControlStatus: AVPlayer.TimeControlStatus

    /// Demonstrates observing playback speed for playing/scrubbing derivation.
    @Observed("rate")
    private var rate: Float

    /// Demonstrates observing current-item readiness transitions.
    @Observed("currentItem?.status")
    private var itemStatus: AVPlayerItem.Status?

    /// Demonstrates observing wait-reason context for buffering derivation.
    @Observed("reasonForWaitingToPlay")
    private var waitingReason: AVPlayer.WaitingReason?

    /// Demonstrates observing error surface used by failed playback condition.
    @Observed("error")
    private var itemError: Error?

    /// Demonstrates periodic time input alongside observed key-path inputs.
    @TimeObserver(interval: CMTime(seconds: 0.5, preferredTimescale: 600))
    private var currentTime: CMTime = .zero
}

/// Demonstrates minimal diagnostics aggregation wiring via @PlaybackDiagnostics.
@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
@PlaybackDiagnostics
@MainActor
final class ShowcasePlaybackDiagnosticsObserver {
    let item: AVPlayerItem
}
