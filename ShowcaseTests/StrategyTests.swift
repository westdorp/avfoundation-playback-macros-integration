import Testing
import PlaybackStateMachine

@Suite("Strategy Evaluations")
struct StrategyTests {

    // MARK: - Seeking

    @Test("VOD seek normalizes to target position")
    func vodSeek() throws {
        let strategy = PlaybackStrategies.vodSeeking()
        let target = try #require(PlaybackPositionSeconds(60))
        let request = PlaybackSeekRequest(target: target)
        let decision = strategy.seekDecision(for: request, context: PlaybackKindContext())
        #expect(decision == .seek(to: target))
    }

    @Test("LiveDVR seek near upper bound snaps to live edge")
    func liveDVRSnapToEdge() throws {
        let strategy = PlaybackStrategies.liveDVRSeeking(liveEdgeToleranceSeconds: 10)
        let target = try #require(PlaybackPositionSeconds(295))
        let upperBound = try #require(PlaybackPositionSeconds(300))
        let range = PlaybackPositionSeconds.zero...upperBound
        let request = PlaybackSeekRequest(target: target, seekableRange: range)
        let decision = strategy.seekDecision(for: request, context: PlaybackKindContext())
        #expect(decision == .seekToLiveEdge)
    }

    @Test("LiveDVR seek far from edge produces normal seek")
    func liveDVRNormalSeek() throws {
        let strategy = PlaybackStrategies.liveDVRSeeking(liveEdgeToleranceSeconds: 10)
        let target = try #require(PlaybackPositionSeconds(100))
        let upperBound = try #require(PlaybackPositionSeconds(300))
        let range = PlaybackPositionSeconds.zero...upperBound
        let request = PlaybackSeekRequest(target: target, seekableRange: range)
        let decision = strategy.seekDecision(for: request, context: PlaybackKindContext())
        #expect(decision == .seek(to: target))
    }

    // MARK: - Buffering

    @Test("Ready when likely to keep up and buffer not empty")
    func bufferingReady() {
        let strategy = PlaybackStrategies.vodBuffering()
        let snapshot = PlaybackBufferingSnapshot(
            isLikelyToKeepUp: true, isBufferEmpty: false, isWaitingForData: false
        )
        let decision = strategy.bufferingDecision(for: snapshot, context: PlaybackKindContext())
        #expect(decision == .ready)
    }

    @Test("Buffering when buffer empty")
    func bufferingWhenEmpty() {
        let strategy = PlaybackStrategies.vodBuffering()
        let snapshot = PlaybackBufferingSnapshot(
            isLikelyToKeepUp: false, isBufferEmpty: true, isWaitingForData: false
        )
        let decision = strategy.bufferingDecision(for: snapshot, context: PlaybackKindContext())
        #expect(decision == .buffering(reason: .rebuffering))
    }

    // MARK: - Stall Classification

    @Test("No stall when buffering is ready")
    func noStall() {
        let strategy = PlaybackStrategies.vodStall()
        let observation = PlaybackStallObservation(
            bufferingDecision: .ready,
            consecutiveBufferingTicks: 0,
            isSeeking: false,
            hasPlaybackError: false
        )
        #expect(strategy.classifyStall(from: observation, context: PlaybackKindContext()) == .none)
    }

    @Test("Network stall after threshold ticks")
    func networkStall() {
        let strategy = PlaybackStrategies.vodStall(networkStallThresholdTicks: 3)
        let observation = PlaybackStallObservation(
            bufferingDecision: .buffering(reason: .rebuffering),
            consecutiveBufferingTicks: 4,
            isSeeking: false,
            hasPlaybackError: false
        )
        #expect(strategy.classifyStall(from: observation, context: PlaybackKindContext()) == .network)
    }

    @Test("Player error stall overrides ticks")
    func playerErrorStall() {
        let strategy = PlaybackStrategies.vodStall()
        let observation = PlaybackStallObservation(
            bufferingDecision: .buffering(reason: .rebuffering),
            consecutiveBufferingTicks: 1,
            isSeeking: false,
            hasPlaybackError: true
        )
        #expect(strategy.classifyStall(from: observation, context: PlaybackKindContext()) == .playerError)
    }

    @Test("Transient stall during seeking")
    func transientDuringSeeking() {
        let strategy = PlaybackStrategies.vodStall()
        let observation = PlaybackStallObservation(
            bufferingDecision: .buffering(reason: .rebuffering),
            consecutiveBufferingTicks: 10,
            isSeeking: true,
            hasPlaybackError: false
        )
        #expect(strategy.classifyStall(from: observation, context: PlaybackKindContext()) == .transient)
    }

    // MARK: - Analytics

    @Test("Analytics strategy produces signals for transition events")
    func analyticsSignals() {
        let strategy = PlaybackStrategies.vodAnalytics()
        let signals = strategy.signals(
            for: .transitionAllowed(from: "idle", to: "loading", intent: "selectMedia"),
            context: PlaybackKindContext()
        )
        #expect(!signals.isEmpty)
        guard case let .log(log) = signals.first else {
            Issue.record("Expected log signal")
            return
        }
        #expect(log.category == "playback")
        #expect(log.name == "transitionAllowed")
    }

    // MARK: - Kind Capabilities

    @Test("All kind profiles have consistent capability dimensions")
    func kindCapabilityProfiles() {
        let vod = PlaybackKind.vod.capabilities
        #expect(vod.supportsSeeking)
        #expect(vod.supportsFiniteDuration)
        #expect(!vod.supportsLiveEdge)
        #expect(!vod.isAdKind)

        let live = PlaybackKind.live.capabilities
        #expect(!live.supportsSeeking)
        #expect(!live.supportsFiniteDuration)
        #expect(live.supportsLiveEdge)

        let liveDVR = PlaybackKind.liveDVR.capabilities
        #expect(liveDVR.supportsSeeking)
        #expect(!liveDVR.supportsFiniteDuration)
        #expect(liveDVR.supportsLiveEdge)

        let ad = PlaybackKind.ad(.midroll).capabilities
        #expect(!ad.supportsSeeking)
        #expect(ad.supportsFiniteDuration)
        #expect(!ad.supportsLiveEdge)
        #expect(ad.isAdKind)
        #expect(ad.adType == .midroll)

        let sgaiAd = PlaybackKind.ad(.sgai).capabilities
        #expect(!sgaiAd.supportsSeeking)
        #expect(sgaiAd.supportsFiniteDuration)
        #expect(!sgaiAd.supportsLiveEdge)
        #expect(sgaiAd.isAdKind)
        #expect(sgaiAd.adType == .sgai)
    }
}
