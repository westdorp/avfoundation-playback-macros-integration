import Testing
import PlaybackStateMachine

@Suite("Composite Reducer")
struct CompositeReducerTests {

    @Test("Register surface adds to state")
    func registerSurface() {
        let state = PlaybackCompositeState(activeSurface: .content(id: "vod-main"))
        let transition = PlaybackCompositeReducer.apply(
            .registerSurface(.live(id: "live-1")),
            to: state
        )
        guard case let .allowed(newState) = transition else {
            Issue.record("Expected allowed transition")
            return
        }
        #expect(newState.allSurfaces.count == 2)
        #expect(newState.surface(id: "live-1") != nil)
    }

    @Test("Activate registered surface succeeds")
    func activateRegistered() {
        let state = PlaybackCompositeState(
            activeSurface: .content(id: "vod-main"),
            additionalSurfaces: [.live(id: "live-1")]
        )
        let transition = PlaybackCompositeReducer.apply(
            .activateSurface(id: "live-1"),
            to: state
        )
        guard case let .allowed(newState) = transition else {
            Issue.record("Expected allowed transition")
            return
        }
        #expect(newState.activeSurface.id == "live-1")
    }

    @Test("Activate missing surface is denied")
    func activateMissing() {
        let state = PlaybackCompositeState(activeSurface: .content(id: "vod-main"))
        let transition = PlaybackCompositeReducer.apply(
            .activateSurface(id: "nonexistent"),
            to: state
        )
        guard case .denied = transition else {
            Issue.record("Expected denied transition")
            return
        }
        guard let reason = transition.deniedReason else {
            Issue.record("Expected denied reason")
            return
        }
        #expect(reason == .missingSurface(id: "nonexistent"))
    }

    @Test("Remove active surface is denied")
    func removeActive() {
        let state = PlaybackCompositeState(activeSurface: .content(id: "vod-main"))
        let transition = PlaybackCompositeReducer.apply(
            .unregisterSurface(id: "vod-main"),
            to: state
        )
        guard case .denied = transition else {
            Issue.record("Expected denied transition")
            return
        }
        guard let reason = transition.deniedReason else {
            Issue.record("Expected denied reason")
            return
        }
        #expect(reason == .cannotRemoveActiveSurface(id: "vod-main"))
    }

    @Test("Remove non-active surface succeeds")
    func removeNonActive() {
        let state = PlaybackCompositeState(
            activeSurface: .content(id: "vod-main"),
            additionalSurfaces: [.live(id: "live-1")]
        )
        let transition = PlaybackCompositeReducer.apply(
            .unregisterSurface(id: "live-1"),
            to: state
        )
        guard case let .allowed(newState) = transition else {
            Issue.record("Expected allowed transition")
            return
        }
        #expect(newState.allSurfaces.count == 1)
        #expect(newState.surface(id: "live-1") == nil)
    }

    @Test("Strategy router maps kinds correctly")
    func strategyRouting() {
        #expect(PlaybackCompositeStrategyRouter.route(for: .vod) == .vod)
        #expect(PlaybackCompositeStrategyRouter.route(for: .live) == .live)
        #expect(PlaybackCompositeStrategyRouter.route(for: .liveDVR) == .liveDVR)
        #expect(PlaybackCompositeStrategyRouter.route(for: .ad(.midroll)) == .ad(.midroll))
    }

    @Test("Active route reflects active surface kind")
    func activeRoute() {
        let state = PlaybackCompositeState(activeSurface: .live(id: "live-main"))
        #expect(PlaybackCompositeStrategyRouter.activeRoute(in: state) == .live)
    }
}
